import 'package:bizagent/features/invoices/widgets/pay_by_square_qr_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../helpers/test_app.dart';

void main() {
  group('PayBySquareQrCard', () {
    testWidgets('renders QR code and payment details', (tester) async {
      await tester.pumpWidget(
        testApp(
          child: Scaffold(
            body: PayBySquareQrCard(
              iban: 'SK1211000000001234567890',
              swift: 'TATRSKBX',
              amountEur: 123.45,
              variableSymbol: '2026001',
              recipientName: 'Test Company s.r.o.',
              dateDue: DateTime(2026, 12, 31),
              note: 'Faktúra FA-2026-001',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('QR platba'), findsOneWidget);
      expect(find.textContaining('Naskenujte v bankovej appke'), findsOneWidget);
      expect(
        find.textContaining('SK1211000000001234567890'),
        findsOneWidget,
      );
      expect(find.textContaining('VS: 2026001'), findsOneWidget);
      expect(find.textContaining('123'), findsWidgets);
      expect(find.text('Skopírovať IBAN'), findsOneWidget);
      expect(find.text('Skopírovať VS'), findsOneWidget);
      expect(find.text('Skopírovať sumu'), findsOneWidget);
    });

    testWidgets('hides VS copy chip when variable symbol is empty',
        (tester) async {
      await tester.pumpWidget(
        testApp(
          child: Scaffold(
            body: PayBySquareQrCard(
              iban: 'SK1211000000001234567890',
              swift: 'TATRSKBX',
              amountEur: 50,
              variableSymbol: '',
              recipientName: 'Test Company',
              dateDue: DateTime(2026, 6, 15),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Skopírovať VS'), findsNothing);
    });
  });
}