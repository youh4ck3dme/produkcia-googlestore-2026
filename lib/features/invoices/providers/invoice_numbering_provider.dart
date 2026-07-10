import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../limits/usage_limiter.dart';
import '../data/invoice_numbering_repository.dart';
import '../data/supabase_invoice_numbering_repository.dart';
import '../services/invoice_numbering_service.dart';

class _OfflineInvoiceNumberingRepository implements InvoiceNumberingRepository {
  _OfflineInvoiceNumberingRepository({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  String _poolKey(int year) => 'invoice_number_pool_$year';

  @override
  Future<ReservedBlock> reserveBlock({
    required String uid,
    required int year,
    required int blockSize,
  }) async {
    throw StateError('Supabase not ready');
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

final invoiceNumberingRepositoryProvider = Provider<InvoiceNumberingRepository>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  if (SupabaseConfig.isReady) {
    return SupabaseInvoiceNumberingRepository(
      client: SupabaseConfig.client,
      prefs: prefs,
    );
  }
  return _OfflineInvoiceNumberingRepository(prefs: prefs);
});

final invoiceNumberingServiceProvider = Provider<InvoiceNumberingService>((ref) {
  return InvoiceNumberingService(repo: ref.watch(invoiceNumberingRepositoryProvider));
});