import 'catalogs/common_strings.dart';
import 'catalogs/common_strings_en.dart';
import 'catalogs/devices_strings.dart';
import 'catalogs/devices_strings_en.dart';
import 'catalogs/explore_strings.dart';
import 'catalogs/explore_strings_en.dart';
import 'catalogs/fans_strings.dart';
import 'catalogs/fans_strings_en.dart';
import 'catalogs/lighting_strings.dart';
import 'catalogs/lighting_strings_en.dart';
import 'catalogs/monitoring_strings.dart';
import 'catalogs/monitoring_strings_en.dart';
import 'catalogs/settings_strings.dart';
import 'catalogs/settings_strings_en.dart';
import 'catalogs/shell_strings.dart';
import 'catalogs/shell_strings_en.dart';
import 'catalogs/system_strings.dart';
import 'catalogs/system_strings_en.dart';
import 'ui_language.dart';
import 'app_strings.dart';

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
