import 'package:bizagent/core/models/ico_lookup_result.dart';
import 'package:bizagent/core/providers/theme_provider.dart';
import 'package:bizagent/core/services/company_lookup_service.dart';
import 'package:bizagent/core/services/icoatlas_service.dart';
import 'package:bizagent/features/auth/models/user_model.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/settings/models/user_settings_model.dart';
import 'package:bizagent/features/settings/providers/settings_provider.dart';
import 'package:bizagent/features/settings/providers/settings_repository.dart';
import 'package:bizagent/features/settings/screens/settings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Fake classes to bypass Firebase initialization
class FakeFirebaseFunctions extends Fake implements FirebaseFunctions {}

class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {}

class FakeIcoAtlasService extends Fake implements IcoAtlasService {
  @override
  Future<IcoLookupResult?> publicLookup(String ico) async => null;
}

// Fake service to avoid real API calls
class FakeCompanyLookupService implements CompanyLookupService {
  @override
  Future<IcoLookupResult> lookupByIco(String ico) async {
    if (ico == '36396567') {
      return IcoLookupResult(
        ico: '36396567',
        icoNorm: '36396567',
        name: 'Google Slovakia, s. r. o.',
        status: 'Active',
        city: 'Bratislava',
        street: 'Karadžičova 8/A',
        postalCode: '821 08',
        dic: '2020102636',
        icDph: 'SK2020102636',
        cachedAt: DateTime.now(),
      );
    }
    throw Exception('Not found');
  }
}

class FakeSettingsRepository extends SettingsRepository {
  FakeSettingsRepository() : super(FakeFirebaseFirestore());

  @override
  Stream<UserSettingsModel> watchSettings(String userId) {
    return Stream.value(UserSettingsModel.empty());
  }
}

void main() {
  testWidgets('SettingsScreen populates fields after IČO lookup',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    // Override providers
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          companyLookupServiceProvider
              .overrideWithValue(FakeCompanyLookupService()),
          settingsProvider
              .overrideWith((ref) => Stream.value(UserSettingsModel.empty())),
          settingsRepositoryProvider
              .overrideWithValue(FakeSettingsRepository()),
          authStateProvider.overrideWith((ref) => Stream.value(
              const UserModel(id: 'test-user', email: 'test@example.com'))),
          themeProvider.overrideWith((ref) => ThemeNotifier()), // Default theme
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle(); // Wait for AsyncValue data

    // Initial state: Empty Name
    expect(find.text('Google Slovakia, s. r. o.'), findsNothing);

    // Enter IČO
    // Use a more robust finder for the labels in InputDecoration
    final icoField = find.descendant(
      of: find.byType(TextFormField),
      matching: find.text('IČO'),
    );
    expect(icoField, findsOneWidget);

    await tester.enterText(
        find.ancestor(of: icoField, matching: find.byType(TextFormField)),
        '36396567');
    await tester.pump();

    // Tap Search Icon
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle(); // Wait for async lookup

    // Verify Fields Populated
    expect(find.widgetWithText(TextFormField, 'Google Slovakia, s. r. o.'),
        findsOneWidget);
    expect(
        find.widgetWithText(
            TextFormField, 'Karadžičova 8/A, 821 08 Bratislava'),
        findsOneWidget);
    expect(find.widgetWithText(TextFormField, '2020102636'),
        findsOneWidget); // DIČ
    expect(find.widgetWithText(TextFormField, 'SK2020102636'),
        findsOneWidget); // IČ DPH

    // Verify Snackbar feedback
    expect(find.text('Našli sme: Google Slovakia, s. r. o.'), findsOneWidget);
  });
}
