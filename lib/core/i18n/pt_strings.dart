import 'catalogs/common_strings.dart';
import 'catalogs/common_strings_pt.dart';
import 'catalogs/devices_strings.dart';
import 'catalogs/devices_strings_pt.dart';
import 'catalogs/explore_strings.dart';
import 'catalogs/explore_strings_pt.dart';
import 'catalogs/fans_strings.dart';
import 'catalogs/fans_strings_pt.dart';
import 'catalogs/lighting_strings.dart';
import 'catalogs/lighting_strings_pt.dart';
import 'catalogs/monitoring_strings.dart';
import 'catalogs/monitoring_strings_pt.dart';
import 'catalogs/settings_strings.dart';
import 'catalogs/settings_strings_pt.dart';
import 'catalogs/shell_strings.dart';
import 'catalogs/shell_strings_pt.dart';
import 'catalogs/system_strings.dart';
import 'catalogs/system_strings_pt.dart';
import 'ui_language.dart';
import 'app_strings.dart';

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
