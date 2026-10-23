import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../core/i18n/app_strings.dart';
import '../core/i18n/ui_language.dart';

part 'bootstrap_failure_app_state.dart';

/// Catalog for the failure screen. Startup may have failed before the saved
/// language preference could be read, so the system locale decides.
AppStrings startupFailureStrings(Locale systemLocale) => AppStrings.of(
  systemLocale.languageCode == 'pt' ? UiLanguage.pt : UiLanguage.en,
);

/// Shows and focuses the window. Autostart (`--minimized`) keeps the window
/// hidden and startup cleanup removes the tray icon, so without this the
/// failure screen would never be seen.
Future<void> revealStartupFailureWindow() async {
  await windowManager.ensureInitialized();
  await windowManager.show();
  await windowManager.focus();
}

class BootstrapFailureApp extends StatefulWidget {
  const BootstrapFailureApp({
    required this.error,
    required this.configDir,
    this.strings = AppStrings.en,
    this.revealWindow,
    super.key,
  });

  final Object error;
  final Directory configDir;
  final AppStrings strings;

  /// Called after the first frame so the failure is visible even when the
  /// app was started hidden ([revealStartupFailureWindow] in the app).
  final Future<void> Function()? revealWindow;

  @override
  State<BootstrapFailureApp> createState() => _BootstrapFailureAppState();
}
