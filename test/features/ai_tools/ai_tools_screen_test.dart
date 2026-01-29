import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/features/ai_tools/screens/ai_tools_screen.dart';
import 'package:bizagent/core/services/ocr_service.dart';
import 'package:image_picker/image_picker.dart';

// Mock OcrService
class MockOcrService extends OcrService {
  @override
  Future<ParsedReceipt?> scanReceipt(ImageSource source) async {
    return ParsedReceipt(
      totalAmount: '15.50',
      date: '20.03.2024',
      vendorId: '12345678',
      originalText: 'Mock Receipt Text',
    );
  }
}

void main() {
  testWidgets('AiToolsScreen displays parsed receipt data',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ocrServiceProvider.overrideWithValue(MockOcrService()),
        ],
        child: const MaterialApp(
          home: AiToolsScreen(),
        ),
      ),
    );

    // Initial frame (avoid pumpAndSettle due to animations)
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    // Verify initial state
    expect(find.text('Skener Bločkov'), findsOneWidget);
    expect(find.text('Kamera'), findsOneWidget);

    // Simulate functionality (Since we can't easily click camera in test without mocking ImagePicker platform,
    // we might need to rely on the service override or structure the code for easier testing.
    // However, pressing the button triggers _scan which calls our mock service.)

    // Ensure the button is on-screen (test surface is small).
    await tester.ensureVisible(find.text('Kamera'));

    // Tap generic "Kamera" button
    await tester.tap(find.text('Kamera'));
    await tester.pump(); // Start scanning
    await tester.pump(const Duration(seconds: 1));

    // Verify fields are populated (values are in TextEditingControllers)
    expect(find.text('15.50'), findsWidgets);
    expect(find.text('20.03.2024'), findsWidgets);
    expect(find.text('12345678'), findsWidgets);

    // Verify "Show Full Text" contains original text
    expect(find.text('Zobraziť celý text'), findsOneWidget);
  });
}
