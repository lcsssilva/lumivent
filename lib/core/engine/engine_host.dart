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

/// UI → engine message. Each module defines its own messages.
abstract class EngineCommand {
  const EngineCommand();
}

/// Engine → UI message. Each module defines its own messages.
abstract class EngineEvent {
  const EngineEvent();
}

/// Closes all modules; the engine responds with [EngineStopped] and exits.
class ShutdownEngine extends EngineCommand {
  const ShutdownEngine();
}

class EngineStopped extends EngineEvent {
  const EngineStopped();
}

/// Longest the engine waits for one module to stop before moving on, so a
/// stuck worker never blocks the app exit.
const moduleStopTimeout = Duration(milliseconds: 700);

/// Part of a module that runs inside the engine.
abstract interface class EngineModule {
  void start(void Function(EngineEvent) emit);

  /// Handles [command] if it belongs to this module; returns `false` otherwise.
  bool handle(EngineCommand command);

  /// Stops the module. May be asynchronous (flushing a worker isolate): the
  /// engine waits for each module, in reverse order, up to [moduleStopTimeout].
  FutureOr<void> stop();
}

/// Builds modules inside the engine isolate. Must be a top-level or static
/// function so it can be sent to the isolate.
typedef EngineModulesFactory<T> = List<EngineModule> Function(T init);

/// What the UI uses from the engine. Implemented by the real isolate and by fakes.
abstract interface class EngineApi {
  Stream<EngineEvent> get events;

  /// Last event received of type [T] (the UI can subscribe after receiving it).
  T? lastEvent<T extends EngineEvent>();
  void send(EngineCommand command);
  Future<void> shutdown();
}

final engineProvider = Provider<EngineApi>(
  (ref) => throw UnimplementedError('engineProvider'),
);

/// The engine could not build or start its modules; it stopped the modules
/// that had started and exited.
class EngineStartupException implements Exception {
  const EngineStartupException(this.message);
  final String message;

  @override
  String toString() => 'Engine startup failed: $message';
}

// ── UI side ────────────────────────────────────────────────────────────────

class _EngineReady extends EngineEvent {
  const _EngineReady(this.commands);
  final SendPort commands;
}

// Strings only: the original error may hold objects that cannot cross isolates.
class _EngineStartFailed extends EngineEvent {
  const _EngineStartFailed(this.error, this.stack);
  final String error;
  final String stack;
}

class _Bootstrap<T> {
  const _Bootstrap(this.events, this.factory, this.init);
  final SendPort events;
  final EngineModulesFactory<T> factory;
  final T init;

  List<EngineModule> build() => factory(init);
}

class IsolateEngine implements EngineApi {
  IsolateEngine._(this._rx) {
    _rx.listen((m) {
      switch (m) {
        case _EngineReady(:final commands):
          _ready.complete(commands);
        case _EngineStartFailed(:final error, :final stack):
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
      _Bootstrap<T>(e._rx.sendPort, factory, init),
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

Future<void> _engineMain<T>(_Bootstrap<T> boot) async {
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
    boot.events.send(_EngineStartFailed('$e', '$s'));
    rx.close();
    return;
  }
  boot.events.send(_EngineReady(rx.sendPort));
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
