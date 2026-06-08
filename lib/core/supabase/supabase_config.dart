import 'package:supabase_flutter/supabase_flutter.dart';

/// Centrálna konfigurácia Supabase pre BizAgent.
///
/// Hodnoty cez `--dart-define-from-file=dart_defines/supabase.json`
/// alebo jednotlivo:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment('SUPABASE_URL');

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  static bool _initialized = false;

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;

  /// True po úspešnom [initialize] v tomto procese.
  static bool get isReady => isConfigured && _initialized;

  static Future<void> initialize() async {
    if (!isConfigured || _initialized) return;
    await Supabase.initialize(
      url: url,
      publishableKey: publishableKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    _initialized = true;
  }

  static SupabaseClient get client {
    assert(isReady, 'Supabase nie je inicializovaný — zavolaj SupabaseConfig.initialize()');
    return Supabase.instance.client;
  }
}
