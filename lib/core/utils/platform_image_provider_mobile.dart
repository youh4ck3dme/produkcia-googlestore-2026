import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';

ImageProvider getPlatformSpecificImage(String path) {
  if (path.startsWith('http')) {
    return NetworkImage(path);
  }
  return FileImage(File(path));
}
