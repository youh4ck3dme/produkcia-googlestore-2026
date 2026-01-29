// lib/core/i18n/l10n.dart
import 'package:flutter/widgets.dart';
import 'app_strings.dart';

enum AppLocale { sk /*, en */ }

class L10n extends InheritedWidget {
  const L10n({
    super.key,
    required this.locale,
    required super.child,
  });

  final AppLocale locale;

  static L10n of(BuildContext context) {
    final L10n? result = context.dependOnInheritedWidgetOfExactType<L10n>();
    assert(result != null, 'L10n not found. Wrap app with L10n.');
    return result!;
  }

  String t(AppStr key) {
    switch (locale) {
      case AppLocale.sk:
        return AppStringsSK.values[key] ?? key.name;
    }
  }

  @override
  bool updateShouldNotify(L10n oldWidget) => oldWidget.locale != locale;
}

extension L10nX on BuildContext {
  String t(AppStr key) => L10n.of(this).t(key);
}
