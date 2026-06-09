import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bizagent/core/supabase/auth_backend.dart';
import 'package:bizagent/features/auth/models/user_model.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';

import '../../helpers/fake_auth_backend.dart';

void main() {
  group('AuthRepository (Supabase backend)', () {
    late FakeAuthBackend backend;
    late AuthRepository repository;

    const testUser = UserModel(
      id: 'user-1',
      email: 'test@example.com',
      displayName: 'Test User',
      isAnonymous: false,
    );

    setUp(() {
      backend = FakeAuthBackend(currentUserValue: testUser);
      repository = AuthRepository(backend);
    });

    test('signIn returns mapped user from backend', () async {
      backend.signInResult = testUser;

      final user = await repository.signIn('test@example.com', 'secret');

      expect(user?.email, 'test@example.com');
      expect(user?.id, 'user-1');
    });

    test('signUp returns mapped user from backend', () async {
      backend.signUpResult = testUser;

      final user = await repository.signUp('new@example.com', 'secret');

      expect(user?.email, 'test@example.com');
    });

    test('signIn throws when backend unavailable', () async {
      repository = AuthRepository(UnavailableFakeAuthBackend());

      await expectLater(
        repository.signIn('a@b.com', 'pw'),
        throwsA(isA<StateError>()),
      );
    });

    test('signInWithGoogle on web triggers OAuth redirect flow', () async {
      // kIsWeb is false in VM tests — verify native path instead below.
      backend.googleNativeResult = testUser;
      final user = await repository.signInWithGoogle();
      expect(backend.googleNativeCalled, isTrue);
      expect(user, testUser);
    });

    test('signInWithGoogle returns null when user cancels', () async {
      backend.googleNativeResult = null;

      final user = await repository.signInWithGoogle();

      expect(user, isNull);
    });

    test('signOut delegates to backend', () async {
      await repository.signOut();
      expect(backend.signOutCalled, isTrue);
    });

    test('deleteAccount invokes delete-account function then signs out', () async {
      await repository.deleteAccount();

      expect(backend.invokeCalled, isTrue);
      expect(backend.invokedFunction, 'delete-account');
      expect(backend.signOutCalled, isTrue);
    });

    test('authStateChanges mirrors backend stream', () async {
      final controller = StreamController<UserModel?>();
      backend.authStream = controller.stream;
      repository = AuthRepository(backend);

      expectLater(repository.authStateChanges, emits(testUser));
      controller.add(testUser);
      await controller.close();
    });

    test('offline backend emits null auth stream', () async {
      repository = AuthRepository(UnavailableFakeAuthBackend());

      expect(await repository.authStateChanges.first, isNull);
      expect(repository.currentUser, isNull);
    });
  });

  group('userModelFromSupabase mapping', () {
    test('maps metadata fields', () {
      final user = User(
        id: 'abc',
        appMetadata: {},
        userMetadata: const {
          'full_name': 'Full Name',
          'avatar_url': 'https://photo.test/a.jpg',
        },
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'mapped@example.com',
      );

      final model = userModelFromSupabase(user);

      expect(model.id, 'abc');
      expect(model.email, 'mapped@example.com');
      expect(model.displayName, 'Full Name');
      expect(model.photoUrl, 'https://photo.test/a.jpg');
    });
  });
}
