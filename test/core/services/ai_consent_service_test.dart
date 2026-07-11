import 'package:bizagent/core/services/ai_consent_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AiConsentService', () {
    late AiConsentService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = AiConsentService();
    });

    test('hasConsent returns false by default', () async {
      expect(await service.hasConsent(), isFalse);
    });

    test('grantConsent persists consent', () async {
      await service.grantConsent();
      expect(await service.hasConsent(), isTrue);
    });

    test('revokeConsent clears consent', () async {
      await service.grantConsent();
      await service.revokeConsent();
      expect(await service.hasConsent(), isFalse);
    });
  });
}