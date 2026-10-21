import 'package:flutter/widgets.dart';

import 'app_strings.dart';

/// Makes the active catalog available to the widget tree.
///
/// In the app it sits above `MaterialApp`, so pages, dialogs, and routes all
/// inherit it.
class AppStringsScope extends InheritedWidget {
  const AppStringsScope({
    super.key,
    required this.strings,
    required super.child,
  });

  final AppStrings strings;

  static AppStrings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStringsScope>();
    // Outside the app shell (standalone widget tests, previews) there is no
    // scope: use the default language, like a fresh install.
    return scope?.strings ?? AppStrings.en;
  }

  @override
  bool updateShouldNotify(AppStringsScope oldWidget) =>
      oldWidget.strings != strings;
}

extension AppStringsContext on BuildContext {
  AppStrings get strings => AppStringsScope.of(this);
}
