import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bizagent/core/supabase/supabase_config.dart';

bool _testSupabaseInitialized = false;

/// Inicializuje Supabase v testoch, ak sú dostupné dart-define hodnoty.
Future<void> ensureTestSupabase() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  if (!SupabaseConfig.isConfigured || _testSupabaseInitialized) return;
  await SupabaseConfig.initialize();
  _testSupabaseInitialized = true;
}
