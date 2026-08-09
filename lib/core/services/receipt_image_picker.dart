import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

bool _androidPhotoPickerConfigured = false;

/// Enables the system Photo Picker on Android (no READ_MEDIA_* / storage permissions).
void configureAndroidPhotoPicker() {
  if (_androidPhotoPickerConfigured || kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.android) return;

  final platform = ImagePickerPlatform.instance;
  if (platform is ImagePickerAndroid) {
    platform.useAndroidPhotoPicker = true;
    _androidPhotoPickerConfigured = true;
  }
}

/// Picks receipt images via camera or Android/iOS system pickers (no broad storage access).
class ReceiptImagePicker {
  ReceiptImagePicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<XFile?> pick(ImageSource source) {
    configureAndroidPhotoPicker();
    return _picker.pickImage(
      source: source,
      // Avoid extra photo-library permission prompts on Android/iOS.
      requestFullMetadata: false,
    );
  }
}