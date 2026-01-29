import 'dart:math';
import '../data/invoice_numbering_repository.dart';

class InvoiceNumberResult {
  InvoiceNumberResult({required this.number, required this.isProvisional});
  final String number;
  final bool isProvisional;
}

class InvoiceNumberingService {
  InvoiceNumberingService({
    required this.repo,
    this.blockSize = 25,
  });

  final InvoiceNumberingRepository repo;
  final int blockSize;

  String formatNumber(int year, int seq) =>
      '$year/${seq.toString().padLeft(3, '0')}';

  /// Tries:
  /// 1) local pool
  /// 2) reserve new block (online) -> save -> allocate
  /// 3) fallback TMP if offline & no pool
  Future<InvoiceNumberResult> nextNumber({
    required String uid,
    DateTime? now,
  }) async {
    final date = now ?? DateTime.now();
    final year = date.year;

    // 1) use local pool if exists
    final pool = await repo.loadLocalPool(year);
    if (pool != null && pool.hasNext) {
      final seq = pool.next;
      await repo.saveLocalPool(pool.allocateOne());
      return InvoiceNumberResult(
          number: formatNumber(year, seq), isProvisional: false);
    }

    // 2) try reserve a new block (requires online / firestore)
    try {
      final block =
          await repo.reserveBlock(uid: uid, year: year, blockSize: blockSize);
      final newPool = LocalPool(year: year, next: block.start, end: block.end);

      // allocate first immediately
      final seq = newPool.next;
      await repo.saveLocalPool(newPool.allocateOne());
      return InvoiceNumberResult(
          number: formatNumber(year, seq), isProvisional: false);
    } catch (_) {
      // 3) offline fallback (TMP)
      final tmp = _tmpNumber(year);
      return InvoiceNumberResult(number: tmp, isProvisional: true);
    }
  }

  String _tmpNumber(int year) {
    // 6 digits random-ish (still human readable)
    final r = Random().nextInt(900000) + 100000;
    return '$year/TMP-$r';
  }
}
