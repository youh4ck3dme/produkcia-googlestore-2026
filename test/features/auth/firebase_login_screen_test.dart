import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bizagent/core/i18n/l10n.dart';
import 'package:bizagent/core/ui/biz_theme.dart';
import 'package:bizagent/features/auth/models/user_model.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/auth/screens/firebase_login_screen.dart';

import '../../helpers/fake_auth_backend.dart';
import '../../helpers/layout_test_helpers.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(() {
    FirebaseLoginScreen.debugForceGoogleSignInAvailable = null;
  });

  testWidgets('FirebaseLoginScreen renders email and password fields',
      (tester) async {
    addTearDown(() => resetTestView(tester));
    final backend = FakeAuthBackend();

    await pumpAtViewport(
      tester,
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(AuthRepository(backend)),
        ],
        child: MaterialApp(
          theme: BizTheme.light(),
          home: const L10n(
            locale: AppLocale.sk,
            child: FirebaseLoginScreen(),
          ),
        ),
      ),
      physicalSize: const Size(390, 844),
    );

    expect(find.byType(TextField), findsAtLeast(2));
    expect(find.text('Prihlásiť sa'), findsOneWidget);
    expect(find.text('Prihlásiť sa cez Google'), findsNothing);
    expectNoLayoutOverflow(tester);
  });

  testWidgets('Google button visible and calls signInWithGoogle when forced',
      (tester) async {
    addTearDown(() => resetTestView(tester));
    FirebaseLoginScreen.debugForceGoogleSignInAvailable = true;
    final backend = FakeAuthBackend(
      signInWithGoogleResult: const UserModel(
        id: 'g-1',
        email: 'google@test.com',
      ),
    );

    await pumpAtViewport(
      tester,
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(AuthRepository(backend)),
        ],
        child: MaterialApp(
          theme: BizTheme.light(),
          home: const L10n(
            locale: AppLocale.sk,
            child: FirebaseLoginScreen(),
          ),
        ),
      ),
      physicalSize: const Size(390, 844),
    );

    expect(find.text('Prihlásiť sa cez Google'), findsOneWidget);
    await tester.tap(find.text('Prihlásiť sa cez Google'));
    await tester.pumpAndSettle();

    expect(backend.signInWithGoogleCalled, isTrue);
  });

  testWidgets('tap Prihlásiť sa calls auth repository signIn', (tester) async {
    addTearDown(() => resetTestView(tester));
    final backend = FakeAuthBackend();

    await pumpAtViewport(
      tester,
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(AuthRepository(backend)),
        ],
        child: MaterialApp(
          theme: BizTheme.light(),
          home: const L10n(
            locale: AppLocale.sk,
            child: FirebaseLoginScreen(),
          ),
        ),
      ),
      physicalSize: const Size(390, 844),
    );

    await tester.enterText(find.byType(TextField).at(0), 'user@test.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Prihlásiť sa'));
    await tester.pumpAndSettle();

    expect(backend.signInCalled, isTrue);
    expect(backend.lastSignInEmail, 'user@test.com');
    expect(backend.lastSignInPassword, 'password123');
  });
}
