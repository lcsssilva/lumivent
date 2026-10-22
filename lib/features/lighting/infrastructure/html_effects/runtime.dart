// Runs an HTML/Canvas effect on QuickJS (flutter_js) and draws each frame into a
// 320×200 ui.Image by replaying the binary canvas commands emitted by
// canvas2d_shim.js. Linux app builds use a child process for QuickJS; tests and
// development runners use an isolate. Both paths enforce evaluation deadlines,
// while the process boundary can also kill a native call stuck past its limit.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_js/flutter_js.dart';

import '../../../../core/platform/numeric_locale.dart';
import '../../domain/effect_meta.dart';
import '../../domain/effect_runtime.dart';
import '../../domain/effect_sampling.dart';
import '../../domain/light_device.dart';
import '../../domain/rgb.dart';
import 'canvas_buffer.dart';
import 'canvas_replay.dart';
import 'quickjs_interrupt.dart';
import 'simple_canvas_raster.dart';

class EffectScriptException implements Exception {
  const EffectScriptException(this.message);
  final String message;
  @override
  String toString() => 'EffectScriptException: $message';
}

/// The shim is an asset; read it once on the main isolate and hand it to the
/// worker (background isolates cannot use the Flutter asset bundle).
Future<String>? _shimScript;
Future<String> _loadShim() =>
    _shimScript ??= rootBundle.loadString('assets/effects/canvas2d_shim.js');

/// Longest a frame may run in the worker before the isolate is killed. The
/// runner pauses after three frames above 250 ms; this is the hard stop for a
/// script that never returns.
const scriptHardLimit = Duration(milliseconds: 750);
const scriptLoadLimit = Duration(seconds: 8);

/// QuickJS interrupts one evaluation after this long. Below the hard limits,
/// so the worker answers with the script error before the parent kills it.
const scriptInterruptLimit = Duration(milliseconds: 500);
const scriptLoadInterruptLimit = Duration(seconds: 6);

/// Decodes the base64 string produced by `canvas2d_shim.js`.
Uint8List _decodeCanvas(String s) => base64Decode(s);

/// The JS half of an effect: owns QuickJS and the shim, no dart:ui.
class _JsEffect {
  _JsEffect(this.effect, this._js);

  final EffectSource effect;
  final JavascriptRuntime _js;
  Duration lastScriptTime = Duration.zero;

  static _JsEffect load(String html, String shim, Map<String, Object?> values) {
    // Must run before the first QuickJS parse (see numeric_locale.dart).
    useCNumericLocale();
    final effect = parseEffect(html);
    final js = newInterruptibleQuickJs();
    final rt = _JsEffect(effect, js);
    try {
      rt._eval(shim, 'canvas2d_shim.js', limit: scriptLoadInterruptLimit);
      // Properties become globals before the effect script runs (§6.2).
      final globals = {
        for (final p in effect.properties) p.name: p.resolve(values[p.name]),
      };
      rt._eval(
        'Object.assign(globalThis, ${jsonEncode(globals)});',
        'props',
        limit: scriptLoadInterruptLimit,
      );
      rt._eval(effect.script, effect.title, limit: scriptLoadInterruptLimit);
      for (final hook in ['onEngineReady', 'onReady']) {
        rt._eval(
          'typeof $hook === "function" && $hook();',
          hook,
          limit: scriptLoadInterruptLimit,
        );
      }
    } on Object {
      js.dispose();
      rethrow;
    }
    return rt;
  }

  /// Advances the effect to [nowMs] and returns the canvas command buffer.
  Uint8List renderOps(double nowMs) {
    final sw = Stopwatch()..start();
    final encoded = _eval('__we_frame($nowMs)', 'frame');
    lastScriptTime = sw.elapsed;
    return _decodeCanvas(encoded);
  }

  void setProperty(String name, Object? value) => _eval(
    '__we_setProperty(${jsonEncode(name)}, ${jsonEncode(value)});',
    'setProperty',
  );

  void setSensors(Map<String, double> values) {
    final clean = <String, double>{
      for (final e in values.entries)
        if (e.value.isFinite) e.key: e.value,
    };
    _eval('__we_setSensors(${jsonEncode(clean)});', 'sensors');
  }

  List<String> drainLog() {
    final r = _eval('JSON.stringify(__we_log.splice(0))', 'log');
    return (jsonDecode(r) as List).cast<String>();
  }

