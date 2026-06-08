import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/models/user_model.dart';
import '../../features/auth/providers/google_sign_in_adapter.dart';

/// Tenká auth abstrakcia pre testovateľný [AuthRepository].
abstract class AuthBackend {
  bool get isAvailable;

  Stream<UserModel?> get authStateChanges;

  UserModel? get currentUser;

  Future<String?> get currentUserToken;

  Future<UserModel?> signInWithPassword(String email, String password);

  Future<UserModel?> signUp(String email, String password);

  Future<void> signInWithOAuthGoogle({required String redirectTo});

  Future<UserModel?> signInWithGoogleNative();

  Future<void> signOut();

  Future<void> invokeFunction(String name);

  factory AuthBackend.fromClient(
    SupabaseClient? client, {
    GoogleSignInAdapter? googleSignIn,
  }) {
    if (client == null) return _UnavailableAuthBackend();
    return SupabaseAuthBackend(client, googleSignIn: googleSignIn);
  }
}

UserModel userModelFromSupabase(User u) => UserModel(
      id: u.id,
      email: u.email ?? '',
      displayName:
          (u.userMetadata?['full_name'] ?? u.userMetadata?['name']) as String?,
      photoUrl: u.userMetadata?['avatar_url'] as String?,
      isAnonymous: u.isAnonymous,
    );

class _UnavailableAuthBackend implements AuthBackend {
  static const _missingConfigMessage =
      'Supabase nie je nakonfigurovaný — chýba SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY.';

  @override
  bool get isAvailable => false;

  @override
  Stream<UserModel?> get authStateChanges =>
      Stream<UserModel?>.value(null);

  @override
  UserModel? get currentUser => null;

  @override
  Future<String?> get currentUserToken async => null;

  @override
  Future<void> invokeFunction(String name) async {}

  @override
  Future<UserModel?> signInWithGoogleNative() async => null;

  @override
  Future<void> signInWithOAuthGoogle({required String redirectTo}) async {}

  @override
  Future<UserModel?> signInWithPassword(String email, String password) async {
    throw StateError(_missingConfigMessage);
  }

  @override
  Future<UserModel?> signUp(String email, String password) async {
    throw StateError(_missingConfigMessage);
  }

  @override
  Future<void> signOut() async {}
}

class SupabaseAuthBackend implements AuthBackend {
  SupabaseAuthBackend(this._client, {GoogleSignInAdapter? googleSignIn})
      : _googleSignIn = googleSignIn ?? DefaultGoogleSignInAdapter();

  final SupabaseClient _client;
  final GoogleSignInAdapter _googleSignIn;

  @override
  bool get isAvailable => true;

  @override
  Stream<UserModel?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      return user == null ? null : userModelFromSupabase(user);
    });
  }

  @override
  UserModel? get currentUser {
    final u = _client.auth.currentUser;
    return u == null ? null : userModelFromSupabase(u);
  }

  @override
  Future<String?> get currentUserToken async =>
      _client.auth.currentSession?.accessToken;

  @override
  Future<void> invokeFunction(String name) async {
    await _client.functions.invoke(name);
  }

  @override
  Future<UserModel?> signInWithGoogleNative() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw const AuthException('Google neposkytol ID token.');
    }
    final res = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
    final u = res.user;
    return u == null ? null : userModelFromSupabase(u);
  }

  @override
  Future<void> signInWithOAuthGoogle({required String redirectTo}) async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
    );
  }

  @override
  Future<UserModel?> signInWithPassword(String email, String password) async {
    final res =
        await _client.auth.signInWithPassword(email: email, password: password);
    final u = res.user;
    return u == null ? null : userModelFromSupabase(u);
  }

  @override
  Future<UserModel?> signUp(String email, String password) async {
    final res = await _client.auth.signUp(email: email, password: password);
    final u = res.user;
    return u == null ? null : userModelFromSupabase(u);
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // ignore
    }
    await _client.auth.signOut();
  }
}
