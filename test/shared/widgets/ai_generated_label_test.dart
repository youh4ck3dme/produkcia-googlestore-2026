import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/shared/widgets/ai_generated_label.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('AiGeneratedLabel shows Vygenerované AI', (tester) async {
    await tester.pumpWidget(
      testApp(child: const Scaffold(body: AiGeneratedLabel())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vygenerované AI'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
  });
}