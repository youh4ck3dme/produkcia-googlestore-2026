import 'package:shared_preferences/shared_preferences.dart';
import 'auth_repository.dart';

class LocalAuthRepository implements AuthRepository {
  static const _kLoggedIn = 'auth_logged_in';

  @override
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kLoggedIn) ?? false;
  }

  @override
  Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedIn, value);
  }
}
