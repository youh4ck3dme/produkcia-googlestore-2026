import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_config.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    SupabaseConfig.isReady ? SupabaseConfig.client : null,
  );
});

final authStateProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Auth cez Supabase. Email/heslo + Google OAuth (google_sign_in ponechaný).
/// Anonymné/demo prihlásenie bolo zámerne odstránené (Play release).
class AuthRepository {
  final SupabaseClient? _client;

  AuthRepository(this._client);

  /// Vyhodí čitateľnú chybu ak Supabase nie je nakonfigurovaný.
  SupabaseClient get _sb {
    final c = _client;
    if (c == null) {
      throw StateError(
        'Supabase nie je nakonfigurovaný — chýba SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY.',
      );
    }
    return c;
  }

  UserModel _fromUser(User u) => UserModel(
        id: u.id,
        email: u.email ?? '',
        displayName: (u.userMetadata?['full_name'] ?? u.userMetadata?['name']) as String?,
        photoUrl: u.userMetadata?['avatar_url'] as String?,
        isAnonymous: u.isAnonymous,
      );

  /// Stream stavu prihlásenia. Najprv aktuálny user, potom zmeny.
  Stream<UserModel?> get authStateChanges {
    final c = _client;
    if (c == null) return Stream<UserModel?>.value(null);
    return c.auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      return user == null ? null : _fromUser(user);
    });
  }

  UserModel? get currentUser {
    final u = _client?.auth.currentUser;
    return u == null ? null : _fromUser(u);
  }

  Future<String?> get currentUserToken async =>
      _client?.auth.currentSession?.accessToken;

  Future<UserModel?> signIn(String email, String password) async {
    final res = await _sb.auth.signInWithPassword(email: email, password: password);
    final u = res.user;
    return u == null ? null : _fromUser(u);
  }

  Future<UserModel?> signUp(String email, String password) async {
    final res = await _sb.auth.signUp(email: email, password: password);
    final u = res.user;
    return u == null ? null : _fromUser(u);
  }

  Future<UserModel?> signInWithGoogle() async {
    if (kIsWeb) {
      // Na webe OAuth redirect — výsledok zachytí onAuthStateChange po reloade.
      await _sb.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: Uri.base.origin,
      );
      return null;
    }

    // Natívne: google_sign_in → ID token → Supabase signInWithIdToken.
    // serverClientId musí byť Web OAuth client ID z Google Cloud (nakonfiguruj
    // ho v Supabase Auth → Google providers).
    const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    final googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: webClientId.isEmpty ? null : webClientId,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null; // používateľ zrušil
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw const AuthException('Google neposkytol ID token.');
    }

    final res = await _sb.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
    final u = res.user;
    return u == null ? null : _fromUser(u);
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // ignore
    }
    await _client?.auth.signOut();
  }

  /// Zmaže účet + všetky dáta cez edge funkciu `delete-account`
  /// (kaskádové mazanie riadkov + storage na strane servera so service_role).
  Future<void> deleteAccount() async {
    await _sb.functions.invoke('delete-account');
    await signOut();
  }

  void dispose() {}
}
