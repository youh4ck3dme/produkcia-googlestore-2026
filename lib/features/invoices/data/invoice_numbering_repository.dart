// lib/features/invoices/data/invoice_numbering_repository.dart
import 'dart:convert';

abstract class InvoiceNumberingRepository {
  Future<ReservedBlock> reserveBlock({
    required String uid,
    required int year,
    required int blockSize,
  });

  Future<LocalPool?> loadLocalPool(int year);
  Future<void> saveLocalPool(LocalPool pool);
}

class ReservedBlock {
  ReservedBlock({required this.start, required this.end});
  final int start;
  final int end;
}

class LocalPool {
  LocalPool({required this.year, required this.next, required this.end});
  final int year;
  final int next;
  final int end;

  bool get hasNext => next <= end;

  LocalPool allocateOne() => LocalPool(year: year, next: next + 1, end: end);

  Map<String, dynamic> toJson() => {'year': year, 'next': next, 'end': end};

  static LocalPool fromJson(Map<String, dynamic> j) => LocalPool(
      year: j['year'] as int, next: j['next'] as int, end: j['end'] as int);

  String encode() => jsonEncode(toJson());
  static LocalPool decode(String s) =>
      fromJson(jsonDecode(s) as Map<String, dynamic>);
}
