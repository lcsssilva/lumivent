// Named, validated shape of the messages exchanged with the HTML effect
// worker. Both transports (isolate SendPort and child-process stdin/stdout)
// carry the same envelopes:
//
//   request [id, op, ...arguments]      parent -> worker
//   reply   [id, ok, payload]           worker -> parent
//
// The request builders below are the only way the parent side produces a
// request, and the worker mains switch on the same op names, so changing
// one side always changes both together.
//
// Every message crosses a boundary the app does not control (a spawned
// process, a message port), so both sides parse through the `tryParse`
// functions and handle malformed data explicitly instead of operating on
// list positions unchecked.

import 'dart:convert';
import 'dart:isolate' show TransferableTypedData;
import 'dart:typed_data';

import '../../domain/light_device.dart';
import '../../domain/rgb.dart';

/// Prefix on every stdout line of a child-process worker, so the app output
/// is never parsed as a worker message.
const effectWorkerMessagePrefix = 'LUMIVENT_HTML_EFFECT:';

/// The ops the worker understands (the second envelope entry).
enum EffectWorkerOperation {
  load,
  points,
  frame,
  property,
  sensors,
  log,
  dispose;

  /// Longest an effect worker request may be when it arrives as a stdin line
  /// (see `runHtmlEffectWorker`): the load request carries the whole effect.
  static const maxLineBytes = 12 * 1024 * 1024;
}

// ── Parent side: request builders ────────────────────────────────────────
// `id` is added by the worker connection; `id == 0` marks fire-and-forget
// requests (properties, sensors): their errors surface on the next frame.

List<Object?> loadRequest(
  String html,
  String shim,
  Map<String, Object?> values,
) => [EffectWorkerOperation.load.name, html, shim, values];

List<Object?> frameRequest(double nowMs) => [
  EffectWorkerOperation.frame.name,
  nowMs,
];

List<Object?> pointsRequest(Object? encodedPoints) => [
  EffectWorkerOperation.points.name,
  encodedPoints,
];

List<Object?> propertyRequest(String name, Object? value) => [
  EffectWorkerOperation.property.name,
  name,
  value,
];

List<Object?> sensorsRequest(Map<String, double> values) => [
  EffectWorkerOperation.sensors.name,
  values,
];

List<Object?> logRequest() => [EffectWorkerOperation.log.name];

List<Object?> disposeRequest() => [EffectWorkerOperation.dispose.name];

// ── Worker side: parsed request ──────────────────────────────────────────

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
  /// * `frame`: time in milliseconds.
  /// * `property`: name, value (absent equals null).
  /// * `sensors`: the values.
  /// * `points`: encoded sample points, or null to clear them.
  String html() => arguments[0] as String;
  String shim() => arguments[1] as String;
  Map<String, Object?> values() =>
      (arguments[2] as Map).cast<String, Object?>();
  double frameTime() => (arguments[0] as num).toDouble();
  String propertyName() => arguments[0] as String;
  Object? propertyValue() => arguments.length > 1 ? arguments[1] : null;
  Map<String, double> sensorValues() =>
      (arguments[0] as Map).cast<String, double>();
  List<(LightDeviceId, int, int)>? get samplePoints =>
      arguments.isEmpty || arguments[0] == null
      ? null
      : decodeSamplePoints(arguments[0]);
}

// ── Replies ──────────────────────────────────────────────────────────────

/// A reply parsed from an envelope. `ok` true means done ([payload] is the
/// result); false means failed ([payload] is the error pair.
final class EffectWorkerReply {
  EffectWorkerReply._(this.id, this.ok, this.payload);

  /// Parses [message] as a reply envelope; `null` when it is not valid, so
  /// the caller drops it instead of failing every pending request.
  static EffectWorkerReply? tryParse(Object? message) {
    if (message is! List || message.length < 3) return null;
    final id = message[0];
    final ok = message[1];
    if (id is! int || ok is! bool) return null;
    return EffectWorkerReply._(id, ok, message[2]);
  }

  final int id;
  final bool ok;
  final Object? payload;

  /// Message of an error payload ('the message first, then the stack').
  String get errorMessage {
    final detail = payload;
    return detail is List && detail.isNotEmpty ? '${detail[0]}' : '$detail';
  }
}

// ── Frame reply payload ──────────────────────────────────────────────────

