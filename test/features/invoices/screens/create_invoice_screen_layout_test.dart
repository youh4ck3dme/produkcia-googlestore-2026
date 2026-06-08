import 'package:bizagent/core/config/play_release_scope.dart';
import 'package:bizagent/core/models/ico_lookup_result.dart';
import 'package:bizagent/core/services/icoatlas_service.dart';
import 'package:bizagent/core/ui/biz_theme.dart';
import 'package:bizagent/features/auth/models/user_model.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/invoices/screens/create_invoice_screen.dart';
import 'package:bizagent/features/settings/models/user_settings_model.dart';
import 'package:bizagent/features/settings/providers/settings_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../helpers/layout_test_helpers.dart';

class FakeIcoAtlasService extends IcoAtlasService {
  FakeIcoAtlasService() : super(Dio(BaseOptions(baseUrl: 'http://localhost')));

  @override
  Future<List<Map<String, dynamic>>> autocomplete(String query) async => [];

  @override
  Future<IcoLookupResult?> publicLookup(String ico) async => null;
}

Widget createInvoiceTestApp() {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith(
        (ref) => Stream.value(
          const UserModel(
            id: 'test-user',
            email: 'test@example.com',
            displayName: 'Test user',
            isAnonymous: true,
          ),
        ),
      ),
      settingsProvider.overrideWith(
        (ref) => Stream.value(
          UserSettingsModel.empty().copyWith(
            companyName: 'My Biz',
            isVatPayer: true,
          ),
        ),
      ),
      icoAtlasServiceProvider.overrideWithValue(FakeIcoAtlasService()),
    ],
    child: MaterialApp(
      theme: BizTheme.light(),
      home: const CreateInvoiceScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
    'premium form sections render with uppercase headers and bordered inputs',
    (tester) async {
      await pumpAtViewport(
        tester,
        createInvoiceTestApp(),
        physicalSize: const Size(390, 900),
      );

      expect(find.text('ODBERATEĽ'), findsOneWidget);
      expect(find.text('DETAILY FAKTÚRY'), findsOneWidget);
      expect(find.text('POLOŽKY'), findsOneWidget);
      expect(find.byTooltip('AI Vyplniť'), findsOneWidget);

      expect(find.byType(TextFormField), findsWidgets);

      final inputTheme = BizTheme.light().inputDecorationTheme;
      final enabled = inputTheme.enabledBorder as OutlineInputBorder?;
      expect(enabled?.borderSide.width, 1);
      expect(enabled?.borderSide.color, BizTheme.gray200);

      expectNoLayoutOverflow(tester);
    },
    skip: PlayReleaseScope.playMvp,
  );

  testWidgets(
    'create invoice screen avoids overflow on narrow viewports',
    (tester) async {
      addTearDown(() => resetTestView(tester));
      // Realistic mobile widths (full invoice form needs more than 150 logical px).
      for (final width in [320.0, 360.0, 400.0]) {
        await pumpAtViewport(
          tester,
          createInvoiceTestApp(),
          physicalSize: Size(width, 800),
          textScaleFactor: 1.3,
        );
        expectNoLayoutOverflow(tester);
      }
    },
    skip: PlayReleaseScope.playMvp,
  );
}
