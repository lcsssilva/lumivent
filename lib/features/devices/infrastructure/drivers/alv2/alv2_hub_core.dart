import 'dart:async';
import 'dart:io';

import 'alv2_hub.dart';
import 'alv2_hub_command.dart';
import 'alv2_hub_reply.dart';

/// Runs commands over an [Alv2Hub]. It does **not** serialize them: the hub
/// already owns the queue, the pauses and the priority rules, and the
/// synchronous operations (duty, RPM) deliberately run during an asynchronous
/// frame, as they did when the hub lived in the engine isolate.
class Alv2HubCore {
  Alv2HubCore(this._hub);
  final Alv2Hub _hub;

  /// Starts [command] now and answers when it finishes. Never throws.
  Future<Alv2HubReply> handle(int id, Alv2HubCommand command) async {
    try {
      return switch (command) {
        HubReadRpm() => _rpm(id, _hub.readRpm()),
        HubSetDuty(:final group, :final duty) => _ok(
          id,
          _hub.setDuty(group, duty),
        ),
        HubSetMotherboardSync(:final sync) => _ok(
          id,
          _hub.setMotherboardSync(sync),
        ),
        HubSetQuantity(:final group, :final quantity) => _ok(
          id,
          _hub.setQuantity(group, quantity),
        ),
        HubSetMergeOrder(:final order) => _ok(id, _hub.setMergeOrder(order)),
        HubDisableArgbSync() => _ok(id, _hub.disableArgbSync()),
        HubSendLighting(:final writes, :final frame, :final priority) => _ok(
          id,
          await _hub.sendLighting(writes, frame: frame, priority: priority),
        ),
        HubStreamCanvas(:final writes) => _ok(
          id,
          await _hub.streamCanvas(writes),
        ),
        HubIdentify(:final group, :final merge) => _ok(
          id,
          await _hub.identify(group, merge: merge),
        ),
        HubDispose() => _dispose(id),
      };
    } on Object catch (e) {
      // Safety guards and unexpected driver errors become "unavailable".
      stderr.writeln('alv2 hub: $e');
      return Alv2HubReply.failed(id);
    }
  }

  static Alv2HubReply _ok(int id, bool ok) => Alv2HubReply(id, ok: ok);
  static Alv2HubReply _rpm(int id, List<int>? rpm) =>
      Alv2HubReply(id, ok: rpm != null, rpm: rpm);

  Alv2HubReply _dispose(int id) {
    _hub.dispose();
    return Alv2HubReply(id, ok: true);
  }
}
