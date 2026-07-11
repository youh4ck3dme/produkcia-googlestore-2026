import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/models/user_model.dart';
import 'google_auth_service.dart';

/// Tenká auth abstrakcia pre testovateľný [AuthRepository].
abstract class AuthBackend {
  bool get isAvailable;

  Stream<UserModel?> get authStateChanges;

  UserModel? get currentUser;

  Future<String?> get currentUserToken;

  Future<UserModel?> signInWithPassword(String email, String password);

  Future<UserModel?> signUp(String email, String password);

  Future<UserModel?> signInWithGoogle();

  Future<void> signOut();

  Future<void> invokeFunction(String name);

  factory AuthBackend.fromClient(SupabaseClient? client) {
    if (client == null) return _UnavailableAuthBackend();
    return SupabaseAuthBackend(client);
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
  Future<UserModel?> signInWithPassword(String email, String password) async {
    throw StateError(_missingConfigMessage);
  }

  @override
  Future<UserModel?> signUp(String email, String password) async {
    throw StateError(_missingConfigMessage);
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    throw StateError(_missingConfigMessage);
  }

  @override
  Future<void> signOut() async {}
}

class SupabaseAuthBackend implements AuthBackend {
  SupabaseAuthBackend(this._client);

  final SupabaseClient _client;
  late final GoogleAuthService _googleAuth = GoogleAuthService(_client);

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
  Future<UserModel?> signInWithGoogle() => _googleAuth.signIn();

  @override
  Future<void> signOut() async {
    await _googleAuth.signOutNative();
    await _client.auth.signOut();
  }
}