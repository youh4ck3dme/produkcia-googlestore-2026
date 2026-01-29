import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app_router.dart contains expected paths for bank-import and export',
      () {
    final file = File('lib/core/router/app_router.dart');
    expect(file.existsSync(), isTrue);

    final content = file.readAsStringSync();

    expect(content.contains("path: '/bank-import'"), isTrue,
        reason: 'Missing /bank-import route in app_router.dart');
    expect(content.contains("path: '/export'"), isTrue,
        reason: 'Missing /export route in app_router.dart');
  });
}
