import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_strings.dart';
import 'ui_language.dart';

/// Active UI language. `bootstrap.dart` overrides it with the saved preference;
/// standalone containers default to English, matching a fresh install.
final uiLanguageProvider = Provider<UiLanguage>((ref) => UiLanguage.en);

/// Catalog for the active language. Widgets normally use `context.strings`;
/// providers and application code use `ref.watch(stringsProvider)`.
final stringsProvider = Provider<AppStrings>(
  (ref) => AppStrings.of(ref.watch(uiLanguageProvider)),
);
