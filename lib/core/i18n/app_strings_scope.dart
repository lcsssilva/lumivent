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
    // Standalone widget tests and previews may build a page without the app
    // shell. They keep the historical Portuguese text unless they wrap the
    // tree with an explicit scope.
    return scope?.strings ?? AppStrings.pt;
  }

  @override
  bool updateShouldNotify(AppStringsScope oldWidget) =>
      oldWidget.strings != strings;
}

extension AppStringsContext on BuildContext {
  AppStrings get strings => AppStringsScope.of(this);
}
