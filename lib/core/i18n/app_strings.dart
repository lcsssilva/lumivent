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

/// Typed, compile-time-checked UI catalog.
///
/// Widgets read it through `context.strings`; providers and isolates receive it
/// as a parameter. `core/` must not depend on `features/`, so [UiLanguage] lives
/// here and `bootstrap.dart` maps the saved preference to it.
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

class EnStrings extends AppStrings {
  const EnStrings();

  @override
  UiLanguage get language => UiLanguage.en;
  @override
  CommonStrings get common => const CommonStringsEn();
  @override
  ShellStrings get shell => const ShellStringsEn();
  @override
  SettingsStrings get settings => const SettingsStringsEn();
  @override
  DevicesStrings get devices => const DevicesStringsEn();
  @override
  MonitoringStrings get monitoring => const MonitoringStringsEn();
  @override
  LightingStrings get lighting => const LightingStringsEn();
  @override
  FansStrings get fans => const FansStringsEn();
  @override
  ExploreStrings get explore => const ExploreStringsEn();
  @override
  SystemStrings get system => const SystemStringsEn();
  @override
  String get decimalSeparator => '.';
  @override
  String get groupingSeparator => ',';
}

class PtStrings extends AppStrings {
  const PtStrings();

  @override
  UiLanguage get language => UiLanguage.pt;
  @override
  CommonStrings get common => const CommonStringsPt();
  @override
  ShellStrings get shell => const ShellStringsPt();
  @override
  SettingsStrings get settings => const SettingsStringsPt();
  @override
  DevicesStrings get devices => const DevicesStringsPt();
  @override
  MonitoringStrings get monitoring => const MonitoringStringsPt();
  @override
  LightingStrings get lighting => const LightingStringsPt();
  @override
  FansStrings get fans => const FansStringsPt();
  @override
  ExploreStrings get explore => const ExploreStringsPt();
  @override
  SystemStrings get system => const SystemStringsPt();
  @override
  String get decimalSeparator => ',';
  @override
  String get groupingSeparator => '.';
}