  String _eval(
    String code,
    String name, {
    Duration limit = scriptInterruptLimit,
  }) {
    final r = withScriptDeadline(
      limit,
      () => _js.evaluate(code, sourceUrl: name),
    );
    if (r.isError) throw EffectScriptException('$name: ${r.stringResult}');
    return r.stringResult;
  }

  void dispose() => _js.dispose();
}

/// Replays canvas commands and readbacks a frame. Main isolate only.
class _Rasterizer {
  static const width = 320, height = 200;

  final _replayer = CanvasReplayer(
    width: width.toDouble(),
    height: height.toDouble(),
  );
  ui.Image? _frame;
  Uint32List? _simplePixels;
  SimpleRasterState? _simpleState;
  ui.Image? _preview;
  bool _decodingPreview = false;
  DateTime _lastPreviewAt = DateTime.fromMillisecondsSinceEpoch(0);
  int lastOpCount = 0;
  Duration lastRasterTime = Duration.zero, lastReadbackTime = Duration.zero;

  Set<String> get unknownOps => _replayer.unknownOps;

  /// The fast frames accepted by [acceptSimple], for preview and snapshot.
  Uint32List? get simplePixels => _simplePixels;

  ui.Image? get image {
    final pixels = _simplePixels;
    if (pixels != null) {
      final now = DateTime.now();
      if (!_decodingPreview &&
          now.difference(_lastPreviewAt) > const Duration(milliseconds: 100)) {
        _lastPreviewAt = now;
        _decodingPreview = true;
        _decode(pixels).then(
          (img) {
            if (!_decodingPreview) {
              img.dispose();
              return;
            }
            _preview?.dispose();
            _preview = img;
            _decodingPreview = false;
          },
          onError: (Object _) {
            _decodingPreview = false;
          },
        );
      }
      return _preview;
    }
    return _frame;
  }

  /// Accepts a frame already rasterized on the render isolate (the fast
  /// path): the runtime only formats the RGBA bytes ([rgba]) and keeps the
  /// pixels for preview and snapshot. No raster work reaches the UI isolate.
  EffectFrame acceptSimple(Uint8List rgba, int opCount) {
    lastRasterTime = Duration.zero;
    lastReadbackTime = Duration.zero;
    lastOpCount = opCount;
    _frame?.dispose();
    _frame = null;
    _simplePixels = Uint32List.view(
      rgba.buffer,
      rgba.offsetInBytes,
      rgba.lengthInBytes >> 2,
    );
    return EffectFrame(width, height, rgba);
  }

  Future<EffectFrame> draw(Uint8List encoded) async {
    final simple = SimpleCanvasRaster.tryRaster(
      encoded,
      previous: _simplePixels,
      state: _simpleState ?? const SimpleRasterState(),
    );
    if (simple != null) {
      final frame = acceptSimple(simple.rgba, simple.opCount);
      _simpleState = simple.state;
      return frame;
    }
    return drawSlow(encoded);
  }

  /// General dart:ui replay, for frames the fast path cannot draw.
  Future<EffectFrame> drawSlow(Uint8List encoded) async {
    final sw = Stopwatch()..start();
    _simplePixels = null;
    _simpleState = null;
    _preview?.dispose();
    _preview = null;
    final ops = CanvasCommandBuffer(encoded);
    sw.reset();
    final rec = ui.PictureRecorder();
    final canvas = ui.Canvas(
      rec,
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );
    // The browser canvas preserves content between frames (Neon Shift relies
    // on this): start from the previous image.
    final prev = _frame;
    if (prev != null) {
      canvas.drawImage(
        prev,
        ui.Offset.zero,
        ui.Paint()..blendMode = ui.BlendMode.src,
      );
    }
    _replayer.replay(canvas, ops);
    final pic = rec.endRecording();
    final img = await pic.toImage(width, height);
    pic.dispose();
    lastRasterTime = sw.elapsed;
    lastOpCount = ops.count;

    sw.reset();
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    lastReadbackTime = sw.elapsed;
    prev?.dispose();
    _frame = img;
    if (data == null) {
      throw const EffectScriptException('frame read failed');
    }
    return EffectFrame(
      width,
      height,
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  Future<Uint8List?> snapshotPng() async {
    final pixels = _simplePixels;
    if (pixels != null) {
      final img = await _decode(pixels);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      if (png == null) return null;
      return png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
    }
    final png = await _frame?.toByteData(format: ui.ImageByteFormat.png);
    if (png == null) return null;
    return png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
  }

  Future<ui.Image> _decode(Uint32List pixels) {
    final done = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      Uint8List.view(pixels.buffer, pixels.offsetInBytes, pixels.lengthInBytes),
      width,
      height,
      ui.PixelFormat.rgba8888,
      done.complete,
    );
    return done.future;
  }

  void dispose() {
    _frame?.dispose();
    _frame = null;
    _preview?.dispose();
    _preview = null;
    _simplePixels = null;
    _simpleState = null;
  }
}

/// Direct (same-isolate) runtime, used by the benchmark spike and tests.
class HtmlEffectRuntime implements EffectRuntime {
  HtmlEffectRuntime._(this.effect, this._js, this._raster);

