import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/services/export_service.dart';
import '../../export/models/export_models.dart';
import '../../invoices/models/invoice_model.dart';
import '../../expenses/models/expense_model.dart';

class FirestoreExportDataSource implements ExportDataSource {
  final FirebaseFirestore _firestore;
  final String userId;
  final Dio _dio = Dio();

  FirestoreExportDataSource(this._firestore, this.userId);

  @override
  Future<List<InvoiceExportItem>> loadInvoices(ExportPeriod period) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .where('dateIssued',
            isGreaterThanOrEqualTo: period.from.toIso8601String())
        .where('dateIssued', isLessThanOrEqualTo: period.to.toIso8601String())
        .get();

    final invoices = snapshot.docs
        .map((doc) => InvoiceModel.fromMap(doc.data(), doc.id))
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
            localPath = await _downloadFile(inv.pdfUrl!, 'inv_${inv.number}.pdf');
          } catch (_) {
             // ignore download errors
          }
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
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: period.from.toIso8601String())
        .where('date', isLessThanOrEqualTo: period.to.toIso8601String())
        .get();

    final expenses = snapshot.docs
        .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
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
    // Simplified raw dump for now
    return {
      'metadata': {
        'userId': userId,
        'periodFrom': period.from.toIso8601String(),
        'periodTo': period.to.toIso8601String(),
        'exportedAt': DateTime.now().toIso8601String(),
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
