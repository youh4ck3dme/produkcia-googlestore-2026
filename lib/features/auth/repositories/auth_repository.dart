abstract class AuthRepository {
  Future<bool> isLoggedIn();
  Future<void> setLoggedIn(bool value);
}
