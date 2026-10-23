import 'dart:ui' show Locale;

import 'catalogs/common_strings.dart';
import 'catalogs/devices_strings.dart';
import 'catalogs/explore_strings.dart';
import 'catalogs/fans_strings.dart';
import 'catalogs/lighting_strings.dart';
import 'catalogs/monitoring_strings.dart';
import 'catalogs/settings_strings.dart';
import 'catalogs/shell_strings.dart';
import 'catalogs/system_strings.dart';
import 'ui_language.dart';
import 'en_strings.dart';
import 'pt_strings.dart';

/// Typed, compile-time-checked UI catalog.
///
/// Widgets read it through `context.strings`; providers and isolates receive it
/// as a parameter. `core/` must not depend on `features/`, so [UiLanguage] lives
/// here and `lib/app/ui_language_binding.dart` maps the saved preference to it.
abstract class AppStrings {
  const AppStrings();

  UiLanguage get language;

  CommonStrings get common;
  ShellStrings get shell;
  SettingsStrings get settings;
  DevicesStrings get devices;
  MonitoringStrings get monitoring;
  LightingStrings get lighting;
  FansStrings get fans;
  ExploreStrings get explore;
  SystemStrings get system;

  Locale get locale => language.locale;
  String get localeName => language.localeName;

  static const supportedLocales = [Locale('en', 'US'), Locale('pt', 'BR')];

  /// Decimal separator used by every formatted number.
  String get decimalSeparator;

  /// Thousands separator used by every grouped integer.
  String get groupingSeparator;

  String decimal(double value, int digits) =>
      value.toStringAsFixed(digits).replaceAll('.', decimalSeparator);

  /// Integer with the language's thousands separator: 1820 → "1,820" / "1.820".
  String grouped(int value) {
    final digits = value.abs().toString();
    final out = StringBuffer(value < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(groupingSeparator);
      out.write(digits[i]);
    }
    return out.toString();
  }

  static const AppStrings en = EnStrings();
  static const AppStrings pt = PtStrings();

  static AppStrings of(UiLanguage language) => switch (language) {
    UiLanguage.en => en,
    UiLanguage.pt => pt,
  };
}
