// Lumivent: lighting, fan control, and monitoring for Linux.
//
//   lumivent [--minimized]
//
// --minimized: start minimized to the system tray (used by autostart).
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app/bootstrap.dart';
import 'app/bootstrap_failure_app.dart';
import 'core/persistence/config_store.dart';
import 'features/lighting/infrastructure/html_effects/runtime.dart'
    show runHtmlEffectWorker;

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    stderr.writeln('Lumivent Flutter error: ${details.exceptionAsString()}');
    stderr.writeln(details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    stderr.writeln('Lumivent uncaught error: $error');
    stderr.writeln(stack);
    return true;
  };

  if (args.contains('--html-effect-worker')) {
    try {
      await runHtmlEffectWorker();
    } on Object catch (error, stack) {
      stderr.writeln('Lumivent effect worker failed: $error');
      stderr.writeln(stack);
      exitCode = 1;
    }
    exit(exitCode);
  }

  try {
    await bootstrap(args);
  } on Object catch (error, stack) {
    stderr.writeln('Lumivent startup failed: $error');
    stderr.writeln(stack);
    runApp(
      BootstrapFailureApp(
        error: error,
        configDir: defaultConfigDir(),
        strings: startupFailureStrings(PlatformDispatcher.instance.locale),
      ),
    );
  }
}
