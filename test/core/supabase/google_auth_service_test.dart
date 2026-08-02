import 'package:flutter_test/flutter_test.dart';

import 'package:bizagent/core/supabase/google_auth_service.dart';

void main() {
  group('GoogleAuthService.resolveIsConfigured', () {
    test('false when Supabase is not ready', () {
      expect(
        GoogleAuthService.resolveIsConfigured(
          supabaseReady: false,
          isWeb: true,
          googleWebClientId: 'client-id',
        ),
        isFalse,
      );
      expect(
        GoogleAuthService.resolveIsConfigured(
          supabaseReady: false,
          isWeb: false,
          googleWebClientId: 'client-id',
        ),
        isFalse,
      );
    });

    test('web is true when Supabase ready even without web client id', () {
      expect(
        GoogleAuthService.resolveIsConfigured(
          supabaseReady: true,
          isWeb: true,
          googleWebClientId: '',
        ),
        isTrue,
      );
    });

    test('native is false when GOOGLE_WEB_CLIENT_ID is empty', () {
      expect(
        GoogleAuthService.resolveIsConfigured(
          supabaseReady: true,
          isWeb: false,
          googleWebClientId: '',
        ),
        isFalse,
      );
    });

    test('native is true when GOOGLE_WEB_CLIENT_ID is set', () {
      expect(
        GoogleAuthService.resolveIsConfigured(
          supabaseReady: true,
          isWeb: false,
          googleWebClientId:
              '90348815049-e5faruj0mfvnn34m80k9b9b5upp9nn6v.apps.googleusercontent.com',
        ),
        isTrue,
      );
    });
  });
}
