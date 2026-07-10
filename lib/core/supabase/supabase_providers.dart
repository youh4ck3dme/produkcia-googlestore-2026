import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'supabase_config.dart';
import 'supabase_table_store.dart';

final supabaseTableStoreProvider = Provider<SupabaseTableStore>((ref) {
  return SupabaseConfig.isReady
      ? SupabaseTableStore.fromClient(SupabaseConfig.client)
      : SupabaseTableStore.fromClient(null);
});