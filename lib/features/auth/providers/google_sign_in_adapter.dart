import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

/// Testovateľný wrapper okolo Google Sign-In (natívny OAuth flow).
abstract class GoogleSignInAdapter {
  Future<GoogleSignInAccount?> signIn();
  Future<void> signOut();
}

String? _envOrNull(String key) {
  final value = String.fromEnvironment(key);
  return value.isEmpty ? null : value;
}

GoogleSignIn _defaultGoogleSignIn() {
  final serverClientId = _envOrNull('GOOGLE_WEB_CLIENT_ID');
  final androidClientId = _envOrNull('GOOGLE_ANDROID_CLIENT_ID');
  final useExplicitAndroidClient = !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      androidClientId != null;

  return GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: serverClientId,
    clientId: useExplicitAndroidClient ? androidClientId : null,
  );
}

class DefaultGoogleSignInAdapter implements GoogleSignInAdapter {
  DefaultGoogleSignInAdapter({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? _defaultGoogleSignIn();

  final GoogleSignIn _googleSignIn;

  @override
  Future<GoogleSignInAccount?> signIn() => _googleSignIn.signIn();

  @override
  Future<void> signOut() => _googleSignIn.signOut();
}