/// Builds the payload of a frame reply: `[pixelsOrOps, simple, opCount, logs,
/// scriptTimeUs, colors]`. Fast frames transfer the final RGBA pixels
/// ([simple] is true) and the parent only samples them; slow frames transfer
/// the raw canvas ops ([opCount] is -1) for the parent to replay. The
/// [TransferableTypedData] form is for the isolate transport; the child
/// process sends the same shape with the bytes base64 encoded (JSON lines).
List<Object?> frameReply({
  required TypedData pixelsOrOps,
  required bool simple,
  required int opCount,
  required List<String> logs,
  required Duration scriptTime,
  required Object? colors,
}) => [
  TransferableTypedData.fromList([pixelsOrOps]),
  simple,
  opCount,
  logs,
  scriptTime.inMicroseconds,
  colors,
];

/// Payload of a frame reply as encoded by [frameReply] or the process worker
/// (which carries the frame as a base64 String).
({
  Uint8List pixelsOrOps,
  bool simple,
  int opCount,
  List<String> logs,
  Duration scriptTime,
  Map<LightDeviceId, List<Rgb>>? colors,
})
parseFrameReply(List payload) {
  final data = switch (payload.length >= 6 ? payload[0] : null) {
    TransferableTypedData typedData => typedData.materialize().asUint8List(),
    Uint8List bytes => bytes,
    String encoded => base64Decode(encoded),
    _ => null,
  };
  if (data == null) throw const FormatException('malformed frame reply');
  if (payload.length < 6) throw const FormatException('malformed frame reply');
  final colorMap = payload[5];
  if (colorMap != null && colorMap is! Map) {
    throw const FormatException('malformed frame reply');
  }
  return (
    pixelsOrOps: data,
    simple: payload[1] == true,
    opCount: payload[2] is num ? (payload[2] as num).toInt() : 0,
    logs: payload[3] is List ? (payload[3] as List).cast<String>() : const [],
    scriptTime: payload[4] is num
        ? Duration(microseconds: (payload[4] as num).toInt())
        : Duration.zero,
    colors: colorMap == null ? null : decodeSampledColors(colorMap),
  );
}

// ── Sample points and sampled colors codecs ──────────────────────────────

/// Sample-point encoding over any transport: device name, LED index, width
/// fraction.
Object? encodeSamplePoints(List<(LightDeviceId, int, int)>? points) =>
    points?.map((point) => [point.$1.name, point.$2, point.$3]).toList();

/// Decodes sample points; throws when a value does not describe a point.
List<(LightDeviceId, int, int)> decodeSamplePoints(Object? raw) {
  if (raw is! List) throw const FormatException('invalid sample points');
  final points = <(LightDeviceId, int, int)>[];
  for (final entry in raw) {
    if (entry is! List ||
        entry.length != 3 ||
        entry[0] is! String ||
        entry[1] is! int ||
        entry[2] is! int) {
      throw const FormatException('invalid sample point');
    }
    points.add((
      LightDeviceId.values.byName(entry[0] as String),
      entry[1] as int,
      entry[2] as int,
    ));
  }
  return points;
}

/// Encodes the sampled device colors for any transport (names as keys).
Map<String, Object?>? encodeSampledColors(
  Map<LightDeviceId, List<Rgb>>? colors,
) => colors == null
    ? null
    : {
        for (final entry in colors.entries)
          entry.key.name: [
            for (final color in entry.value) [color.r, color.g, color.b],
          ],
      };

/// Rebuilds the sampled colors from a reply, entry by entry: the message may
/// carry anything, so it is checked before use. `null` makes the app sample
/// the returned frame itself.
Map<LightDeviceId, List<Rgb>>? decodeSampledColors(Object? raw) {
  if (raw is! Map) return null;
  final out = <LightDeviceId, List<Rgb>>{};
  for (final entry in raw.entries) {
    final key = entry.key;
    LightDeviceId? id;
    if (key is LightDeviceId) {
      id = key;
    } else if (key is String) {
      for (final candidate in LightDeviceId.values) {
        if (candidate.name == key) {
          id = candidate;
          break;
        }
      }
    }
    final leds = entry.value;
    if (id == null || leds is! List) return null;
    final colors = <Rgb>[];
    for (final color in leds) {
      if (color is Rgb) {
        colors.add(color);
      } else if (color is List &&
          color.length == 3 &&
          color.every((channel) => channel is int)) {
        colors.add(Rgb(color[0] as int, color[1] as int, color[2] as int));
      } else {
        return null;
      }
    }
    out[id] = colors;
  }
  return out;
}
