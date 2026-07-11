import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
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

  GoogleSignIn _nativeGoogleSignIn() {
    final webClientId = SupabaseConfig.googleWebClientId;
    return GoogleSignIn(
      serverClientId:
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android
              ? webClientId
              : null,
      clientId: !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
          ? _iosClientId
          : null,
      scopes: const ['email', 'profile'],
    );
  }

  bool get isConfigured {
    if (!SupabaseConfig.isReady) return false;
    if (kIsWeb) return true;
    return SupabaseConfig.googleWebClientId.isNotEmpty;
  }

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
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      return _client.auth.currentUser == null
          ? null
          : userModelFromSupabase(_client.auth.currentUser!);
    }

    final google = _nativeGoogleSignIn();
    final account = await google.signIn();
    if (account == null) return null;

    final googleAuth = await account.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw AuthException(
        'Google nevrátil ID token — over SHA-1 a Web Client ID.',
      );
    }

    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );

    final user = response.user;
    return user == null ? null : userModelFromSupabase(user);
  }

  Future<void> signOutNative() async {
    if (kIsWeb) return;
    try {
      await _nativeGoogleSignIn().signOut();
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