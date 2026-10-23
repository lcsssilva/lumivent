// "Engine" isolate: sole owner of all hardware handles.
//
// The engine knows no feature. Each module registers an [EngineModule]
// (assembled by a top-level factory in the new isolate) and defines its own
// commands and events by extending [EngineCommand]/[EngineEvent]. This keeps
// real-time loops (fans, LEDs, sensors) running with the window closed, without
// exposing module details to the UI.
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'engine_command.dart';
import 'engine_event.dart';
import 'shutdown_engine.dart';
import 'engine_stopped.dart';
import 'engine_module.dart';
import 'engine_api.dart';
import 'engine_startup_exception.dart';
import 'engine_bootstrap.dart';
import 'engine_ready.dart';
import 'engine_start_failed.dart';

/// Longest the engine waits for one module to stop before moving on, so a
/// stuck worker never blocks the app exit.
const moduleStopTimeout = Duration(milliseconds: 700);

final engineProvider = Provider<EngineApi>(
  (ref) => throw UnimplementedError('engineProvider'),
);

// ── UI side ────────────────────────────────────────────────────────────────

class IsolateEngine implements EngineApi {
  IsolateEngine._(this._rx) {
    _rx.listen((m) {
      switch (m) {
        case EngineReady(:final commands):
          _ready.complete(commands);
        case EngineStartFailed(:final error, :final stack):
          _ready.completeError(
            EngineStartupException(error),
            StackTrace.fromString(stack),
          );
        case EngineEvent():
          _last[m.runtimeType] = m;
          _events.add(m);
        case [final error, final stack]:
          // Unhandled engine error (Isolate.spawn onError).
          stderr.writeln('engine: $error\n$stack');
        case null:
          // Isolate.spawn onExit.
          _onExit();
      }
    });
  }

  void _onExit() {
    if (_exited) return;
    _exited = true;
    if (!_ready.isCompleted) {
      _ready.completeError(
        const EngineStartupException('the engine exited during startup'),
      );
    } else if (!_shuttingDown) {
      stderr.writeln('engine: the isolate exited unexpectedly');
    }
  }

  final ReceivePort _rx;
  final _ready = Completer<SendPort>();
  final _events = StreamController<EngineEvent>.broadcast();
  final _last = <Type, EngineEvent>{};
  late final Isolate _isolate;
  late final SendPort _commands;
  bool _exited = false;
  bool _shuttingDown = false;

  @override
  Stream<EngineEvent> get events => _events.stream;

  @override
  T? lastEvent<T extends EngineEvent>() => _last[T] as T?;

  static Future<IsolateEngine> spawn<T>(
    EngineModulesFactory<T> factory,
    T init,
  ) async {
    final e = IsolateEngine._(ReceivePort('lumivent-engine'));
    e._isolate = await Isolate.spawn(
      _engineMain<T>,
      EngineBootstrap<T>(e._rx.sendPort, factory, init),
      debugName: 'lumivent-engine',
      errorsAreFatal: false,
      onError: e._rx.sendPort,
      onExit: e._rx.sendPort,
    );
    try {
      e._commands = await e._ready.future;
    } on Object {
      e._rx.close();
      await e._events.close();
      rethrow;
    }
    return e;
  }

  @override
  void send(EngineCommand command) => _commands.send(command);

  @override
  Future<void> shutdown() async {
    _shuttingDown = true;
    if (!_exited) {
      final stopped = events.firstWhere((e) => e is EngineStopped);
      send(const ShutdownEngine());
      try {
        await stopped.timeout(const Duration(seconds: 3));
      } on TimeoutException {
        _isolate.kill(priority: Isolate.immediate);
      }
    }
    _rx.close();
    await _events.close();
  }
}

// ── Engine side ────────────────────────────────────────────────────────────

Future<void> _engineMain<T>(EngineBootstrap<T> boot) async {
  final rx = ReceivePort('lumivent-engine-commands');
  // Ready is announced only after every module started: a failure here must
  // reach the UI as a startup error, not leave an engine that drops commands.
  final modules = <EngineModule>[];
  try {
    final built = boot.build();
    for (final m in built) {
      // Added before start: a module that throws midway may own resources.
      modules.add(m);
      m.start(boot.events.send);
    }
  } catch (e, s) {
    stderr.writeln('engine: startup failed: $e\n$s');
    await _stopAll(modules);
    boot.events.send(EngineStartFailed('$e', '$s'));
    rx.close();
    return;
  }
  boot.events.send(EngineReady(rx.sendPort));
  await for (final cmd in rx) {
    if (cmd is ShutdownEngine) {
      await _stopAll(modules);
      boot.events.send(const EngineStopped());
      rx.close();
    } else if (cmd is EngineCommand) {
      var handled = false;
      for (final m in modules) {
        try {
          if (m.handle(cmd)) {
            handled = true;
            break;
          }
        } catch (e, s) {
          // A throwing module still owns the command; don't try the others.
          stderr.writeln(
            'engine: ${m.runtimeType} failed on ${cmd.runtimeType}: $e\n$s',
          );
          handled = true;
          break;
        }
      }
      if (!handled) {
        stderr.writeln('engine: command has no module: ${cmd.runtimeType}');
      }
    }
  }
}

/// Stops [modules] in reverse order; one failure does not block the others.
Future<void> _stopAll(List<EngineModule> modules) async {
  for (final m in modules.reversed) {
    try {
      await Future.sync(m.stop).timeout(moduleStopTimeout);
    } catch (e, s) {
      stderr.writeln('engine: ${m.runtimeType} stop failed: $e\n$s');
    }
  }
}
