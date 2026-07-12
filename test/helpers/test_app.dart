import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bizagent/core/i18n/l10n.dart';

Widget testApp({
  required Widget child,
  Iterable extraOverrides = const [],
}) {
  return ProviderScope(
    overrides: [...extraOverrides],
    child: MaterialApp(
      home: L10n(locale: AppLocale.sk, child: child),
    ),
  );
}
