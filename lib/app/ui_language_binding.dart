import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../core/i18n/strings_provider.dart';
import '../core/i18n/ui_language.dart';
import '../features/preferences/preferences.dart';

/// Maps the saved preference to the core language (core does not know
/// features, so the enum is duplicated on purpose).
UiLanguage uiLanguageOf(AppLanguage language) => switch (language) {
  AppLanguage.en => UiLanguage.en,
  AppLanguage.pt => UiLanguage.pt,
};

/// The interface language follows the saved preference and rebuilds the
/// catalog immediately when it changes (no restart).
Override uiLanguageFromPreferences() => uiLanguageProvider.overrideWith(
  (ref) =>
      uiLanguageOf(ref.watch(preferencesProvider.select((p) => p.language))),
);
