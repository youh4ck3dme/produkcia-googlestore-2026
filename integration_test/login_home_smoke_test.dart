import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:bizagent/app.dart';
import 'package:bizagent/core/services/local_persistence_service.dart';
import 'package:bizagent/core/supabase/supabase_config.dart';
import 'package:bizagent/core/supabase/oauth_callback_handler.dart';
import 'package:bizagent/features/limits/usage_limiter.dart';
import 'package:bizagent/features/dashboard/screens/dashboard_screen.dart';
import 'package:bizagent/features/auth/screens/firebase_login_screen.dart';
import 'package:bizagent/firebase_options.dart';

/// Live smoke: email login → dashboard (home).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final email = const String.fromEnvironment(
    'PLAY_SMOKE_EMAIL',
    defaultValue: 'bizagent@bizagent.sk',
  );
  final password = const String.fromEnvironment('PLAY_SMOKE_PASSWORD');

  setUpAll(() async {
    await Hive.initFlutter();
    await initializeDateFormatting('sk', null);
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await SupabaseConfig.initialize();
    await recoverOAuthSessionFromBrowserUrl();
  });

  testWidgets('login smoke: email → dashboard', (tester) async {
    if (password.isEmpty) {
      fail('Chýba --dart-define=PLAY_SMOKE_PASSWORD=...');
    }

    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({'seen_onboarding': true});
    final sharedPrefs = await SharedPreferences.getInstance();
    final persistence = LocalPersistenceService();
    await persistence.init();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(sharedPrefs),
          localPersistenceServiceProvider.overrideWithValue(persistence),
        ],
        child: const BizAgentApp(),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 20));

    expect(find.byType(FirebaseLoginScreen), findsOneWidget);

    final fields = find.byType(TextField);
    expect(fields, findsAtLeast(2));
    await tester.enterText(fields.at(0), email);
    await tester.enterText(fields.at(1), password);
    await tester.pump();

    await tester.tap(find.text('Prihlásiť sa'));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 25));

    expect(
      find.byType(DashboardScreen),
      findsOneWidget,
      reason: 'Po prihlásení očakávaný Dashboard (home)',
    );
  });
}