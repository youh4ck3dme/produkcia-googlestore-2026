import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bizagent/core/i18n/l10n.dart';
import 'package:bizagent/core/ui/biz_theme.dart';
import 'package:bizagent/features/auth/models/user_model.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/settings/models/user_settings_model.dart';
import 'package:bizagent/features/settings/providers/settings_provider.dart';
import 'package:bizagent/features/notifications/services/notification_service.dart';
import 'package:bizagent/features/tools/services/monitoring_service.dart';

import 'fake_monitoring_service.dart';
import 'fake_notification_service.dart';
import 'test_supabase.dart';

Future<void> setUpIntegrationHarness({
  Map<String, Object> prefs = const {
    'seen_onboarding': true,
    'theme_mode': 'light',
  },
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  SharedPreferences.setMockInitialValues(prefs);
  await ensureTestSupabase();
}

Widget integrationApp({
  required Widget child,
  List<Override> overrides = const [],
  UserModel? user,
}) {
  final defaults = <Override>[
    authStateProvider.overrideWith((ref) => Stream.value(user)),
    invoicesProvider.overrideWith((ref) => Stream.value([])),
    expensesProvider.overrideWith((ref) => Stream.value([])),
    settingsProvider.overrideWith((ref) => Stream.value(UserSettingsModel.empty())),
    monitoringServiceProvider.overrideWithValue(FakeMonitoringService()),
    notificationServiceProvider.overrideWithValue(FakeNotificationService()),
  ];

  return ProviderScope(
    overrides: [...defaults, ...overrides],
    child: MaterialApp(
      theme: BizTheme.light(),
      darkTheme: BizTheme.dark(),
      home: L10n(locale: AppLocale.sk, child: child),
    ),
  );
}

Future<void> pumpFrames(WidgetTester tester, {int count = 3}) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