  static const width = _Rasterizer.width, height = _Rasterizer.height;

  @override
  final EffectSource effect;
  final _JsEffect _js;
  final _Rasterizer _raster;
  List<(LightDeviceId, int, int)>? _samplePoints;

  Duration lastRasterTime = Duration.zero, lastReadbackTime = Duration.zero;
  int lastOpCount = 0;

  Duration get lastScriptTime => _js.lastScriptTime;
  @override
  Set<String> get unknownOps => _raster.unknownOps;

  /// Last rendered frame (for previews and thumbnails).
  ui.Image? get preview => _raster.image;

  static Future<HtmlEffectRuntime> load(
    String html, {
    Map<String, Object?> values = const {},
    String? shim,
  }) async {
    final js = _JsEffect.load(html, shim ?? await _loadShim(), values);
    return HtmlEffectRuntime._(js.effect, js, _Rasterizer());
  }

  @override
  Future<EffectFrame> renderFrame(double nowMs) async =>
      (await renderSampled(nowMs)).$1;

  @override
  Future<(EffectFrame, Map<LightDeviceId, List<Rgb>>?)> renderSampled(
    double nowMs,
  ) async {
    final encoded = _js.renderOps(nowMs);
    final frame = await _raster.draw(encoded);
    lastOpCount = _raster.lastOpCount;
    lastRasterTime = _raster.lastRasterTime;
    lastReadbackTime = _raster.lastReadbackTime;
    final points = _samplePoints;
    final pixels = _raster.simplePixels;
    return (
      frame,
      points == null || pixels == null
          ? null
          : sampleCanvasPixels(points, pixels),
    );
  }

  @override
  void setSamplePoints(List<(LightDeviceId, int, int)>? points) =>
      _samplePoints = points;

  @override
  void setProperty(String name, Object? value) => _js.setProperty(name, value);

  @override
  void setSensors(Map<String, double> values) => _js.setSensors(values);

  @override
  Future<Uint8List?> snapshotPng() => _raster.snapshotPng();

  @override
  List<String> drainLog() => _js.drainLog();

