// The worker side of the HTML effect runtime: the hidden Flutter process
// (`--html-effect-worker`) and the fallback isolate share the message shape
// and validation of `effect_worker_protocol.dart`, with one entry point per
// transport.
//
// The process boundary is the hard stop for native QuickJS code that does not
// return to Dart's interrupt handler: the parent kills the process when a
// frame exceeds `scriptHardLimit`. Background isolates cannot kill native
// code, so they only use the (shorter) interrupt deadlines.
//
// Both entries answer known requests with `[id, true, payload]` or
// `[id, false, [message, stack]]`; malformed envelopes are dropped; unknown
// ops are answered as an error so the parent's request does not wait for its
// timeout.

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import '../../domain/effect_sampling.dart' show sampleCanvasPixels;
import '../../domain/light_device.dart';
import 'effect_worker_protocol.dart';
import 'quickjs_effect.dart';
import 'quickjs_interrupt.dart' show limitWorkerAddressSpace;
import 'runtime.dart';
import 'simple_canvas_raster.dart';

/// Runs the hidden Flutter entrypoint used by the parent process.
Future<void> runHtmlEffectWorker() async {
  limitWorkerAddressSpace();
  HtmlEffectRuntime? runtime;
  Object? pendingError;

  Future<void> sendLine(Object message) async {
    stdout.writeln('$effectWorkerMessagePrefix${jsonEncode(message)}');
    await stdout.flush();
  }

  await sendLine({'ready': true});
  try {
    await for (final line
        in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.length > EffectWorkerOperation.maxLineBytes) {
        throw const EffectScriptException('effect worker request is too large');
      }
      final request = EffectWorkerRequest.tryParse(jsonDecode(line));
      if (request == null) continue;
      try {
        Object? reply;
        switch (request.operation) {
          case EffectWorkerOperation.load:
            final args = request.arguments;
            if (args.length < 3 ||
                args[0] is! String ||
                args[1] is! String ||
                args[2] is! Map) {
              throw const FormatException('invalid load request');
            }
            runtime?.dispose();
            runtime = await HtmlEffectRuntime.load(
              request.html(),
              shim: request.shim(),
              values: request.values(),
            );
          case EffectWorkerOperation.points:
            final points = request.samplePoints;
            runtime?.setSamplePoints(points);
          case EffectWorkerOperation.frame:
            final current = runtime;
            if (current == null) {
              throw const EffectScriptException('no effect');
            }
            final error = pendingError;
            pendingError = null;
            if (error != null) throw EffectScriptException('$error');
            final (frame, colors) = await current.renderSampled(
              request.frameTime(),
            );
            reply = [
              base64Encode(frame.rgba),
              true,
              current.lastOpCount,
              current.drainLog(),
              current.lastScriptTime.inMicroseconds,
              encodeSampledColors(colors),
            ];
          case EffectWorkerOperation.property:
            if (request.arguments.isEmpty || request.arguments[0] is! String) {
              throw const FormatException('invalid property request');
            }
            try {
              runtime?.setProperty(
                request.propertyName(),
                request.propertyValue(),
              );
            } on Object catch (error) {
              pendingError = error;
            }
          case EffectWorkerOperation.sensors:
            if (request.arguments.isEmpty || request.arguments[0] is! Map) {
              throw const FormatException('invalid sensors request');
            }
            try {
              runtime?.setSensors(request.sensorValues());
            } on Object catch (error) {
              pendingError = error;
            }
          case EffectWorkerOperation.log:
            reply = runtime?.drainLog() ?? const <String>[];
          case EffectWorkerOperation.dispose:
            runtime?.dispose();
            runtime = null;
            if (request.id != 0) await sendLine(request.ok());
            return;
          case null:
            throw FormatException('unknown worker operation: ${request.op}');
        }
        if (request.id != 0) await sendLine(request.ok(reply));
      } on Object catch (error, stack) {
        if (request.id != 0) {
          await sendLine(request.error(error, stack));
        }
      }
    }
  } finally {
    runtime?.dispose();
  }
}

