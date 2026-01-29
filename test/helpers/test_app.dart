import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bizagent/core/i18n/l10n.dart';

Widget testApp({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: L10n(locale: AppLocale.sk, child: child),
    ),
  );
}
