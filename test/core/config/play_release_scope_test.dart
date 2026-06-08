import 'package:bizagent/core/config/play_release_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayReleaseScope (Play MVP)', () {
    test('BizBot je povolený v Play MVP', () {
      expect(PlayReleaseScope.showBizBot, isTrue);
      expect(PlayReleaseScope.showBizBotCard, isTrue);
    });

    test('Asistent nav je zapnutý aj keď plný AI hub nie', () {
      if (PlayReleaseScope.playMvp) {
        expect(PlayReleaseScope.showAiToolsNav, isFalse);
        expect(PlayReleaseScope.showAssistantNav, isTrue);
      }
    });

    test('BizBot route nie je disabled v Play MVP', () {
      if (PlayReleaseScope.playMvp) {
        expect(PlayReleaseScope.isRouteDisabled('/ai-tools/biz-bot'), isFalse);
        expect(PlayReleaseScope.isRouteDisabled('/ai-tools'), isFalse);
        expect(PlayReleaseScope.isRouteDisabled('/ai-tools/email-generator'), isTrue);
        expect(PlayReleaseScope.isRouteDisabled('/icoatlas'), isTrue);
      }
    });

    test('Demo mode je vypnutý v Play MVP', () {
      if (PlayReleaseScope.playMvp) {
        expect(PlayReleaseScope.allowDemoMode, isFalse);
        expect(PlayReleaseScope.showDemoModeGesture, isFalse);
      }
    });
  });
}
