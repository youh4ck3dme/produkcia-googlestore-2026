// lib/core/services/export_service.dart
import 'dart:convert';
import 'package:universal_io/io.dart';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../utils/csv.dart';
import '../utils/file_names.dart';
import '../../features/export/models/export_models.dart';

/// ---
/// Adapt this interface to your existing repos.
/// The key: return local file paths if available (offline-first).
/// ---
class InvoiceExportItem {
  InvoiceExportItem({
    required this.id,
    required this.number,
    required this.issuedAt,
    required this.clientName,
    required this.totalEur,
    required this.vatEur,
    this.pdfLocalPath, 
    this.pdfData,
  });

  final String id;
  final String number;
  final DateTime issuedAt;
  final String clientName;
  final double totalEur;
  final double vatEur;
  final String? pdfLocalPath;
  final Uint8List? pdfData;
}

class ExpenseExportItem {
  ExpenseExportItem({
    required this.id,
    required this.date,
    required this.vendor,
    required this.totalEur,
    required this.category,
    this.attachmentLocalPaths = const [],
    this.attachmentDatas = const [],
  });

  final String id;
  final DateTime date;
  final String vendor;
  final double totalEur;
  final String category;
  final List<String> attachmentLocalPaths;
  final List<Uint8List> attachmentDatas;
}

abstract class ExportDataSource {
  Future<List<InvoiceExportItem>> loadInvoices(ExportPeriod period);
  Future<List<ExpenseExportItem>> loadExpenses(ExportPeriod period);

  /// Raw dump for JSON. Can be your Firestore maps or model toJson outputs.
  Future<Map<String, dynamic>> loadRawDump(ExportPeriod period);
}

class ExportService {
  ExportService(this.dataSource);

  final ExportDataSource dataSource;

