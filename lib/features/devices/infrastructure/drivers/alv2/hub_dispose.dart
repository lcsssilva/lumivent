part of 'alv2_hub_command.dart';

/// Closes the hub inside the worker; everything sent before it has already
/// reached the device (or been dropped by the hub rules).
class HubDispose extends Alv2HubCommand {
  const HubDispose();
}
