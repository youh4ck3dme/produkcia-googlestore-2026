import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/core/utils/csv.dart';

void main() {
  test('CSV escapes commas and quotes', () {
    final out = Csv.encode([
      ['a', 'b,c', 'he said "yo"'],
    ]);

    expect(out.trim(), 'a,"b,c","he said ""yo"""');
  });
}