  Future<ExportResult> buildZip({
    required String uid,
    required ExportPeriod period,
    required void Function(String msg)? onStep,
    required void Function(ExportProgress p)? onProgress,
  }) async {
    final missing = <String>[];
    var prog = ExportProgress.empty();

    final now = DateTime.now();
    
    // Prepare Output Path (Only on Native)
    String? zipPath;
    if (!kIsWeb) {
      final dir = await getApplicationDocumentsDirectory();
      final exportDir = Directory(p.join(dir.path, 'exports'));
      if (!await exportDir.exists()) await exportDir.create(recursive: true);
      final fromStr = _yyyymmdd(period.from);
      final toStr = _yyyymmdd(period.to);
      final zipFileName =
          'BizAgent_Export_${FileNames.safe(uid)}_${fromStr}_$toStr.zip';
      zipPath = p.join(exportDir.path, zipFileName);
    }

    onStep?.call('Načítavam dáta…');
    final invoices = await dataSource.loadInvoices(period);
    final expenses = await dataSource.loadExpenses(period);
    final rawDump = await dataSource.loadRawDump(period);

    // Prepare CSV
    onStep?.call('Generujem CSV…');
    final invoiceCsv = _buildInvoicesCsv(invoices);
    final expenseCsv = _buildExpensesCsv(expenses);
    prog = prog.copyWith(csvDone: true, message: 'CSV hotové');
    onProgress?.call(prog);

    // Prepare JSON
    onStep?.call('Generujem JSON…');
    final jsonStr = const JsonEncoder.withIndent('  ').convert(rawDump);
    prog = prog.copyWith(jsonDone: true, message: 'JSON hotové');
    onProgress?.call(prog);

    // Build ZIP
    onStep?.call('Balinujem ZIP…');
    final archive = Archive();

    // Root meta
    archive.addFile(
        ArchiveFile('README.txt', 0, utf8.encode(_readme(period, now))));
    archive.addFile(ArchiveFile('missing_report.txt', 0, utf8.encode('')));

    // CSV
    archive.addFile(ArchiveFile(
        'summary/invoices.csv', invoiceCsv.length, utf8.encode(invoiceCsv)));
    archive.addFile(ArchiveFile(
        'summary/expenses.csv', expenseCsv.length, utf8.encode(expenseCsv)));

    // JSON
    archive.addFile(ArchiveFile(
        'data/raw_dump.json', jsonStr.length, utf8.encode(jsonStr)));

    // PDFs
    onStep?.call('Pridávam PDF faktúry…');
    int pdfOk = 0;
    for (final inv in invoices) {
      final fileName = FileNames.safe('${inv.number}_${inv.clientName}.pdf');
      final zipEntryPath = 'invoices/$fileName';
      
      List<int>? bytes;
      if (inv.pdfData != null) {
        bytes = inv.pdfData;
      } else if (inv.pdfLocalPath != null && inv.pdfLocalPath!.isNotEmpty) {
        final f = File(inv.pdfLocalPath!);
        if (await f.exists()) {
          bytes = await f.readAsBytes();
        }
      }

      if (bytes == null) {
        missing.add('PDF missing for invoice ${inv.number} (${inv.id})');
        continue;
      }
      
      archive.addFile(ArchiveFile(zipEntryPath, bytes.length, bytes));
      pdfOk++;
    }
    prog = prog.copyWith(
        pdfDone: true, message: 'PDF hotové ($pdfOk/${invoices.length})');
    onProgress?.call(prog);

    // Expense attachments
    onStep?.call('Pridávam prílohy výdavkov…');
    int attOk = 0;
    int attTotal = 0;
    for (final ex in expenses) {
      final baseFolder =
          'expenses/${FileNames.safe(_yyyymmdd(ex.date))}_${FileNames.safe(ex.vendor)}/${ex.id}';
      
      // Process explicit data first (Web)
      for (int i = 0; i < ex.attachmentDatas.length; i++) {
        attTotal++;
        final bytes = ex.attachmentDatas[i];
        final name = 'attachment_data_${i + 1}.bin'; // Fallback extension
        archive.addFile(ArchiveFile('$baseFolder/$name', bytes.length, bytes));
        attOk++;
      }

      // Process local paths (Mobile)
      for (final ap in ex.attachmentLocalPaths) {
        attTotal++;
        final f = File(ap);
        if (!await f.exists()) {
          missing.add('Attachment not found: $ap (expense ${ex.id})');
          continue;
        }
        final bytes = await f.readAsBytes();
        final ext = p.extension(ap).isEmpty ? '.bin' : p.extension(ap);
        final name = 'attachment_${attOk + 1}$ext';
        archive.addFile(ArchiveFile('$baseFolder/$name', bytes.length, bytes));
        attOk++;
      }
    }
    prog = prog.copyWith(
        photosDone: true, message: 'Prílohy hotové ($attOk/$attTotal)');
    onProgress?.call(prog);

    // Missing report
    final missingText = missing.isEmpty
        ? 'OK - nič nechýba.\n'
        : '${missing.map((e) => '- $e').join('\n')}\n';
    archive.addFile(ArchiveFile(
        'missing_report.txt', missingText.length, utf8.encode(missingText)));

    // Save ZIP
    final outBytes = ZipEncoder().encode(archive);
    
    if (!kIsWeb && zipPath != null) {
      final outFile = File(zipPath);
      await outFile.writeAsBytes(outBytes, flush: true);
    }

    return ExportResult(
      zipPath: zipPath ?? '', 
      missingItems: missing, 
      zipBytes: kIsWeb ? Uint8List.fromList(outBytes) : null,
    );
  }

  String _buildInvoicesCsv(List<InvoiceExportItem> invoices) {
    final rows = <List<String>>[];
    rows.add(['number', 'issued_at', 'client', 'total_eur', 'vat_eur']);
    for (final i in invoices) {
      rows.add([
        i.number,
        _yyyymmdd(i.issuedAt),
        i.clientName,
        i.totalEur.toStringAsFixed(2),
        i.vatEur.toStringAsFixed(2),
      ]);
    }
    return Csv.encode(rows);
  }

  String _buildExpensesCsv(List<ExpenseExportItem> expenses) {
    final rows = <List<String>>[];
    rows.add(['date', 'vendor', 'category', 'total_eur', 'attachments_count']);
    for (final e in expenses) {
      rows.add([
        _yyyymmdd(e.date),
        e.vendor,
        e.category,
        e.totalEur.toStringAsFixed(2),
        (e.attachmentLocalPaths.length + e.attachmentDatas.length).toString(),
      ]);
    }
    return Csv.encode(rows);
  }

  String _readme(ExportPeriod period, DateTime now) {
    return [
      'BizAgent Export',
      'Generated: ${now.toIso8601String()}',
      'Period: ${_yyyymmdd(period.from)} -> ${_yyyymmdd(period.to)}',
      '',
      'Folders:',
      '- invoices/ (PDF faktúry)',
      '- expenses/ (prílohy výdavkov)',
      '- summary/ (CSV pre účtovníctvo)',
      '- data/ (raw JSON dump)',
      '',
      'missing_report.txt obsahuje chýbajúce súbory (offline / neuložené prílohy).',
    ].join('\n');
  }

  String _yyyymmdd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
