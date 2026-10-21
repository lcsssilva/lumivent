// Lumivent: lighting, fan control, and monitoring for Linux.
//
//   lumivent [--minimized]
//
// --minimized: start minimized to the system tray (used by autostart).
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app/bootstrap.dart';
import 'app/bootstrap_failure.dart';
import 'core/persistence/config_store.dart';

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

  try {
    await bootstrap(args);
  } on Object catch (error, stack) {
    stderr.writeln('Lumivent startup failed: $error');
    stderr.writeln(stack);
    runApp(BootstrapFailureApp(error: error, configDir: defaultConfigDir()));
  }
}
