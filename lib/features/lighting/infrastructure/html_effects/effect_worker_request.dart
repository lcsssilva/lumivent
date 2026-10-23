import '../../domain/light_device.dart';
import 'effect_worker_protocol.dart';

/// A request parsed from an envelope. `op` stays a String here: the connection
/// only validates the envelope, and unknown ops are answered by the worker
/// with an error reply (`unknown worker operation`) instead of a timeout.
final class EffectWorkerRequest {
  EffectWorkerRequest._(this.id, this.op, this.arguments);

  /// Parses [message] as a request envelope; `null` when it is not valid, so
  /// the caller drops it without crashing the worker.
  static EffectWorkerRequest? tryParse(Object? message) {
    if (message is! List || message.length < 2) return null;
    final id = message[0];
    final op = message[1];
    if (id is! int || id < 0 || op is! String) return null;
    return EffectWorkerRequest._(id, op, message.sublist(2));
  }

  /// `id == 0` means fire-and-forget: no reply is expected.
  final int id;
  final String op;
  final List<Object?> arguments;

  /// The op as a typed value; `null` when the name is not one the protocol
  /// defines (the workers answer it as an explicit error).
  EffectWorkerOperation? get operation {
    for (final candidate in EffectWorkerOperation.values) {
      if (candidate.name == op) return candidate;
    }
    return null;
  }

  /// Answers [EffectWorkerRequest]. The id of an error reply matches the
  /// request, and the payload keeps the stack under the message.
  List<Object?> ok([Object? payload]) => [id, true, payload];

  List<Object?> error(Object error, StackTrace stack) => [
    id,
    false,
    ['$error', '$stack'],
  ];

  /// Arguments per op (validated again by each handling):
  ///
  /// * `load`: html, shim script, property values.
  /// * `frame`: time in milliseconds, whether the pixels are wanted (absent
  ///   equals true).
  /// * `property`: name, value (absent equals null).
  /// * `sensors`: the values.
  /// * `points`: encoded sample points, or null to clear them.
  String html() => arguments[0] as String;
  String shim() => arguments[1] as String;
  Map<String, Object?> values() =>
      (arguments[2] as Map).cast<String, Object?>();
  double frameTime() => (arguments[0] as num).toDouble();
  bool framePixels() => arguments.length < 2 || arguments[1] != false;
  String propertyName() => arguments[0] as String;
  Object? propertyValue() => arguments.length > 1 ? arguments[1] : null;
  Map<String, double> sensorValues() =>
      (arguments[0] as Map).cast<String, double>();
  List<(LightDeviceId, int, int)>? get samplePoints =>
      arguments.isEmpty || arguments[0] == null
      ? null
      : decodeSamplePoints(arguments[0]);
}
