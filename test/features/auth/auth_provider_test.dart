import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizagent/features/auth/providers/auth_provider.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/auth/models/user_model.dart';

// Mock AuthRepository
class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;
  bool _shouldThrow = false;
  String? _throwError;
  final _authStateController = StreamController<UserModel?>.broadcast();
  late final Stream<UserModel?> authStateChanges;

  MockAuthRepository() {
    _authStateController.add(_currentUser);
    authStateChanges = Stream.value(_currentUser)
        .asyncExpand((_) => _authStateController.stream)
        .asBroadcastStream();
  }

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Future<String?> get currentUserToken async => _currentUser?.id;

  @override
  Future<UserModel?> signIn(String email, String password) async {
    if (_shouldThrow) {
      throw Exception(_throwError ?? 'Sign in failed');
    }
    _currentUser = UserModel(
      id: 'user123',
      email: email,
      displayName: 'Test User',
    );
    _authStateController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<UserModel?> signUp(String email, String password) async {
    if (_shouldThrow) {
      throw Exception(_throwError ?? 'Sign up failed');
    }
    _currentUser = UserModel(
      id: 'newuser123',
      email: email,
      displayName: 'New User',
    );
    _authStateController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    if (_shouldThrow) {
      throw Exception(_throwError ?? 'Google sign in failed');
    }
    _currentUser = UserModel(
      id: 'googleuser123',
      email: 'google@example.com',
      displayName: 'Google User',
    );
    _authStateController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<UserModel?> signInAnonymously() async {
    if (_shouldThrow) {
      throw Exception(_throwError ?? 'Anonymous sign in failed');
    }
    _currentUser = UserModel(
      id: 'anonymous123',
      email: '',
      displayName: 'Demo User',
      isAnonymous: true,
    );
    _authStateController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<void> signOut() async {
    if (_shouldThrow) {
      throw Exception(_throwError ?? 'Sign out failed');
    }
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  void dispose() {
    _authStateController.close();
  }

  void setShouldThrow(bool value, [String? error]) {
    _shouldThrow = value;
    _throwError = error;
  }
}

void main() {
  group('AuthController', () {
    late MockAuthRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('signIn', () {
      test('should set loading state then success state', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        final controller = container.read(authControllerProvider.notifier);

        // Act
        final future = controller.signIn(email, password);

        // Assert - Check loading state
        expect(container.read(authControllerProvider).isLoading, isTrue);

        await future;

        // Assert - Check success state
        expect(container.read(authControllerProvider).hasValue, isTrue);
      });

      test('should set error state on failure', () async {
        // Arrange
        mockRepository.setShouldThrow(true, 'Invalid credentials');
        const email = 'wrong@example.com';
        const password = 'wrongpassword';
        final controller = container.read(authControllerProvider.notifier);

        // Act
        await controller.signIn(email, password);

        // Assert
        expect(container.read(authControllerProvider).hasError, isTrue);
        expect(
          container.read(authControllerProvider).error,
          isA<Exception>(),
        );
      });
    });

    group('signUp', () {
      test('should set loading state then success state', () async {
        // Arrange
        const email = 'newuser@example.com';
        const password = 'password123';
        final controller = container.read(authControllerProvider.notifier);

        // Act
        final future = controller.signUp(email, password);

        // Assert - Check loading state
        expect(container.read(authControllerProvider).isLoading, isTrue);

        await future;

        // Assert - Check success state
        expect(container.read(authControllerProvider).hasValue, isTrue);
      });

      test('should set error state on failure', () async {
        // Arrange
        mockRepository.setShouldThrow(true, 'Email already exists');
        const email = 'existing@example.com';
        const password = 'password123';
        final controller = container.read(authControllerProvider.notifier);

        // Act
        await controller.signUp(email, password);

        // Assert
        expect(container.read(authControllerProvider).hasError, isTrue);
      });
    });

    group('signInWithGoogle', () {
      test('should set loading state then success state', () async {
        // Arrange
        final controller = container.read(authControllerProvider.notifier);

        // Act
        final future = controller.signInWithGoogle();

        // Assert - Check loading state
        expect(container.read(authControllerProvider).isLoading, isTrue);

        await future;

        // Assert - Check success state
        expect(container.read(authControllerProvider).hasValue, isTrue);
      });

      test('should set error state on failure', () async {
        // Arrange
        mockRepository.setShouldThrow(true, 'Google sign in cancelled');
        final controller = container.read(authControllerProvider.notifier);

        // Act
        await controller.signInWithGoogle();

        // Assert
        expect(container.read(authControllerProvider).hasError, isTrue);
      });
    });

    group('signOut', () {
      test('should set loading state then success state', () async {
        // Arrange
        final controller = container.read(authControllerProvider.notifier);

        // Act
        final future = controller.signOut();

        // Assert - Check loading state
        expect(container.read(authControllerProvider).isLoading, isTrue);

        await future;

        // Assert - Check success state
        expect(container.read(authControllerProvider).hasValue, isTrue);
      });

      test('should set error state on failure', () async {
        // Arrange
        mockRepository.setShouldThrow(true, 'Sign out failed');
        final controller = container.read(authControllerProvider.notifier);

        // Act
        await controller.signOut();

        // Assert
        expect(container.read(authControllerProvider).hasError, isTrue);
      });
    });

    group('mockSuccessLogin', () {
      test('should set success state directly', () {
        // Arrange
        final controller = container.read(authControllerProvider.notifier);

        // Act
        controller.mockSuccessLogin();

        // Assert
        expect(container.read(authControllerProvider).hasValue, isTrue);
      });
    });

    group('state transitions', () {
      test('should transition from data to loading to data', () async {
        // Arrange
        final controller = container.read(authControllerProvider.notifier);
        const email = 'test@example.com';
        const password = 'password123';

        // Initial state should be data
        expect(container.read(authControllerProvider).hasValue, isTrue);

        // Act
        final future = controller.signIn(email, password);

        // Should be loading
        expect(container.read(authControllerProvider).isLoading, isTrue);

        await future;

        // Should be data again
        expect(container.read(authControllerProvider).hasValue, isTrue);
      });

      test('should transition from data to loading to error', () async {
        // Arrange
        mockRepository.setShouldThrow(true, 'Test error');
        final controller = container.read(authControllerProvider.notifier);
        const email = 'test@example.com';
        const password = 'password123';

        // Initial state should be data
        expect(container.read(authControllerProvider).hasValue, isTrue);

        // Act
        await controller.signIn(email, password);

        // Should be error
        expect(container.read(authControllerProvider).hasError, isTrue);
      });
    });
  });
}
