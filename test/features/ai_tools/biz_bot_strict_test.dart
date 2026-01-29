import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizagent/features/ai_tools/screens/biz_bot_screen.dart';
import 'package:bizagent/features/ai_tools/services/biz_bot_service.dart';
import 'package:mockito/mockito.dart';
import 'package:intl/date_symbol_data_local.dart';

// Generate Mocks (Manual implementation for simplicity in one file)
class MockBizBotService extends Mock implements BizBotService {
  @override
  Future<String> ask(String prompt) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 50));
    
    if (prompt.contains('chyba')) {
      throw Exception('Simulated Network Error');
    }
    return 'Toto je testovacia odpoveď na: $prompt';
  }
}

void main() {
  setUpAll(() async {
    // FIX: Initialize locale data for tests
    await initializeDateFormatting('sk', null);
  });

  Widget createWidgetUnderTest(MockBizBotService mockService) {
    return ProviderScope(
      overrides: [
        bizBotServiceProvider.overrideWithValue(mockService),
      ],
      child: const MaterialApp(
        home: BizBotScreen(),
      ),
    );
  }

  testWidgets('BizBot Strict UI Test: Initial State', (WidgetTester tester) async {
    final mockService = MockBizBotService();
    await tester.pumpWidget(createWidgetUnderTest(mockService));
    await tester.pumpAndSettle();

    // 1. Verify Title
    expect(find.text('BizBot'), findsOneWidget);
    expect(find.text('AI Asistent'), findsOneWidget);

    // 2. Verify Welcome Message
    expect(find.textContaining('Ahoj! Som tvoj BizAgent asistent'), findsOneWidget);

    // 3. Verify Input Field and Send Button exist
    expect(find.byKey(const Key('bizbot_input')), findsOneWidget);
    expect(find.byKey(const Key('bizbot_send_btn')), findsOneWidget);
  });

  testWidgets('BizBot Strict Flow: Send Message & Receive Reply', (WidgetTester tester) async {
    final mockService = MockBizBotService();
    await tester.pumpWidget(createWidgetUnderTest(mockService));
    await tester.pumpAndSettle();

    // 1. Enter Text
    await tester.enterText(find.byKey(const Key('bizbot_input')), 'Ako sa máš?');
    await tester.pump();

    // 2. Tap Send
    await tester.tap(find.byKey(const Key('bizbot_send_btn')));
    await tester.pump(); // Start animation/loading

    // 3. Verify User Message Appears
    expect(find.text('Ako sa máš?'), findsOneWidget);

    // 4. Verify Loading Indicator Logic (Wait for Mock Delay)
    // Note: Due to pumpAndSettle, we jump to end state
    await tester.pumpAndSettle();

    // 5. Verify Bot Response
    expect(find.textContaining('Toto je testovacia odpoveď na: Ako sa máš?'), findsOneWidget);
  });

  testWidgets('BizBot Strict Flow: Error Handling', (WidgetTester tester) async {
     final mockService = MockBizBotService();
    await tester.pumpWidget(createWidgetUnderTest(mockService));
    await tester.pumpAndSettle();

    // 1. Trigger Error
    await tester.enterText(find.byKey(const Key('bizbot_input')), 'chyba');
    await tester.tap(find.byKey(const Key('bizbot_send_btn')));
    await tester.pumpAndSettle();

    // 2. Verify Error Message Displayed
    expect(find.textContaining('Sieťová chyba'), findsOneWidget);
  });
}
