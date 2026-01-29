import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/features/ai_tools/screens/ai_email_generator_screen.dart';
import 'package:bizagent/features/ai_tools/providers/ai_email_service.dart';

class MockAiEmailService implements AiEmailService {
  @override
  Future<String> generateEmail({
    required String type,
    required String tone,
    required String context,
  }) async {
    if (context.isEmpty) {
      return 'Prosím, zadajte kontext pre vygenerovanie e-mailu.';
    }
    return 'Vážený klient, posielame Vám faktúru...';
  }
}

void main() {
  testWidgets('AiEmailGeneratorScreen generates text on button press',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiEmailServiceProvider.overrideWithValue(MockAiEmailService()),
        ],
        child: const MaterialApp(
          home: AiEmailGeneratorScreen(),
        ),
      ),
    );

    // Verify initial state
    expect(find.text('AI Generátor E-mailov'), findsOneWidget);
    expect(find.text('Generovať E-mail'), findsOneWidget);

    // Enter context
    await tester.enterText(find.byType(TextField), 'Faktúra 123 po splatnosti');

    // Tap generate
    await tester.tap(find.text('Generovať E-mail'));
    await tester.pump(); // Start loading

    // Fast forward mock delay (2 seconds)
    await tester.pump(const Duration(seconds: 2));

    // Verify result appears
    expect(find.textContaining('Vážený klient'), findsOneWidget);
    expect(find.text('Výsledok:'), findsOneWidget);
  });

  testWidgets('AiEmailGeneratorScreen validates empty context',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiEmailServiceProvider.overrideWithValue(MockAiEmailService()),
        ],
        child: const MaterialApp(
          home: AiEmailGeneratorScreen(),
        ),
      ),
    );

    // Tap generate without entering text
    await tester.tap(find.text('Generovať E-mail'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    // Verify error message from service
    expect(find.text('Prosím, zadajte kontext pre vygenerovanie e-mailu.'),
        findsOneWidget);
  });
}