/// Worker side of the isolate transport (spawned by the app's fallback path).
void runHtmlEffectIsolateWorker(SendPort main) {
  final receive = ReceivePort();
  main.send(receive.sendPort);
  QuickJsEffect? runtime;
  Object? pendingError;

  // Fast-path state of the effect being drawn: the previous fast canvas is
  // mutated in place every frame ("double buffer" of one retained canvas);
  // each transfer publishes a per-frame copy, so the UI isolate never touches
  // this memory. Null canvas after the first frame = the general replay drew
  // the previous frame: its pixels are unknown, so the next fast frame must
  // start by covering the whole canvas ([renderIsolateFrame]).
  Uint32List? fastCanvas;
  SimpleRasterState fastState = const SimpleRasterState();
  var firstFrame = true;

  // Where the LED colors are sampled (the runner sends the points once its
  // config changes; null = the app samples the returned frame itself).
  List<(LightDeviceId, int, int)>? samplePoints;

  receive.listen((dynamic message) {
    final request = EffectWorkerRequest.tryParse(message);
    if (request == null) return;
    try {
      Object? reply;
      switch (request.operation) {
        case EffectWorkerOperation.load:
          runtime?.dispose();
          runtime = QuickJsEffect.load(
            request.html(),
            request.shim(),
            request.values(),
          );
          fastCanvas = null;
          fastState = const SimpleRasterState();
          firstFrame = true;
        case EffectWorkerOperation.points:
          samplePoints = request.samplePoints;
        case EffectWorkerOperation.frame:
          final error = pendingError;
          pendingError = null;
          if (error != null) throw EffectScriptException('$error');
          final js = runtime;
          if (js == null) throw const EffectScriptException('no effect');
          reply = renderIsolateFrame(
            js,
            request.frameTime(),
            fastState: fastState,
            fastCanvas: fastCanvas,
            firstFrame: firstFrame,
            points: samplePoints,
            onState: (canvas, state) {
              fastCanvas = canvas;
              fastState = state;
              firstFrame = false;
            },
          );
        case EffectWorkerOperation.property:
          try {
            runtime?.setProperty(
              request.propertyName(),
              request.propertyValue(),
            );
          } on Object catch (e) {
            pendingError = e;
          }
        case EffectWorkerOperation.sensors:
          try {
            runtime?.setSensors(request.sensorValues());
          } on Object catch (e) {
            pendingError = e;
          }
        case EffectWorkerOperation.log:
          reply = runtime?.drainLog() ?? const <String>[];
        case EffectWorkerOperation.dispose:
          runtime?.dispose();
          runtime = null;
          fastCanvas = null;
          receive.close();
          return;
        case null:
          throw FormatException('unknown worker operation: ${request.op}');
      }
      if (request.id != 0) main.send(request.ok(reply));
    } on Object catch (e, st) {
      main.send(request.error(e, st));
    }
  });
}

/// One isolate-transport frame: renders the ops on QuickJS, tries the fast
/// raster path in place, and answers with [frameReply]. The caller keeps the
/// fast canvas via [onState]. A null [fastCanvas] on a frame that is not the
/// [firstFrame] means the general replay drew the previous one.
List<Object?> renderIsolateFrame(
  QuickJsEffect js,
  double nowMs, {
  required SimpleRasterState fastState,
  required Uint32List? fastCanvas,
  required bool firstFrame,
  required List<(LightDeviceId, int, int)>? points,
  required void Function(Uint32List? canvas, SimpleRasterState state) onState,
}) {
  final bytes = js.renderOps(nowMs);
  final logs = js.drainLog();
  final raster = SimpleCanvasRaster.rasterInto(
    fastCanvas ??
        Uint32List(SimpleCanvasRaster.width * SimpleCanvasRaster.height),
    bytes,
    firstFrame: fastCanvas == null && firstFrame,
    mustCover: fastCanvas == null && !firstFrame,
    state: fastState,
  );
  final simple = raster != null;
  if (simple) {
    onState(raster.pixels, raster.state);
  } else {
    // The frame went to the general replay: drop the fast canvas and keep the
    // styles it left behind.
    onState(null, SimpleCanvasRaster.stateAfterReplay(bytes, fastState));
  }
  final colors = simple && points != null
      ? sampleCanvasPixels(points, raster.pixels)
      : null;
  return frameReply(
    pixelsOrOps: simple ? raster.pixels : bytes,
    simple: simple,
    opCount: simple ? raster.opCount : -1,
    logs: logs,
    scriptTime: js.lastScriptTime,
    colors: colors,
  );
}
