import 'package:flutter_test/flutter_test.dart';

import 'package:bizagent/core/router/oauth_login_hold.dart';

void main() {
  group('shouldHoldLoginForOAuthCode', () {
    test('web + code + logged out → hold on login', () {
      expect(
        shouldHoldLoginForOAuthCode(
          isWeb: true,
          queryParameters: const {'code': 'abc'},
          isLoggedIn: false,
        ),
        isTrue,
      );
    });

    test('web + code + logged in → do not hold', () {
      expect(
        shouldHoldLoginForOAuthCode(
          isWeb: true,
          queryParameters: const {'code': 'abc'},
          isLoggedIn: true,
        ),
        isFalse,
      );
    });

    test('native ignores code query', () {
      expect(
        shouldHoldLoginForOAuthCode(
          isWeb: false,
          queryParameters: const {'code': 'abc'},
          isLoggedIn: false,
        ),
        isFalse,
      );
    });

    test('web without code → do not hold', () {
      expect(
        shouldHoldLoginForOAuthCode(
          isWeb: true,
          queryParameters: const {},
          isLoggedIn: false,
        ),
        isFalse,
      );
    });
  });
}