  @override
  void dispose() {
    _raster.dispose();
    _js.dispose();
  }
}

const _processWorkerPrefix = 'LUMIVENT_HTML_EFFECT:';

/// Runs the hidden Flutter entrypoint used by the parent process.
///
/// The process boundary is the hard stop for native QuickJS code that does not
/// return to Dart's interrupt handler.
Future<void> runHtmlEffectWorker() async {
  limitWorkerAddressSpace();
  HtmlEffectRuntime? runtime;
  Object? pendingError;

  Future<void> send(Object message) async {
    stdout.writeln('$_processWorkerPrefix${jsonEncode(message)}');
    await stdout.flush();
  }

  await send({'ready': true});
  try {
    await for (final line
        in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.length > 12 * 1024 * 1024) {
        throw const FormatException('effect worker request is too large');
      }
      final decoded = jsonDecode(line);
      if (decoded is! List || decoded.length < 2 || decoded[0] is! int) {
        continue;
      }
      final id = decoded[0] as int;
      final op = decoded[1];
      try {
        Object? reply;
        switch (op) {
          case 'load':
            if (decoded.length < 5 ||
                decoded[2] is! String ||
                decoded[3] is! String ||
                decoded[4] is! Map) {
              throw const FormatException('invalid load request');
            }
            runtime?.dispose();
            runtime = await HtmlEffectRuntime.load(
              decoded[2] as String,
              shim: decoded[3] as String,
              values: (decoded[4] as Map).cast<String, Object?>(),
            );
          case 'points':
            final raw = decoded.length > 2 ? decoded[2] : null;
            if (raw == null) {
              runtime?.setSamplePoints(null);
              break;
            }
            final points = <(LightDeviceId, int, int)>[];
            if (raw is! List) {
              throw const FormatException('invalid sample points');
            }
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
            runtime?.setSamplePoints(points);
          case 'frame':
            final current = runtime;
            if (current == null || decoded.length < 3 || decoded[2] is! num) {
              throw const EffectScriptException('no effect');
            }
            final error = pendingError;
            pendingError = null;
            if (error != null) throw EffectScriptException('$error');
            final (frame, colors) = await current.renderSampled(
              (decoded[2] as num).toDouble(),
            );
            reply = [
              base64Encode(frame.rgba),
              true,
              current.lastOpCount,
              current.drainLog(),
              current.lastScriptTime.inMicroseconds,
              colors == null
                  ? null
                  : {
                      for (final entry in colors.entries)
                        entry.key.name: [
                          for (final color in entry.value)
                            [color.r, color.g, color.b],
                        ],
                    },
            ];
          case 'property':
            if (decoded.length < 3 || decoded[2] is! String) {
              throw const FormatException('invalid property request');
            }
            try {
              runtime?.setProperty(
                decoded[2] as String,
                decoded.length > 3 ? decoded[3] : null,
              );
            } on Object catch (error) {
              pendingError = error;
            }
          case 'sensors':
            if (decoded.length < 3 || decoded[2] is! Map) {
              throw const FormatException('invalid sensors request');
            }
            try {
              runtime?.setSensors((decoded[2] as Map).cast<String, double>());
            } on Object catch (error) {
              pendingError = error;
            }
          case 'log':
            reply = runtime?.drainLog() ?? const <String>[];
          case 'dispose':
            runtime?.dispose();
            runtime = null;
            if (id != 0) await send([id, true, null]);
            return;
          default:
            throw FormatException('unknown worker operation: $op');
        }
        if (id != 0) await send([id, true, reply]);
      } on Object catch (error, stack) {
        if (id != 0) {
          await send([
            id,
            false,
            ['$error', '$stack'],
          ]);
        }
      }
    }
  } finally {
    runtime?.dispose();
  }
}

/// Runtime used by the app: QuickJS in a worker that can be killed when a frame
/// exceeds [scriptHardLimit] or the effect throws. The fast raster path also
/// runs there (a simple canvas is mutated in place and published per frame),
/// so the UI isolate only forwards the RGBA bytes.
class IsolatedHtmlEffectRuntime implements EffectRuntime {
  static const _maxBufferedLogs = 200;

  IsolatedHtmlEffectRuntime._(this.effect, this._connection, this._raster);

  @override
  final EffectSource effect;
  final _WorkerConnection _connection;
  final _Rasterizer _raster;
  final _logs = <String>[];
  Duration _lastScriptTime = Duration.zero;

  static const width = _Rasterizer.width, height = _Rasterizer.height;

  int get lastOpCount => _raster.lastOpCount;
  Duration get lastScriptTime => _lastScriptTime;
  Duration get lastRasterTime => _raster.lastRasterTime;
  Duration get lastReadbackTime => _raster.lastReadbackTime;
  ui.Image? get preview => _raster.image;

  @override
  Set<String> get unknownOps => _raster.unknownOps;

  static Future<IsolatedHtmlEffectRuntime> load(
    String html, {
    Map<String, Object?> values = const {},
    String? shim,
  }) async {
    final effect = parseEffect(html);
    final connection = await _WorkerConnection.spawn();
    try {
      await connection.request([
        'load',
        html,
        shim ?? await _loadShim(),
        values,
      ], timeout: scriptLoadLimit);
    } on Object {
      connection.close();
      rethrow;
    }
    return IsolatedHtmlEffectRuntime._(effect, connection, _Rasterizer());
  }

  @override
  Future<EffectFrame> renderFrame(double nowMs) async =>
      (await renderSampled(nowMs)).$1;

