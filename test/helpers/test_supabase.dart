import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bizagent/core/supabase/supabase_config.dart';

bool _testSupabaseInitialized = false;

/// Inicializuje Supabase v testoch, ak sú dostupné dart-define hodnoty.
Future<void> ensureTestSupabase() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  if (!SupabaseConfig.isConfigured || _testSupabaseInitialized) return;
  // VM integration tests: implicit flow — PKCE + mock prefs spôsobuje 400 pri signIn.
  await SupabaseConfig.initialize(authFlowType: AuthFlowType.implicit);
  _testSupabaseInitialized = true;
}
