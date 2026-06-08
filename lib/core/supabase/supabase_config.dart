import 'package:supabase_flutter/supabase_flutter.dart';

/// Centrálna konfigurácia Supabase pre BizAgent.
///
/// Hodnoty sa dodávajú cez `--dart-define` (nikdy nehardcoduj kľúče):
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
///
/// `anon` kľúč je verejný (chránený RLS politikami) — nikdy nepoužívaj
/// `service_role` kľúč v klientovi.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// True ak sú dodané URL aj anon kľúč (inak Supabase init preskočíme).
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  /// Inicializuje Supabase klienta. Bezpečné volať aj bez konfigurácie
  /// (vtedy je no-op a appka beží v offline/local režime).
  static Future<void> initialize() async {
    if (!isConfigured) return;
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  /// Skratka k Supabase klientovi.
  static SupabaseClient get client => Supabase.instance.client;
}
