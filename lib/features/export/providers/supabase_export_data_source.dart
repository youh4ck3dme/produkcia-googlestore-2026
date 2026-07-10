import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/services/export_service.dart';
import '../../../core/supabase/supabase_table_store.dart';
import '../../export/models/export_models.dart';
import '../../invoices/models/invoice_model.dart';
import '../../expenses/models/expense_model.dart';

class SupabaseExportDataSource implements ExportDataSource {
  SupabaseExportDataSource(this._store, this.userId);

  final SupabaseTableStore _store;
  final String userId;
  final Dio _dio = Dio();

  @override
  Future<List<InvoiceExportItem>> loadInvoices(ExportPeriod period) async {
    final rows = await _store.select(
      'invoices',
      eq: {'user_id': userId, 'is_deleted': false},
    );

    final invoices = rows
        .map((row) {
          final data = Map<String, dynamic>.from(row['data'] as Map);
          data['id'] = row['id'];
          return InvoiceModel.fromMap(data, row['id'] as String);
        })
        .where((inv) =>
            !inv.dateIssued.isBefore(period.from) &&
            !inv.dateIssued.isAfter(period.to))
        .toList();

    final exportItems = <InvoiceExportItem>[];
    for (final inv in invoices) {
      String? localPath;
      Uint8List? fileBytes;

      if (inv.pdfUrl != null && inv.pdfUrl!.isNotEmpty) {
        if (kIsWeb) {
          fileBytes = await _downloadBytes(inv.pdfUrl!);
        } else {
          try {
            localPath =
                await _downloadFile(inv.pdfUrl!, 'inv_${inv.number}.pdf');
          } catch (_) {}
        }
      }
      exportItems.add(InvoiceExportItem(
        id: inv.id,
        number: inv.number,
        issuedAt: inv.dateIssued,
        clientName: inv.clientName,
        totalEur: inv.totalAmount,
        vatEur: inv.totalVat,
        pdfLocalPath: localPath,
        pdfData: fileBytes,
      ));
    }
    return exportItems;
  }

  @override
  Future<List<ExpenseExportItem>> loadExpenses(ExportPeriod period) async {
    final rows = await _store.select(
      'expenses',
      eq: {'user_id': userId},
    );

    final expenses = rows
        .map((row) {
          final data = Map<String, dynamic>.from(row['data'] as Map);
          data['id'] = row['id'];
          return ExpenseModel.fromMap(data, row['id'] as String);
        })
        .where((ex) =>
            !ex.date.isBefore(period.from) && !ex.date.isAfter(period.to))
        .toList();

    final exportItems = <ExpenseExportItem>[];
    for (final ex in expenses) {
      final localPaths = <String>[];
      final fileDatas = <Uint8List>[];

      for (int i = 0; i < ex.receiptUrls.length; i++) {
        final url = ex.receiptUrls[i];
        final name = 'exp_${ex.id}_$i${_ext(url)}';

        if (kIsWeb) {
          final bytes = await _downloadBytes(url);
          if (bytes != null) fileDatas.add(bytes);
        } else {
          try {
            final path = await _downloadFile(url, name);
            if (path != null) localPaths.add(path);
          } catch (_) {}
        }
      }
      exportItems.add(ExpenseExportItem(
        id: ex.id,
        date: ex.date,
        vendor: ex.vendorName,
        totalEur: ex.amount,
        category: ex.category?.name ?? 'Other',
        attachmentLocalPaths: localPaths,
        attachmentDatas: fileDatas,
      ));
    }
    return exportItems;
  }

  @override
  Future<Map<String, dynamic>> loadRawDump(ExportPeriod period) async {
    return {
      'metadata': {
        'userId': userId,
        'periodFrom': period.from.toIso8601String(),
        'periodTo': period.to.toIso8601String(),
        'exportedAt': DateTime.now().toIso8601String(),
        'source': 'supabase',
      }
    };
  }

  Future<String?> _downloadFile(String url, String fileName) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final downloadDir = Directory(p.join(cacheDir.path, 'export_tmp'));
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final savePath = p.join(downloadDir.path, fileName);
      await _dio.download(url, savePath);
      return savePath;
    } catch (e) {
      return null;
    }
  }

  String _ext(String url) {
    if (url.contains('.png')) return '.png';
    if (url.contains('.jpg')) return '.jpg';
    if (url.contains('.jpeg')) return '.jpeg';
    if (url.contains('.pdf')) return '.pdf';
    return '.img';
  }

  Future<Uint8List?> _downloadBytes(String url) async {
    try {
      final response = await _dio.get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data);
    } catch (e) {
      return null;
    }
  }
}