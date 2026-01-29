import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('No plain empty texts remain (must use BizEmptyState)', () {
    final inv = File('lib/features/invoices/screens/invoices_screen.dart')
        .readAsStringSync();
    final exp = File('lib/features/expenses/screens/expenses_screen.dart')
        .readAsStringSync();

    // Ensure BizEmptyState is used, not plain Center(Text(...))
    expect(inv.contains('BizEmptyState'), isTrue,
        reason: 'Invoices screen must use BizEmptyState for empty state');
    expect(exp.contains('BizEmptyState'), isTrue,
        reason: 'Expenses screen must use BizEmptyState for empty state');

    // Ensure old plain text patterns are gone
    expect(inv.contains("Center(child: Text('Žiadne faktúry'))"), isFalse,
        reason: 'Invoices empty state reverted to plain text');
    expect(exp.contains("Center(child: Text('Žiadne výdavky'))"), isFalse,
        reason: 'Expenses empty state reverted to plain text');
  });

  test('BizEmptyState widget exists and is properly defined', () {
    final widget = File('lib/shared/widgets/biz_empty_state.dart');
    expect(widget.existsSync(), isTrue,
        reason: 'BizEmptyState widget file must exist');

    final content = widget.readAsStringSync();
    expect(content.contains('class BizEmptyState'), isTrue);
    expect(content.contains('final String title'), isTrue);
    expect(content.contains('final String body'), isTrue);
    expect(content.contains('final String? ctaLabel'), isTrue);
    expect(content.contains('final VoidCallback? onCta'), isTrue);
  });
}
