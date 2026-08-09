import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/models/user_model.dart';
import 'auth_backend.dart';
import 'supabase_config.dart';

/// Google prihlásenie cez Supabase Auth (OAuth web / ID token native).
class GoogleAuthService {
  GoogleAuthService(this._client);

  final SupabaseClient _client;

  static const _iosClientId =
      '90348815049-lh9qppoqpadudei1sgp3di4450jbsin7.apps.googleusercontent.com';

  static bool _nativeInitialized = false;

  /// Pure gate for Google Sign-In availability (unit-testable without SDK).
  @visibleForTesting
  static bool resolveIsConfigured({
    required bool supabaseReady,
    required bool isWeb,
    required String googleWebClientId,
  }) {
    if (!supabaseReady) return false;
    if (isWeb) return true;
    return googleWebClientId.isNotEmpty;
  }

  Future<void> _ensureNativeInitialized() async {
    if (_nativeInitialized || kIsWeb) return;

    final webClientId = SupabaseConfig.googleWebClientId;
    await GoogleSignIn.instance.initialize(
      serverClientId:
          defaultTargetPlatform == TargetPlatform.android ? webClientId : null,
      clientId: defaultTargetPlatform == TargetPlatform.iOS ? _iosClientId : null,
    );
    _nativeInitialized = true;
  }

  bool get isConfigured => resolveIsConfigured(
        supabaseReady: SupabaseConfig.isReady,
        isWeb: kIsWeb,
        googleWebClientId: SupabaseConfig.googleWebClientId,
      );

  Future<UserModel?> signIn() async {
    if (!isConfigured) {
      throw StateError(
        'Google Sign-In nie je nakonfigurovaný — chýba GOOGLE_WEB_CLIENT_ID.',
      );
    }

    if (kIsWeb) {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _webRedirectTo,
        authScreenLaunchMode: LaunchMode.platformDefault,
      );
      return _client.auth.currentUser == null
          ? null
          : userModelFromSupabase(_client.auth.currentUser!);
    }

    await _ensureNativeInitialized();
    final account = await GoogleSignIn.instance.authenticate(
      scopeHint: const ['email', 'profile'],
    );

    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AuthException(
        'Google nevrátil ID token — over SHA-1 a Web Client ID.',
      );
    }

    final authz = await account.authorizationClient.authorizationForScopes(
      const ['email', 'profile'],
    );

    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: authz?.accessToken,
    );

    final user = response.user;
    return user == null ? null : userModelFromSupabase(user);
  }

  Future<void> signOutNative() async {
    if (kIsWeb) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  String? get _webRedirectTo {
    final base = Uri.base;
    if (base.origin.isEmpty || base.origin == 'null') {
      return 'https://bizagent.sk/';
    }
    final path = base.path.isEmpty ? '/' : base.path;
    final normalized = path.endsWith('/') ? path : '$path/';
    return '${base.origin}$normalized';
  }
}
