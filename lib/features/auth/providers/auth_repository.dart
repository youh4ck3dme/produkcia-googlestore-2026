import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/debug/agent_log.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance);
});

final authStateProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

class AuthRepository {
  final FirebaseAuth _auth;
  final _authStateController = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;
  late final Stream<UserModel?> authStateChanges;
  StreamSubscription<User?>? _authSubscription;
  AuthRepository(this._auth) {
    _init();
    _initInitialValue();

    // Initialize stable stream that always yields current state first
    authStateChanges = _buildAuthStream().asBroadcastStream();
  }

  Stream<UserModel?> _buildAuthStream() async* {
    yield _currentUser;
    yield* _authStateController.stream;
  }

  void _initInitialValue() {
    final user = _auth.currentUser;
    if (user != null) {
      _currentUser = UserModel(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        isAnonymous: user.isAnonymous,
      );
    }
    _authStateController.add(_currentUser);
  }

  void _init() {
    // Explicitly set persistence to LOCAL (long-lived) on WEB only.
    if (kIsWeb) {
      try {
        _auth.setPersistence(Persistence.LOCAL);
      } catch (e) {
        debugPrint('Auth persistence not supported: $e');
      }
    }

    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (_currentUser != null && _currentUser!.id == 'fake-id-123') return;

      if (user == null) {
        _currentUser = null;
      } else {
        _currentUser = UserModel(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoUrl: user.photoURL,
          isAnonymous: user.isAnonymous,
        );
      }
      _authStateController.add(_currentUser);
    });
  }

  // Helper to get current user immediately
  UserModel? get currentUser => _currentUser;

  // Helper to get Firebase ID Token
  Future<String?> get currentUserToken async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  Future<UserModel?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      if (user == null) return null;
      final userModel = UserModel(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
        isAnonymous: user.isAnonymous,
      );
      _authStateController.add(userModel);
      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> signUp(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      if (user == null) return null;
      final userModel = UserModel(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
        isAnonymous: user.isAnonymous,
      );
      _authStateController.add(userModel);
      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      // #region agent log
      unawaited(agentLog(
        hypothesisId: 'H1',
        location: 'lib/features/auth/providers/auth_repository.dart:signInWithGoogle:entry',
        message: 'signInWithGoogle called',
        data: {
          'kIsWeb': kIsWeb,
          'platform': defaultTargetPlatform.toString(),
        },
      ));
      // #endregion agent log

      if (kIsWeb) {
        // Prefer FirebaseAuth popup on web (more reliable than google_sign_in web setup).
        final GoogleAuthProvider googleProvider = GoogleAuthProvider()..addScope('email');
        final result = await _auth.signInWithPopup(googleProvider);
        final user = result.user;
        if (user == null) return null;

        final userModel = UserModel(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoUrl: user.photoURL,
          isAnonymous: user.isAnonymous,
        );
        _authStateController.add(userModel);
        return userModel;
      }

      final googleSignIn = GoogleSignIn(scopes: const ['email']);

      GoogleSignInAccount? googleUser;
      try {
        googleUser = await googleSignIn.signIn();
      } catch (e) {
        // #region agent log
        unawaited(agentLog(
          hypothesisId: 'H4',
          location: 'lib/features/auth/providers/auth_repository.dart:signInWithGoogle:googleSignIn.catch',
          message: 'googleSignIn.signIn threw',
          data: {
            'type': e.runtimeType.toString(),
            'msg': e.toString().substring(0, e.toString().length.clamp(0, 200)),
          },
        ));
        // #endregion agent log
        debugPrint('Google Sign-In error: $e');
        return null;
      }

      // #region agent log
      unawaited(agentLog(
        hypothesisId: 'H2',
        location: 'lib/features/auth/providers/auth_repository.dart:signInWithGoogle:afterGoogleSignIn',
        message: 'googleSignIn.signIn completed',
        data: {
          'googleUserNull': googleUser == null,
        },
      ));
      // #endregion agent log

      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      // #region agent log
      unawaited(agentLog(
        hypothesisId: 'H3',
        location: 'lib/features/auth/providers/auth_repository.dart:signInWithGoogle:afterAuth',
        message: 'googleUser.authentication completed',
        data: {
          'hasIdToken': googleAuth.idToken != null,
          'hasAccessToken': googleAuth.accessToken != null,
        },
      ));
      // #endregion agent log

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;

      // #region agent log
      unawaited(agentLog(
        hypothesisId: 'H1',
        location: 'lib/features/auth/providers/auth_repository.dart:signInWithGoogle:afterCredential',
        message: 'FirebaseAuth.signInWithCredential completed',
        data: {
          'firebaseUserNull': user == null,
          'isAnonymous': user?.isAnonymous ?? false,
        },
      ));
      // #endregion agent log

      if (user == null) return null;

      final userModel = UserModel(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
        isAnonymous: user.isAnonymous,
      );

      _authStateController.add(userModel);
      return userModel;
    } catch (e) {
      // #region agent log
      unawaited(agentLog(
        hypothesisId: 'H5',
        location: 'lib/features/auth/providers/auth_repository.dart:signInWithGoogle:outerCatch',
        message: 'signInWithGoogle threw (outer catch)',
        data: {
          'type': e.runtimeType.toString(),
          'msg': e.toString().substring(0, e.toString().length.clamp(0, 200)),
        },
      ));
      // #endregion agent log
      debugPrint('Firebase Auth error: $e');
      rethrow;
    }
  }

  Future<UserModel?> signInAnonymously() async {
    try {
      final result = await _auth.signInAnonymously();
      final user = result.user;
      if (user == null) return null;
      final userModel = UserModel(
        id: user.uid,
        email: '', // Anonymous users don't have email
        displayName: 'Demo User',
        photoUrl: null,
        isAnonymous: true,
      );
      _authStateController.add(userModel);
      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    _currentUser = null;
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // ignore
    }
    await _auth.signOut();
    _authStateController.add(null);
  }

  void dispose() {
    _authSubscription?.cancel();
    _authStateController.close();
  }
}
