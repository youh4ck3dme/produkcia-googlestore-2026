import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizagent/features/invoices/screens/create_invoice_screen.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/settings/providers/settings_provider.dart';
import 'package:bizagent/features/settings/models/user_settings_model.dart';
import 'package:bizagent/features/auth/models/user_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:bizagent/core/services/icoatlas_service.dart';
import 'package:bizagent/core/models/ico_lookup_result.dart';

class FakeIcoAtlasService extends IcoAtlasService {
  FakeIcoAtlasService() : super(Dio(BaseOptions(baseUrl: 'http://localhost')));

  @override
  Future<List<Map<String, dynamic>>> autocomplete(String query) async => [];

  @override
  Future<IcoLookupResult?> publicLookup(String ico) async => null;
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        // Mock Auth State
        authStateProvider.overrideWith((ref) => Stream.value(const UserModel(
          id: 'test-user',
          email: 'test@example.com',
          displayName: 'Test user',
        ))),
        // Mock Settings
        settingsProvider.overrideWith((ref) => Stream.value(UserSettingsModel.empty().copyWith(
          companyName: 'My Biz',
          isVatPayer: true,
        ))),
        icoAtlasServiceProvider.overrideWithValue(FakeIcoAtlasService()),
      ],
      child: const MaterialApp(
        home: CreateInvoiceScreen(),
      ),
    );
  }

  testWidgets('AI Magic Fill populates fields and can be undone', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // 1. Verify initial state: AI button exists in Slovak
    final aiButton = find.text('AI Vyplniť');
    expect(aiButton, findsOneWidget);
    expect(find.text('Oatmeal Digital s.r.o.'), findsNothing);
    
    // 2. Click AI Vyplniť
    await tester.tap(aiButton);
    await tester.pumpAndSettle();

    // 3. Verify data is populated
    expect(find.text('Oatmeal Digital s.r.o.'), findsOneWidget);
    
    // 4. Verify highlighting: InputDecorations should have "Navrhnuté AI" helper
    expect(find.text('Navrhnuté AI'), findsAtLeast(1));

    // 5. Verify adaptive UI: Details should be hidden now
    expect(find.text('DIČ'), findsNothing);
    
    // 6. Test Undo
    final undoButton = find.byIcon(Icons.undo);
    expect(undoButton, findsOneWidget);
    
    await tester.tap(undoButton);
    await tester.pumpAndSettle();
    
    // Data should be cleared (or restored to empty)
    expect(find.text('Oatmeal Digital s.r.o.'), findsNothing);
    expect(find.text('Navrhnuté AI'), findsNothing);
    
    // 7. Re-apply and verify Item
    await tester.tap(aiButton);
    await tester.pumpAndSettle();

    final itemFinder = find.text('Mesačný paušál - správa kampaní');
    await tester.dragUntilVisible(
      itemFinder,
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    
    expect(itemFinder, findsOneWidget);
    // Verified item presence via title, avoiding strict formatting checks for amount in unit tests
    expect(find.byType(ListTile), findsAtLeast(1));
  });
}
