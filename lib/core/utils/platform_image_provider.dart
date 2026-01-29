import 'package:flutter/material.dart';

import 'platform_image_provider_stub.dart'
    if (dart.library.io) 'platform_image_provider_mobile.dart'
    if (dart.library.html) 'platform_image_provider_web.dart';

ImageProvider getPlatformImage(String path) {
  return getPlatformSpecificImage(path);
}
