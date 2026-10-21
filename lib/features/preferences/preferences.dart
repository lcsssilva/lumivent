/// Preferences module: general preferences (system tray, unit, FPS).
/// Public API: other modules import only this file.
library;

export 'application/preferences_controller.dart'
    show PreferencesController, preferencesProvider;
export 'domain/preferences.dart' show AppLanguage, Preferences, TemperatureUnit;
export 'preferences_module.dart';
export 'presentation/preferences_card.dart' show PreferencesCard;
