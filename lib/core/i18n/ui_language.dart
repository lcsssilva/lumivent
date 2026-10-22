// Languages the interface is available in.
//
// `core/i18n` must not depend on `features/` (architecture rule 1), so the
// domain preference (`AppLanguage`) is mapped in `lib/app/ui_language_binding.dart`.
import 'dart:ui' show Locale;

enum UiLanguage {
  en,
  pt;

  Locale get locale => switch (this) {
    UiLanguage.en => const Locale('en', 'US'),
    UiLanguage.pt => const Locale('pt', 'BR'),
  };

  /// ICU-style name used by `flutter_localizations` (`en_US`, `pt_BR`).
  String get localeName => switch (this) {
    UiLanguage.en => 'en_US',
    UiLanguage.pt => 'pt_BR',
  };
}
