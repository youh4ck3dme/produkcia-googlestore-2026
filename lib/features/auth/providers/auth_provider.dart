import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);

class AuthController extends Notifier<AsyncValue<void>> {
  late final AuthRepository _authRepository;

  @override
  AsyncValue<void> build() {
    _authRepository = ref.read(authRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state =
        await AsyncValue.guard(() => _authRepository.signIn(email, password));
  }

  Future<void> signUp(String email, String password) async {
    state = const AsyncValue.loading();
    state =
        await AsyncValue.guard(() => _authRepository.signUp(email, password));
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authRepository.signOut());
  }

  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authRepository.deleteAccount());
  }

  void mockSuccessLogin() {
    state = const AsyncValue.data(null);
  }
}
