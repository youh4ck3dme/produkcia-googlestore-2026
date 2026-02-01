import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/features/billing/billing_service.dart';
import 'package:bizagent/features/entitlements/user_entitlements.dart';

/// Unit tests for BillingState and UserEntitlements (models only).
/// BillingService IAP logic is tested via integration or with Firebase Emulator.
void main() {
  group('BillingState', () {
    test('copyWith preserves unspecified fields', () {
      final state = BillingState(
        entitlements: UserEntitlements.free().copyWith(invoiceCount: 5),
        isLoading: false,
      );
      final updated = state.copyWith(isLoading: true);
      expect(updated.isLoading, isTrue);
      expect(updated.entitlements.invoiceCount, 5);
    });

    test('copyWith can clear errorMessage', () {
      final state = BillingState(
        entitlements: UserEntitlements.free(),
        errorMessage: 'Error',
      );
      final updated = state.copyWith(errorMessage: null);
      expect(updated.errorMessage, isNull);
    });
  });

  group('UserEntitlements', () {
    test('free() returns non-pro, non-business', () {
      final e = UserEntitlements.free();
      expect(e.isPro, isFalse);
      expect(e.isBusiness, isFalse);
      expect(e.isFree, isTrue);
    });

    test('copyWith preserves unspecified fields', () {
      final e = const UserEntitlements(isPro: true, invoiceCount: 3);
      final updated = e.copyWith(icoLookupsCount: 2);
      expect(updated.isPro, isTrue);
      expect(updated.invoiceCount, 3);
      expect(updated.icoLookupsCount, 2);
    });
  });
}
