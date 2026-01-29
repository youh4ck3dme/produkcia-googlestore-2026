import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/features/invoices/services/invoice_numbering_service.dart';
import 'package:bizagent/features/invoices/data/invoice_numbering_repository.dart';

class FakeRepo implements InvoiceNumberingRepository {
  LocalPool? pool;
  int remoteSeq = 0;
  bool shouldThrowOnReserve = false;

  @override
  Future<LocalPool?> loadLocalPool(int year) async =>
      pool?.year == year ? pool : null;

  @override
  Future<void> saveLocalPool(LocalPool p) async => pool = p;

  @override
  Future<ReservedBlock> reserveBlock({
    required String uid,
    required int year,
    required int blockSize,
  }) async {
    if (shouldThrowOnReserve) {
      throw Exception('Network error');
    }
    final start = remoteSeq + 1;
    final end = remoteSeq + blockSize;
    remoteSeq = end;
    return ReservedBlock(start: start, end: end);
  }
}

void main() {
  test('allocates from reserved block pool', () async {
    final repo = FakeRepo();
    final svc = InvoiceNumberingService(repo: repo, blockSize: 3);

    final a = await svc.nextNumber(uid: 'u', now: DateTime(2026, 1, 1));
    final b = await svc.nextNumber(uid: 'u', now: DateTime(2026, 1, 2));
    final c = await svc.nextNumber(uid: 'u', now: DateTime(2026, 1, 3));

    expect(a.number, '2026/001');
    expect(b.number, '2026/002');
    expect(c.number, '2026/003');
    expect(a.isProvisional, false);
  });

  test('formats padded numbering', () {
    final repo = FakeRepo();
    final svc = InvoiceNumberingService(repo: repo);
    expect(svc.formatNumber(2026, 1), '2026/001');
    expect(svc.formatNumber(2026, 12), '2026/012');
    expect(svc.formatNumber(2026, 123), '2026/123');
  });

  test('uses local pool when available', () async {
    final repo = FakeRepo();
    repo.pool = LocalPool(year: 2026, next: 5, end: 10);
    final svc = InvoiceNumberingService(repo: repo);

    final result = await svc.nextNumber(uid: 'u', now: DateTime(2026, 1, 1));

    expect(result.number, '2026/005');
    expect(result.isProvisional, false);
    expect(repo.pool?.next, 6); // Should be incremented
  });

  test('falls back to TMP number when offline and no pool', () async {
    final repo = FakeRepo();
    repo.shouldThrowOnReserve = true; // Simulate offline
    final svc = InvoiceNumberingService(repo: repo);

    final result = await svc.nextNumber(uid: 'u', now: DateTime(2026, 1, 1));

    expect(result.number, startsWith('2026/TMP-'));
    expect(result.isProvisional, true);
  });

  test('handles year transitions correctly', () async {
    final repo = FakeRepo();
    repo.pool = LocalPool(year: 2025, next: 100, end: 150);
    final svc = InvoiceNumberingService(repo: repo);

    // Request number for 2026 (different year)
    final result = await svc.nextNumber(uid: 'u', now: DateTime(2026, 1, 1));

    // Should reserve new block for 2026, not use 2025 pool
    expect(result.number, startsWith('2026/'));
    expect(result.isProvisional, false);
  });

  test('exhausts local pool before reserving new block', () async {
    final repo = FakeRepo();
    repo.pool = LocalPool(year: 2026, next: 10, end: 10); // Last number in pool
    final svc = InvoiceNumberingService(repo: repo, blockSize: 5);

    // First call uses last number from pool
    final result1 = await svc.nextNumber(uid: 'u', now: DateTime(2026, 1, 1));
    expect(result1.number, '2026/010');
    expect(result1.isProvisional, false);

    // Second call should reserve new block
    final result2 = await svc.nextNumber(uid: 'u', now: DateTime(2026, 1, 2));
    expect(result2.number, '2026/001'); // New block starts at 1
    expect(result2.isProvisional, false);
  });

  test('handles empty pool correctly', () async {
    final repo = FakeRepo();
    repo.pool = LocalPool(year: 2026, next: 11, end: 10); // Empty pool (next > end)
    final svc = InvoiceNumberingService(repo: repo);

    // Should reserve new block instead of using empty pool
    final result = await svc.nextNumber(uid: 'u', now: DateTime(2026, 1, 1));

    expect(result.number, '2026/001');
    expect(result.isProvisional, false);
  });
}
