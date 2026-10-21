// Runs an HTML/Canvas effect on QuickJS (flutter_js) and draws each frame into a
// 320×200 ui.Image by replaying the binary canvas commands emitted by
// canvas2d_shim.js.
//
// QuickJS lives in a worker isolate. Each evaluation has a deadline enforced by
// QuickJS's interrupt handler (quickjs_interrupt.dart), which stops
// `while (true) {}` and frees the thread; the parent still kills the isolate
// after [scriptHardLimit] as a second guard. Rasterization (dart:ui) stays on
// the main isolate, which also keeps the worker free of Flutter bindings.

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_js/flutter_js.dart';

import '../../../../core/platform/numeric_locale.dart';
import '../../domain/effect_meta.dart';
import '../../domain/effect_runtime.dart';
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

  Future<EffectFrame> draw(Uint8List encoded) async {
    final sw = Stopwatch()..start();
    final simple = SimpleCanvasRaster.tryRaster(
      encoded,
      previous: _simplePixels,
      state: _simpleState ?? const SimpleRasterState(),
    );
    if (simple != null) {
      _simplePixels = simple.pixels;
      _simpleState = simple.state;
      _frame?.dispose();
      _frame = null;
      lastRasterTime = sw.elapsed;
      lastReadbackTime = Duration.zero;
      lastOpCount = simple.opCount;
      return EffectFrame(width, height, simple.rgba);
    }
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
  Future<EffectFrame> renderFrame(double nowMs) async {
    final encoded = _js.renderOps(nowMs);
    final frame = await _raster.draw(encoded);
    lastOpCount = _raster.lastOpCount;
    lastRasterTime = _raster.lastRasterTime;
    lastReadbackTime = _raster.lastReadbackTime;
    return frame;
  }

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

/// Runtime used by the app: QuickJS in a worker isolate that can be killed
/// when a frame exceeds [scriptHardLimit] or the effect throws.
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
  Future<EffectFrame> renderFrame(double nowMs) async {
    final reply = await _connection.request([
      'frame',
      nowMs,
    ], timeout: scriptHardLimit) as List;
    final data = reply[0] as TransferableTypedData;
    _logs.addAll((reply[1] as List).cast<String>().take(_maxBufferedLogs));
    if (_logs.length > _maxBufferedLogs) {
      _logs.removeRange(0, _logs.length - _maxBufferedLogs);
    }
    if (reply.length > 2 && reply[2] is num) {
      _lastScriptTime = Duration(microseconds: (reply[2] as num).toInt());
    }
    return _raster.draw(data.materialize().asUint8List());
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
  _WorkerConnection._(this._isolate, this._send, this._receive, this._errors);

  final Isolate _isolate;
  final SendPort _send;
  final ReceivePort _receive;
  final ReceivePort _errors;
  final _pending = <int, Completer<Object?>>{};
  final _timers = <int, Timer>{};
  int _next = 1;
  bool _dead = false;

  static Future<_WorkerConnection> spawn() async {
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
      connection = _WorkerConnection._(isolate, send, ready, errors);
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
    _send.send([id, ...message]);
    return completer.future;
  }

  /// Fire-and-forget (properties/sensors); errors surface on the next frame.
  void send(List<Object?> message) {
    if (_dead) return;
    _send.send([0, ...message]);
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
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(error);
    }
    _pending.clear();
    _isolate.kill(priority: Isolate.immediate);
    _receive.close();
    _errors.close();
  }

  void close() => _fail(const EffectScriptException('Effect unloaded.'));
}

void _workerMain(SendPort main) {
  final receive = ReceivePort();
  main.send(receive.sendPort);
  _JsEffect? runtime;
  Object? pendingError;

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
          reply(id, true, null);
        case 'frame':
          final error = pendingError;
          pendingError = null;
          if (error != null) throw EffectScriptException('$error');
          final js = runtime;
          if (js == null) throw const EffectScriptException('no effect');
          final bytes = js.renderOps((message[2] as num).toDouble());
          final logs = js.drainLog();
          reply(id, true, [
            TransferableTypedData.fromList([bytes]),
            logs,
            js.lastScriptTime.inMicroseconds,
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