  @override
  Future<(EffectFrame, Map<LightDeviceId, List<Rgb>>?)> renderSampled(
    double nowMs,
  ) async {
    final reply = await _connection.request([
      'frame',
      nowMs,
    ], timeout: scriptHardLimit) as List;
    if (reply.length < 6 || reply[0] is! TransferableTypedData) {
      throw const EffectScriptException('malformed frame reply');
    }
    final rawData = reply[0];
    final data = switch (rawData) {
      TransferableTypedData typedData => typedData.materialize().asUint8List(),
      String encoded => base64Decode(encoded),
      _ => throw const EffectScriptException('malformed frame data'),
    };
    _logs.addAll((reply[3] as List).cast<String>().take(_maxBufferedLogs));
    if (_logs.length > _maxBufferedLogs) {
      _logs.removeRange(0, _logs.length - _maxBufferedLogs);
    }
    if (reply[4] is num) {
      _lastScriptTime = Duration(microseconds: (reply[4] as num).toInt());
    }
    if (!identical(reply[1], true)) {
      // General replay on the UI isolate: no sampling available, the app
      // samples from the returned frame itself.
      return (await _raster.drawSlow(data), null);
    }
    if (data.lengthInBytes !=
        SimpleCanvasRaster.width * SimpleCanvasRaster.height * 4) {
      throw const EffectScriptException('frame pixels have the wrong size');
    }
    return (
      _raster.acceptSimple(
        data,
        reply[2] is num ? (reply[2] as num).toInt() : 0,
      ),
      // A null map (invalid reply payload) makes the app sample itself.
      _colors(reply[5]),
    );
  }

  @override
  void setSamplePoints(List<(LightDeviceId, int, int)>? points) =>
      _connection.send([
        'points',
        points?.map((point) => [point.$1.name, point.$2, point.$3]).toList(),
      ]);

  /// Rebuilds the sampled colors from the worker reply, entry by entry: the
  /// isolate message may carry anything, so it is checked before use.
  static Map<LightDeviceId, List<Rgb>>? _colors(Object? raw) {
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

  @override
  void setProperty(String name, Object? value) =>
      _connection.send(['property', name, value]);

  @override
  void setSensors(Map<String, double> values) {
    final clean = <String, double>{
      for (final e in values.entries)
        if (e.value.isFinite) e.key: e.value,
    };
    _connection.send(['sensors', clean]);
  }

  @override
  Future<Uint8List?> snapshotPng() => _raster.snapshotPng();

  @override
  List<String> drainLog() {
    final out = List<String>.of(_logs);
    _logs.clear();
    return out;
  }

  @override
  void dispose() {
    _connection.close();
    _raster.dispose();
  }
}

/// One request at a time per effect; replies are matched by id.
class _WorkerConnection {
  _WorkerConnection._({
    this._isolate,
    this._send,
    this._receive,
    this._errors,
    this._process,
  });

  final Isolate? _isolate;
  final SendPort? _send;
  final ReceivePort? _receive;
  final ReceivePort? _errors;
  final Process? _process;
  StreamSubscription<String>? _stdout;
  StreamSubscription<String>? _stderr;
  Completer<void>? _handshake;
  final _pending = <int, Completer<Object?>>{};
  final _timers = <int, Timer>{};
  String _stderrText = '';
  int _next = 1;
  bool _dead = false;

  static Future<_WorkerConnection> spawn() async {
    if (_shouldSpawnProcess) return _spawnProcess();
    return _spawnIsolate();
  }

  static bool get _shouldSpawnProcess =>
      Platform.isLinux &&
      File(Platform.resolvedExecutable).uri.pathSegments.last == 'lumivent' &&
      Platform.environment['LUMIVENT_HTML_EFFECT_WORKER'] != 'isolate';

  static Future<_WorkerConnection> _spawnProcess() async {
    final process = await Process.start(Platform.resolvedExecutable, [
      '--html-effect-worker',
    ]);
    final connection = _WorkerConnection._(process: process);
    final handshake = connection._handshake = Completer<void>();
    connection._stdout = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(connection._onProcessLine, onError: connection._onError);
    connection._stderr = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(connection._captureStderr, onError: connection._onError);
    process.exitCode.then(connection._onProcessExit);
    try {
      await handshake.future.timeout(scriptLoadLimit);
      return connection;
    } on Object {
      connection.close();
      rethrow;
    }
  }

