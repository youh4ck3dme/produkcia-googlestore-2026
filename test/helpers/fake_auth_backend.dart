import 'dart:async';

import 'package:bizagent/core/supabase/auth_backend.dart';
import 'package:bizagent/features/auth/models/user_model.dart';

class FakeAuthBackend implements AuthBackend {
  FakeAuthBackend({
    this.isAvailable = true,
    this.currentUserValue,
    this.authStream,
  });

  bool isAvailable;
  UserModel? currentUserValue;
  Stream<UserModel?>? authStream;

  bool oauthCalled = false;
  String? oauthRedirect;
  bool googleNativeCalled = false;
  UserModel? googleNativeResult;
  bool signOutCalled = false;
  bool invokeCalled = false;
  String? invokedFunction;

  UserModel? signInResult;
  UserModel? signUpResult;
  bool signInCalled = false;
  String? lastSignInEmail;
  String? lastSignInPassword;
  Exception? signInError;
  Exception? signUpError;
  Exception? googleNativeError;

  @override
  Stream<UserModel?> get authStateChanges =>
      authStream ?? Stream<UserModel?>.value(currentUserValue);

  @override
  UserModel? get currentUser => currentUserValue;

  @override
  Future<String?> get currentUserToken async => 'fake-token';

  @override
  Future<void> invokeFunction(String name) async {
    invokeCalled = true;
    invokedFunction = name;
  }

  @override
  Future<UserModel?> signInWithGoogleNative() async {
    googleNativeCalled = true;
    if (googleNativeError != null) throw googleNativeError!;
    return googleNativeResult;
  }

  @override
  Future<void> signInWithOAuthGoogle({required String redirectTo}) async {
    oauthCalled = true;
    oauthRedirect = redirectTo;
  }

  @override
  Future<UserModel?> signInWithPassword(String email, String password) async {
    signInCalled = true;
    lastSignInEmail = email;
    lastSignInPassword = password;
    if (signInError != null) throw signInError!;
    return signInResult;
  }

  @override
  Future<UserModel?> signUp(String email, String password) async {
    if (signUpError != null) throw signUpError!;
    return signUpResult;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    currentUserValue = null;
  }
}

class UnavailableFakeAuthBackend extends FakeAuthBackend {
  UnavailableFakeAuthBackend()
      : super(isAvailable: false, currentUserValue: null);

  static const _missingConfigMessage =
      'Supabase nie je nakonfigurovaný — chýba SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY.';

  @override
  bool get isAvailable => false;

  @override
  Future<UserModel?> signInWithPassword(String email, String password) async {
    throw StateError(_missingConfigMessage);
  }

  @override
  Future<UserModel?> signUp(String email, String password) async {
    throw StateError(_missingConfigMessage);
  }
}
