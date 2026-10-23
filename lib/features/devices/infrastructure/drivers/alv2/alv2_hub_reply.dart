import 'alv2_hub_command.dart';

class Alv2HubReply {
  const Alv2HubReply(this.id, {this.ok = false, this.rpm});

  /// Reply for a command that could not reach the worker.
  const Alv2HubReply.failed(this.id) : ok = false, rpm = null;

  final int id;
  final bool ok;

  /// Set on [HubReadRpm] replies.
  final List<int>? rpm;
}
