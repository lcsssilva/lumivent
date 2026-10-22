// Worker connection of the app side: isolate by default, child process in the
// Linux app build. Both transports carry the named envelopes of
// `effect_worker_protocol.dart`; the caller never sees a raw port message.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'effect_worker.dart';
import 'effect_worker_protocol.dart';
import 'quickjs_effect.dart';

/// How much later than scheduled the request timer may fire before the main
/// isolate is considered stalled rather than the worker hung.
const _timerStallThreshold = Duration(milliseconds: 100);

/// Extra wait granted once after a stalled timer, so a reply already queued
/// behind the stall is processed before a healthy worker is killed.
const _stallGrace = Duration(milliseconds: 250);

/// One request at a time per effect; replies are matched by id.
class EffectWorkerConnection {
  EffectWorkerConnection._({
    this._isolate,
    this._send,
    this._receive,
    this._errors,
    this._process,
    Stopwatch Function()? stopwatch,
  }) : _newStopwatch = stopwatch ?? Stopwatch.new;

  /// Connection over a bare [SendPort], with no worker behind it. Replies are
  /// fed through [handleMessage]. Used by tests to drive the request timers.
  @visibleForTesting
  EffectWorkerConnection.withPort(
    SendPort send, {
    Stopwatch Function()? stopwatch,
  }) : this._(send: send, stopwatch: stopwatch);

  final Stopwatch Function() _newStopwatch;

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

  static Future<EffectWorkerConnection> spawn() async {
    if (_shouldSpawnProcess) return _spawnProcess();
    return _spawnIsolate();
  }

  static bool get _shouldSpawnProcess =>
      Platform.isLinux &&
      File(Platform.resolvedExecutable).uri.pathSegments.last == 'lumivent' &&
      Platform.environment['LUMIVENT_HTML_EFFECT_WORKER'] != 'isolate';

  static Future<EffectWorkerConnection> _spawnProcess() async {
    final process = await Process.start(Platform.resolvedExecutable, [
      '--html-effect-worker',
    ]);
    final connection = EffectWorkerConnection._(process: process);
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

  static Future<EffectWorkerConnection> _spawnIsolate() async {
    final ready = ReceivePort();
    final errors = ReceivePort();
    final isolate = await Isolate.spawn(
      runHtmlEffectIsolateWorker,
      ready.sendPort,
      onError: errors.sendPort,
      errorsAreFatal: false,
      debugName: 'html-effect',
    );
    final handshake = Completer<SendPort>();
    late final EffectWorkerConnection connection;
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
      connection = EffectWorkerConnection._(
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
    final elapsed = _newStopwatch()..start();
    void hung() => _fail(
      EffectScriptException(
        'effect hung: frame exceeded ${timeout.inMilliseconds} ms',
      ),
    );
    _timers[id] = Timer(timeout, () {
      // A timer that fires far past its deadline means this isolate was
      // stalled, so a reply may already be queued: wait once for it. A timer
      // that fires on time is a genuinely hung worker and fails immediately.
      if (elapsed.elapsed - timeout > _timerStallThreshold) {
        _timers[id] = Timer(_stallGrace, hung);
      } else {
        hung();
      }
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
    if (_dead || !line.startsWith(effectWorkerMessagePrefix)) return;
    try {
      final message = jsonDecode(
        line.substring(effectWorkerMessagePrefix.length),
      );
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

  /// Processes one worker reply as if a transport had delivered it.
  @visibleForTesting
  void handleMessage(dynamic message) => _onMessage(message);

  void _onMessage(dynamic message) {
    final reply = EffectWorkerReply.tryParse(message);
    if (reply == null) return;
    final completer = _pending.remove(reply.id);
    if (completer == null) return;
    _timers.remove(reply.id)?.cancel();
    if (reply.ok) {
      completer.complete(reply.payload);
    } else {
      completer.completeError(EffectScriptException(reply.errorMessage));
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
