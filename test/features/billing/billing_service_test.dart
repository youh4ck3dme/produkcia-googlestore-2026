import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/features/billing/billing_service.dart';
import 'package:bizagent/features/entitlements/user_entitlements.dart';

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

    test('purchaseSuccess defaults to false', () {
      final state = BillingState(entitlements: UserEntitlements.free());
      expect(state.purchaseSuccess, isFalse);
    });

    test('copyWith sets purchaseSuccess', () {
      final state = BillingState(entitlements: UserEntitlements.free());
      final updated = state.copyWith(purchaseSuccess: true);
      expect(updated.purchaseSuccess, isTrue);
    });
  });

  group('UserEntitlements', () {
    test('free() returns non-pro', () {
      final e = UserEntitlements.free();
      expect(e.isPro, isFalse);
      expect(e.isFree, isTrue);
    });

    test('copyWith preserves unspecified fields', () {
      final e = const UserEntitlements(isPro: true, invoiceCount: 3);
      final updated = e.copyWith(icoLookupsCount: 2);
      expect(updated.isPro, isTrue);
      expect(updated.invoiceCount, 3);
      expect(updated.icoLookupsCount, 2);
    });

    test('isExpired returns true for past date', () {
      final e = UserEntitlements(
        isPro: true,
        expiryDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(e.isExpired, isTrue);
    });

    test('isExpired returns false for future date', () {
      final e = UserEntitlements(
        isPro: true,
        expiryDate: DateTime.now().add(const Duration(days: 30)),
      );
      expect(e.isExpired, isFalse);
    });

    test('isExpired returns false when no expiryDate', () {
      const e = UserEntitlements(isPro: true);
      expect(e.isExpired, isFalse);
    });
  });

  group('UserEntitlements persistence', () {
    test('toJson/fromJson round-trip preserves fields', () {
      final original = UserEntitlements(
        isPro: true,
        activePlanId: 'sub_pro_year',
        expiryDate: DateTime(2027, 1, 15),
      );
      final json = original.toJson();
      final restored = UserEntitlements.fromJson(json);
      expect(restored.isPro, isTrue);
      expect(restored.activePlanId, 'sub_pro_year');
      expect(restored.expiryDate, DateTime(2027, 1, 15));
    });

    test('toSpString/fromSpString round-trip', () {
      final original = UserEntitlements(
        isPro: true,
        activePlanId: 'sub_pro_monthly',
        expiryDate: DateTime(2026, 12, 31),
      );
      final spString = original.toSpString();
      final restored = UserEntitlements.fromSpString(spString);
      expect(restored, isNotNull);
      expect(restored!.isPro, isTrue);
      expect(restored.activePlanId, 'sub_pro_monthly');
    });

    test('fromSpString returns null for empty/null', () {
      expect(UserEntitlements.fromSpString(null), isNull);
      expect(UserEntitlements.fromSpString(''), isNull);
    });

    test('fromSpString returns null for invalid JSON', () {
      expect(UserEntitlements.fromSpString('not json'), isNull);
    });

    test('free() toJson has isPro false', () {
      final json = UserEntitlements.free().toJson();
      expect(json['isPro'], isFalse);
      expect(json['activePlanId'], isNull);
    });
  });
}