  static Future<_WorkerConnection> _spawnIsolate() async {
    final ready = ReceivePort();
    final errors = ReceivePort();
    final isolate = await Isolate.spawn(
      _workerMain,
      ready.sendPort,
      onError: errors.sendPort,
      errorsAreFatal: false,
      debugName: 'html-effect',
    );
    final handshake = Completer<SendPort>();
    late final _WorkerConnection connection;
    // A ReceivePort can be listened to only once: use the same subscription for
    // the handshake and for the command replies.
    ready.listen((dynamic message) {
      if (!handshake.isCompleted) {
        if (message is SendPort) {
          handshake.complete(message);
        } else {
          handshake.completeError(
            const EffectScriptException('invalid effect handshake'),
          );
        }
        return;
      }
      connection._onMessage(message);
    });
    try {
      final send = await handshake.future.timeout(scriptLoadLimit);
      connection = _WorkerConnection._(
        isolate: isolate,
        send: send,
        receive: ready,
        errors: errors,
      );
      errors.listen(connection._onError);
      return connection;
    } on Object {
      isolate.kill(priority: Isolate.immediate);
      ready.close();
      errors.close();
      rethrow;
    }
  }

  Future<Object?> request(List<Object?> message, {required Duration timeout}) {
    if (_dead) {
      return Future.error(
        const EffectScriptException('The effect was stopped.'),
      );
    }
    final id = _next++;
    final completer = Completer<Object?>();
    _pending[id] = completer;
    _timers[id] = Timer(timeout, () {
      _fail(
        EffectScriptException(
          'effect hung: frame exceeded ${timeout.inMilliseconds} ms',
        ),
      );
    });
    _sendMessage([id, ...message]);
    return completer.future;
  }

  /// Fire-and-forget (properties/sensors); errors surface on the next frame.
  void send(List<Object?> message) {
    if (_dead) return;
    _sendMessage([0, ...message]);
  }

  void _sendMessage(List<Object?> message) {
    final process = _process;
    if (process == null) {
      _send!.send(message);
      return;
    }
    unawaited(() async {
      try {
        process.stdin.writeln(jsonEncode(message));
        await process.stdin.flush();
      } on Object catch (error) {
        _fail(EffectScriptException('could not send to effect worker: $error'));
      }
    }());
  }

  void _onProcessLine(String line) {
    if (_dead || !line.startsWith(_processWorkerPrefix)) return;
    try {
      final message = jsonDecode(line.substring(_processWorkerPrefix.length));
      if (message is Map && message['ready'] == true) {
        final handshake = _handshake;
        if (handshake != null && !handshake.isCompleted) {
          handshake.complete();
        }
        return;
      }
      _onMessage(message);
    } on Object catch (error) {
      _fail(EffectScriptException('invalid effect worker response: $error'));
    }
  }

  void _captureStderr(String line) {
    _stderrText = '$_stderrText$line\n';
    if (_stderrText.length > 8192) {
      _stderrText = _stderrText.substring(_stderrText.length - 8192);
    }
  }

  void _onProcessExit(int code) {
    if (_dead) return;
    final detail = _stderrText.trim();
    _fail(
      EffectScriptException(
        detail.isEmpty
            ? 'effect worker exited with code $code'
            : 'effect worker exited with code $code: $detail',
      ),
    );
  }

  void _onMessage(dynamic message) {
    if (_dead || message is! List || message.length < 3) return;
    final id = message[0];
    final completer = id is int ? _pending.remove(id) : null;
    if (completer == null) return;
    _timers.remove(id)?.cancel();
    if (message[1] == true) {
      completer.complete(message[2]);
    } else {
      final detail = message[2];
      final text = detail is List && detail.isNotEmpty
          ? '${detail[0]}'
          : '$detail';
      completer.completeError(EffectScriptException(text));
    }
  }

  void _onError(dynamic message) {
    final text = message is List && message.isNotEmpty
        ? '${message.first}'
        : '$message';
    _fail(EffectScriptException('effect isolate: $text'));
  }

  void _fail(Object error) {
    if (_dead) return;
    _dead = true;
    final handshake = _handshake;
    if (handshake != null && !handshake.isCompleted) {
      handshake.completeError(error);
    }
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(error);
    }
    _pending.clear();
    _isolate?.kill(priority: Isolate.immediate);
    _process?.kill(ProcessSignal.sigkill);
    _receive?.close();
    _errors?.close();
    unawaited(_stdout?.cancel());
    unawaited(_stderr?.cancel());
  }

