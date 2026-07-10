import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'invoice_numbering_repository.dart';

class SupabaseInvoiceNumberingRepository implements InvoiceNumberingRepository {
  SupabaseInvoiceNumberingRepository({
    required SupabaseClient client,
    required SharedPreferences prefs,
  })  : _client = client,
        _prefs = prefs;

  final SupabaseClient _client;
  final SharedPreferences _prefs;

  String _poolKey(int year) => 'invoice_number_pool_$year';

  @override
  Future<ReservedBlock> reserveBlock({
    required String uid,
    required int year,
    required int blockSize,
  }) async {
    final response = await _client.rpc(
      'reserve_invoice_block',
      params: {
        'p_year': year,
        'p_block_size': blockSize,
      },
    );

    final row = _firstRow(response);
    final start = (row['start_seq'] as num).toInt();
    final end = (row['end_seq'] as num).toInt();
    return ReservedBlock(start: start, end: end);
  }

  Map<String, dynamic> _firstRow(dynamic response) {
    if (response is List && response.isNotEmpty) {
      return Map<String, dynamic>.from(response.first as Map);
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    throw StateError('Unexpected reserve_invoice_block response: $response');
  }

  @override
  Future<LocalPool?> loadLocalPool(int year) async {
    final s = _prefs.getString(_poolKey(year));
    if (s == null || s.isEmpty) return null;
    try {
      return LocalPool.decode(s);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveLocalPool(LocalPool pool) async {
    await _prefs.setString(_poolKey(pool.year), pool.encode());
  }
}