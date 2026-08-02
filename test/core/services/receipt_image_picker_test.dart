import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/core/services/receipt_image_picker.dart';

void main() {
  test('configureAndroidPhotoPicker is safe to call on test VM', () {
    expect(() => configureAndroidPhotoPicker(), returnsNormally);
    // Idempotent
    expect(() => configureAndroidPhotoPicker(), returnsNormally);
  });
}