import 'package:flutter/material.dart';

ImageProvider getPlatformSpecificImage(String path) {
  // On web, everything is a network image (even local blobs)
  return NetworkImage(path);
}
