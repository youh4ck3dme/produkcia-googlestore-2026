import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'core/supabase/supabase_config.dart';
import 'core/supabase/oauth_callback_handler.dart';
import 'app.dart';
import 'core/services/local_persistence_service.dart';
import 'core/demo_mode/demo_mode_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'features/limits/usage_limiter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kDebugMode && !kIsWeb) {
    try {
      final r = await http.get(Uri.parse('https://www.google.com')).timeout(const Duration(seconds: 5));
      debugPrint('NET OK: ${r.statusCode}');
    } catch (e) {
      debugPrint('NET ERROR: $e');
    }
  }

  // Initialize Hive for Offline Storage
  await Hive.initFlutter();
  await initializeDateFormatting('sk', null);
  final persistenceService = LocalPersistenceService();
  await persistenceService.init();
  DemoModeService.instance.persistence = persistenceService;

  final sharedPrefs = await SharedPreferences.getInstance();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Supabase (DB/Auth/Storage). Vyžaduje dart_defines/supabase.json alebo --dart-define.
  await SupabaseConfig.initialize();

  // Web OAuth: vymení ?code= za session pred prvým renderom (hash URL #/login).
  if (kIsWeb) {
    try {
      await recoverOAuthSessionFromBrowserUrl();
    } on AuthException catch (e) {
      debugPrint('OAuth callback failed: ${e.message}');
    } catch (e, st) {
      debugPrint('OAuth callback error: $e\n$st');
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        localPersistenceServiceProvider.overrideWithValue(persistenceService),
        sharedPrefsProvider.overrideWithValue(sharedPrefs),
      ],
      child: const BizAgentApp(),
    ),
  );
}
