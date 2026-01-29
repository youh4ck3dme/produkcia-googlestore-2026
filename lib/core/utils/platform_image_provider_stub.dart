import 'package:flutter/material.dart';

ImageProvider getPlatformSpecificImage(String path) {
  throw UnsupportedError(
      'Cannot create an image provider without dart:html or dart:io');
}
