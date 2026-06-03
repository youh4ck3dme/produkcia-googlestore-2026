import 'dart:convert';
import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bizagent/core/services/ai_ocr_service.dart';
import 'package:bizagent/core/services/analytics_service.dart';
import 'package:bizagent/core/services/expense_parser_service.dart';
import 'package:bizagent/core/services/gemini_service.dart';
import 'package:bizagent/core/services/local_persistence_service.dart';
import 'package:bizagent/core/services/ocr_service.dart';
import 'package:bizagent/features/auth/models/user_model.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/expenses/providers/expenses_repository.dart';
import 'package:bizagent/features/expenses/screens/create_expense_screen.dart';
import 'package:bizagent/features/expenses/services/categorization_service.dart';
import 'package:bizagent/features/expenses/services/receipt_storage_service.dart';

import '../../helpers/test_app.dart';

const _testUser = UserModel(
  id: 'test-user-ocr',
  email: 'ocr@test.example.com',
);

class FakeLocalPersistenceService extends LocalPersistenceService {
  @override
  List<Map<String, dynamic>> getExpenses() => [];

  @override
  Future<void> saveExpense(String id, Map<String, dynamic> data) async {}

  @override
  Future<void> deleteExpense(String id) async {}
}

class MockFirebaseAnalytics extends Fake implements FirebaseAnalytics {
  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
    AnalyticsCallOptions? callOptions,
  }) async {}

  @override
  Future<void> logAppOpen({
    Map<String, Object?>? parameters,
    AnalyticsCallOptions? callOptions,
  }) async {}
}

/// Stable OCR scan result before AI refinement.
class MockOcrService extends OcrService {
  MockOcrService(this.receiptPath);

  final String receiptPath;

  @override
  Future<ParsedReceipt?> scanReceipt(ImageSource source) async {
    return ParsedReceipt(
      totalAmount: '15.50',
      date: '20.03.2024',
      vendorId: '12345678',
      originalText: 'TESCO BLOČEK\nCelkom: 15.50 EUR\nIČO: 12345678',
      imagePath: receiptPath,
    );
  }

  @override
  Future<ParsedReceipt?> scanReceiptFromPath(String path) async {
    return scanReceipt(ImageSource.gallery);
  }
}

class FakeFirebaseStorage extends Fake implements FirebaseStorage {}

class FakeReceiptStorageService extends ReceiptStorageService {
  FakeReceiptStorageService(super.ref, super.storage);

  @override
  Future<String?> uploadReceipt(String filePath) async {
    return 'https://example.com/receipt.jpg';
  }
}

/// AI refinement returns stable parsed receipt fields.
class MockAiOcrService extends AiOcrService {
  MockAiOcrService() : super(_StubGeminiService());

  @override
  Future<ParsedReceipt?> refineWithAi(String rawText, {String? imagePath}) async {
    return ParsedReceipt(
      totalAmount: '42.99',
      date: '2024-03-15',
      vendorId: '36396567',
      originalText: rawText,
      imagePath: imagePath,
    );
  }
}

class _StubGeminiService extends GeminiService {
  @override
  Future<String> analyzeJson(String context, String schema) async => '{}';
}

class MockGeminiForOcrPipeline extends GeminiService {
  @override
  Future<String> analyzeJson(String context, String schema) async {
    return '{"suma": 42.99, "datum": "2024-03-15", "ico": "36396567"}';
  }
}

class MockGeminiForExpenseParser extends GeminiService {
  @override
  Future<String> analyzeJson(String context, String schema) async {
    return jsonEncode({
      'description': 'Nákup v Tescu',
      'amount': 25.0,
      'category': 'Jedlo',
      'date': '2024-03-15',
      'merchant': 'Tesco',
      'confidence': 0.9,
    });
  }
}

void main() {
  group('Create expense OCR flow', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FakeLocalPersistenceService fakePersistence;
    late String receiptPath;
    late Directory tempDir;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      fakePersistence = FakeLocalPersistenceService();
      tempDir = await Directory.systemTemp.createTemp('ocr_flow_test');
      final file = File('${tempDir.path}/receipt.jpg');
      await file.writeAsString('fake receipt image');
      receiptPath = file.path;
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    List<Override> buildOverrides() {
      return [
        authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
        ocrServiceProvider.overrideWithValue(MockOcrService(receiptPath)),
        aiOcrServiceProvider.overrideWithValue(MockAiOcrService()),
        analyticsServiceProvider.overrideWithValue(
          AnalyticsService(MockFirebaseAnalytics()),
        ),
        expensesRepositoryProvider.overrideWithValue(
          ExpensesRepository(fakeFirestore, fakePersistence),
        ),
        categorizationServiceProvider.overrideWithValue(
          CategorizationService(fakeFirestore),
        ),
        firebaseStorageProvider.overrideWithValue(FakeFirebaseStorage()),
        receiptStorageServiceProvider.overrideWith(
          (ref) => FakeReceiptStorageService(ref, ref.read(firebaseStorageProvider)),
        ),
      ];
    }

    testWidgets('scan receipt autofills fields, shows success snackbar, saves expense',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        testApp(
          child: const CreateExpenseScreen(),
          overrides: buildOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Skenovať bloček'), findsOneWidget);

      await tester.tap(find.textContaining('Skenovať bloček'));
      await tester.pump();
      await tester.pumpAndSettle();

      // AI-refined autofilled fields
      expect(find.text('42.99'), findsOneWidget);
      expect(find.text('36396567'), findsOneWidget);
      expect(find.text('15.03.2024'), findsOneWidget);

      // Success snackbar without vendor-specific AI branding
      expect(find.text('Údaje úspešne spracované'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.textContaining('Gemini'),
        ),
        findsNothing,
      );

      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(_testUser.id)
          .collection('expenses')
          .get();

      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.first.data();
      expect(data['vendorName'], '36396567');
      expect(data['amount'], 42.99);
      expect(data['isOcrVerified'], isTrue);

      expect(find.text('Výdavok úspešne pridaný!'), findsOneWidget);
    });
  });

  group('OCR pipeline safety net', () {
    test('AiOcrService.refineWithAi does not crash on valid mock JSON', () async {
      final service = AiOcrService(MockGeminiForOcrPipeline());

      final result = await service.refineWithAi(
        'TESCO\nCelkom: 42.99 EUR\nIČO: 36396567',
      );

      expect(result, isNotNull);
      expect(result!.totalAmount, '42.99');
      expect(result.date, '2024-03-15');
      expect(result.vendorId, '36396567');
    });

    test('ExpenseParserService.parseExpenseText does not crash on valid mock response',
        () async {
      final service = ExpenseParserService(MockGeminiForExpenseParser());

      final result = await service.parseExpenseText('Tesco nákup 25,00 €');

      expect(result, isNotNull);
      expect(result!.amount, 25.0);
      expect(result.description, isNotEmpty);
      expect(service.isValidExpense(result), isTrue);
    });

    test('AiOcrService.refineWithAi returns null instead of throwing on bad JSON',
        () async {
      final service = AiOcrService(_BrokenGeminiService());

      expect(
        () async => service.refineWithAi('invalid receipt'),
        returnsNormally,
      );

      final result = await service.refineWithAi('invalid receipt');
      expect(result, isNull);
    });
  });
}

class _BrokenGeminiService extends GeminiService {
  @override
  Future<String> analyzeJson(String context, String schema) async {
    return 'not-valid-json';
  }
}
