import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizagent/features/ai_tools/screens/biz_bot_screen.dart';
import 'package:bizagent/features/ai_tools/services/biz_bot_service.dart';
import 'package:bizagent/features/ai_tools/providers/bizbot_history_provider.dart';
import 'package:bizagent/features/auth/models/user_model.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/billing/billing_service.dart';
import 'package:bizagent/features/entitlements/user_entitlements.dart';
import 'package:bizagent/features/limits/usage_limiter.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late UsageLimiter testLimiter;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    testLimiter = UsageLimiter(prefs);
    await initializeDateFormatting('sk', null);
  });

  Widget createWidgetUnderTest(MockBizBotService mockService) {
    final fakeFs = FakeFirebaseFirestore();
    const fakeUser = UserModel(
      id: 'test-uid',
      email: 'test@example.com',
      displayName: 'Test User',
      isAnonymous: false,
    );

    return ProviderScope(
      overrides: [
        bizBotServiceProvider.overrideWithValue(mockService),
        authStateProvider.overrideWith((ref) => Stream.value(fakeUser)),
        bizBotHistoryRepositoryProvider.overrideWithValue(BizBotHistoryRepository(fakeFs)),
        billingProvider.overrideWith(
          (ref) => BillingService.forTest(
            BillingState(entitlements: UserEntitlements(isPro: true)),
            testLimiter,
          ),
        ),
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

    // Wait for FakeFirestore write + mock delay + UI rebuilds.
    await tester.pumpAndSettle();

    // Verify User Message + Bot Response
    expect(find.text('Ako sa máš?'), findsOneWidget);
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
