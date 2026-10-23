import 'autostart_state.dart';

/// Autostart port for the operating system.
abstract interface class AutostartService {
  /// Where the configuration is stored (shown to the user).
  String get location;
  Future<AutostartState> status();
  Future<void> enable();
  Future<void> disable();
}
