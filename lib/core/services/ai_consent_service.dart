import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _consentKey = 'bizagent_ai_consent_granted_v1';

final aiConsentServiceProvider = Provider<AiConsentService>((ref) {
  return AiConsentService();
});

/// Tracks explicit user consent for AI features (GDPR Art. 6(1)(a)).
class AiConsentService {
  Future<bool> hasConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentKey) ?? false;
  }

  Future<void> grantConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, true);
  }

  Future<void> revokeConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_consentKey);
  }
}