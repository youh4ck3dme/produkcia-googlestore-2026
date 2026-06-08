import 'package:google_sign_in/google_sign_in.dart';

/// Testovateľný wrapper okolo Google Sign-In (natívny OAuth flow).
abstract class GoogleSignInAdapter {
  Future<GoogleSignInAccount?> signIn();
  Future<void> signOut();
}

class DefaultGoogleSignInAdapter implements GoogleSignInAdapter {
  DefaultGoogleSignInAdapter({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email', 'profile'],
              serverClientId: const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID')
                      .isEmpty
                  ? null
                  : const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
            );

  final GoogleSignIn _googleSignIn;

  @override
  Future<GoogleSignInAccount?> signIn() => _googleSignIn.signIn();

  @override
  Future<void> signOut() => _googleSignIn.signOut();
}
