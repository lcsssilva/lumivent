import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../core/i18n/app_strings.dart';
import '../core/i18n/ui_language.dart';

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

class _BootstrapFailureAppState extends State<BootstrapFailureApp> {
  String? _openError;

  @override
  void initState() {
    super.initState();
    final reveal = widget.revealWindow;
    if (reveal != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_reveal(reveal)),
      );
    }
  }

  Future<void> _reveal(Future<void> Function() reveal) async {
    try {
      await reveal();
    } on Object catch (error, stack) {
      stderr.writeln('Lumivent could not show the failure window: $error');
      stderr.writeln(stack);
    }
  }

  Future<void> _openConfigFolder() async {
    String? error;
    try {
      await Process.start('xdg-open', [
        widget.configDir.path,
      ], mode: ProcessStartMode.detached);
    } on Object catch (failure) {
      error = '$failure';
    }
    if (!mounted) return;
    setState(() => _openError = error);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings.shell;
    return MaterialApp(
      locale: widget.strings.locale,
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) => Text(
                      s.startupFailedTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(s.startupFailedHint),
                  const SizedBox(height: 12),
                  SelectableText('${widget.error}'),
                  const SizedBox(height: 16),
                  Text(s.configurationAt(widget.configDir.path)),
                  if (_openError case final error?) ...[
                    const SizedBox(height: 8),
                    SelectableText(s.openFolderFailed(error)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _openConfigFolder,
                    child: Text(s.openConfigurationFolder),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
