import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/supabase/auth_backend.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    AuthBackend.fromClient(
      SupabaseConfig.isReady ? SupabaseConfig.client : null,
    ),
  );
});

final authStateProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Auth cez Supabase. Email/heslo + Google OAuth (google_sign_in ponechaný).
/// Anonymné/demo prihlásenie bolo zámerne odstránené (Play release).
class AuthRepository {
  AuthRepository(AuthBackend backend) : _backend = backend;

  final AuthBackend _backend;

  Stream<UserModel?> get authStateChanges => _backend.authStateChanges;

  UserModel? get currentUser => _backend.currentUser;

  Future<String?> get currentUserToken => _backend.currentUserToken;

  Future<UserModel?> signIn(String email, String password) =>
      _backend.signInWithPassword(email, password);

  Future<UserModel?> signUp(String email, String password) =>
      _backend.signUp(email, password);

  Future<UserModel?> signInWithGoogle() async {
    if (kIsWeb) {
      await _backend.signInWithOAuthGoogle(redirectTo: Uri.base.origin);
      return null;
    }
    return _backend.signInWithGoogleNative();
  }

  Future<void> signOut() => _backend.signOut();

  Future<void> deleteAccount() async {
    await _backend.invokeFunction('delete-account');
    await signOut();
  }

  void dispose() {}
}
