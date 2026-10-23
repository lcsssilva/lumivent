// Preferences module domain (pure Dart): general app preferences.
//
// The model is a plain value object: reading tolerance and the JSON shape live
// in `infrastructure/preferences_codec.dart`.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'preferences.freezed.dart';

enum TemperatureUnit { celsius, fahrenheit }

/// Interface language. English is the default (new installs and old configs).
enum AppLanguage { en, pt }

@freezed
abstract class Preferences with _$Preferences {
  const factory Preferences({
    /// Closing the window only hides it; the app remains in the system tray.
    @Default(true) bool closeToTray,
    @Default(TemperatureUnit.celsius) TemperatureUnit temperatureUnit,

    /// Frames per second for the LED loop (the AL V2 is limited to ~15).
    @Default(30) int effectsFps,

    /// UI language; missing or unknown values fall back to English.
    @Default(AppLanguage.en) AppLanguage language,
  }) = _Preferences;

  static const fpsOptions = [15, 30, 60];
}