  void close() => _fail(const EffectScriptException('Effect unloaded.'));
}

void _workerMain(SendPort main) {
  final receive = ReceivePort();
  main.send(receive.sendPort);
  _JsEffect? runtime;
  Object? pendingError;

  // Fast-path state of the effect being drawn: the previous fast canvas is
  // mutated in place every frame ("double buffer" of one retained canvas);
  // each transfer publishes a per-frame copy, so the UI isolate never touches
  // this memory. Null canvas = the general replay drew the previous frame,
  // so the next frame starts over from opaque black.
  Uint32List? fastCanvas;
  SimpleRasterState fastState = const SimpleRasterState();

  // Where the LED colors are sampled (the runner sends the points once its
  // config changes; null = the app samples the returned frame itself).
  List<(LightDeviceId, int, int)>? samplePoints;

  void reply(int id, bool ok, Object? payload) {
    main.send([id, ok, payload]);
  }

  receive.listen((dynamic message) {
    if (message is! List || message.length < 2) return;
    final id = message[0] as int;
    final op = message[1] as String;
    try {
      switch (op) {
        case 'load':
          runtime?.dispose();
          runtime = _JsEffect.load(
            message[2] as String,
            message[3] as String,
            (message[4] as Map).cast<String, Object?>(),
          );
          fastCanvas = null;
          fastState = const SimpleRasterState();
          reply(id, true, null);
        case 'points':
          final raw = message.length > 2 ? message[2] : null;
          if (raw == null) {
            samplePoints = null;
            break;
          }
          final points = <(LightDeviceId, int, int)>[];
          for (final entry in raw is List ? raw : const []) {
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
          samplePoints = points;
        case 'frame':
          final error = pendingError;
          pendingError = null;
          if (error != null) throw EffectScriptException('$error');
          final js = runtime;
          if (js == null) throw const EffectScriptException('no effect');
          final bytes = js.renderOps((message[2] as num).toDouble());
          final logs = js.drainLog();
          final raster = fastCanvas == null
              ? SimpleCanvasRaster.rasterInto(
                  Uint32List(
                    SimpleCanvasRaster.width * SimpleCanvasRaster.height,
                  ),
                  bytes,
                  firstFrame: true,
                )
              : SimpleCanvasRaster.rasterInto(
                  fastCanvas!,
                  bytes,
                  firstFrame: false,
                  state: fastState,
                );
          final simple = raster != null;
          if (simple) {
            fastCanvas = raster.pixels;
            fastState = raster.state;
          } else {
            // The frame went to the general replay: drop the fast canvas.
            fastCanvas = null;
          }
          final points = samplePoints;
          final colors = simple && points != null
              ? sampleCanvasPixels(points, raster.pixels)
              : null;
          reply(id, true, [
            // Fast frames transfer the RGBA pixels; slow frames the raw ops.
            TransferableTypedData.fromList([
              simple ? raster.pixels : bytes as TypedData,
            ]),
            simple,
            simple ? raster.opCount : -1,
            logs,
            js.lastScriptTime.inMicroseconds,
            colors,
          ]);
        case 'property':
          try {
            runtime?.setProperty(
              message[2] as String,
              message.length > 3 ? message[3] : null,
            );
          } on Object catch (e) {
            pendingError = e;
          }
        case 'sensors':
          try {
            runtime?.setSensors((message[2] as Map).cast<String, double>());
          } on Object catch (e) {
            pendingError = e;
          }
        case 'log':
          reply(id, true, runtime?.drainLog() ?? const <String>[]);
        case 'dispose':
          runtime?.dispose();
          runtime = null;
          fastCanvas = null;
          reply(id, true, null);
          receive.close();
      }
    } on Object catch (e, st) {
      reply(id, false, ['$e', '$st']);
    }
  });
}

/// Port implementation used by the UI (wired in `lighting_module.dart`).
class HtmlEffectRuntimeFactory implements EffectRuntimeFactory {
  const HtmlEffectRuntimeFactory();

  @override
  Future<EffectRuntime> load(
    String html, {
    Map<String, Object?> values = const {},
  }) => IsolatedHtmlEffectRuntime.load(html, values: values);
}
