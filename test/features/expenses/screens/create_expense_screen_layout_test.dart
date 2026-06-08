import 'package:bizagent/core/config/play_release_scope.dart';
import 'package:bizagent/core/ui/biz_theme.dart';
import 'package:bizagent/features/auth/models/user_model.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';
import 'package:bizagent/features/expenses/screens/create_expense_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../helpers/layout_test_helpers.dart';
import '../../../helpers/memory_local_persistence.dart';
import '../../../helpers/in_memory_supabase_store.dart';
import 'package:bizagent/features/expenses/providers/expenses_repository.dart';

Widget createExpenseTestApp() {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith(
        (ref) => Stream.value(
          const UserModel(
            id: 'test-user',
            email: 'test@example.com',
            displayName: 'Test user',
            isAnonymous: false,
          ),
        ),
      ),
      expensesRepositoryProvider.overrideWithValue(
        ExpensesRepository(InMemorySupabaseStore(), MemoryLocalPersistenceService()),
      ),
    ],
    child: MaterialApp(
      theme: BizTheme.light(),
      home: const CreateExpenseScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
    'create expense screen renders core fields and avoids overflow',
    (tester) async {
      addTearDown(() => resetTestView(tester));

      for (final width in [320.0, 360.0, 400.0]) {
        await pumpAtViewport(
          tester,
          createExpenseTestApp(),
          physicalSize: Size(width, 900),
          textScaleFactor: 1.3,
        );

        expect(find.text('Nový výdavok'), findsOneWidget);
        expect(find.text('Obchod / Dodávateľ'), findsOneWidget);
        expect(find.text('Suma (€)'), findsOneWidget);
        expect(find.byType(TextFormField), findsWidgets);
        expectNoLayoutOverflow(tester);
      }
    },
    skip: PlayReleaseScope.playMvp,
  );
}
