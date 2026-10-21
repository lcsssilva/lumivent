import 'package:flutter/widgets.dart';
import 'package:lumivent/core/i18n/app_strings.dart';
import 'package:lumivent/core/i18n/app_strings_scope.dart';

/// Wraps a standalone widget test in the Portuguese catalog.
///
/// Widget tests match the Portuguese interface text (`find.text`); without a
/// scope a widget falls back to the default language (English). Tests that
/// check English wrap the tree with `AppStringsScope(strings: AppStrings.en)`.
Widget withPortuguese(Widget child) =>
    AppStringsScope(strings: AppStrings.pt, child: child);
