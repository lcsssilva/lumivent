import 'package:flutter_riverpod/flutter_riverpod.dart';

/// UI-facing desktop integration (window + system tray).
abstract interface class DesktopActions {
  /// Does a system tray exist? Without it, closing the window must exit the app.
  bool get trayAvailable;
  Future<void> quit();
}

final desktopActionsProvider = Provider<DesktopActions>(
  (ref) => throw UnimplementedError('desktopActionsProvider'),
);
