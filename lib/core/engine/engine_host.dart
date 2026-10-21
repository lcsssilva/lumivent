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

// ── UI side ────────────────────────────────────────────────────────────────

class _EngineReady extends EngineEvent {
  const _EngineReady(this.commands);
  final SendPort commands;
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
        case EngineEvent():
          _last[m.runtimeType] = m;
          _events.add(m);
        case [final error, final stack]:
          // Unhandled engine error (Isolate.spawn onError).
          stderr.writeln('engine: $error\n$stack');
      }
    });
  }

  final ReceivePort _rx;
  final _ready = Completer<SendPort>();
  final _events = StreamController<EngineEvent>.broadcast();
  final _last = <Type, EngineEvent>{};
  late final Isolate _isolate;
  late final SendPort _commands;

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
    );
    e._commands = await e._ready.future;
    return e;
  }

  @override
  void send(EngineCommand command) => _commands.send(command);

  @override
  Future<void> shutdown() async {
    final stopped = events.firstWhere((e) => e is EngineStopped);
    send(const ShutdownEngine());
    try {
      await stopped.timeout(const Duration(seconds: 3));
    } on TimeoutException {
      _isolate.kill(priority: Isolate.immediate);
    }
    _rx.close();
    await _events.close();
  }
}

// ── Engine side ────────────────────────────────────────────────────────────

Future<void> _engineMain<T>(_Bootstrap<T> boot) async {
  final rx = ReceivePort('lumivent-engine-commands');
  boot.events.send(_EngineReady(rx.sendPort));
  final modules = boot.build();
  for (final m in modules) {
    m.start(boot.events.send);
  }
  await for (final cmd in rx) {
    if (cmd is ShutdownEngine) {
      for (final m in modules.reversed) {
        try {
          await Future.sync(m.stop).timeout(moduleStopTimeout);
        } catch (e, s) {
          stderr.writeln('engine: ${m.runtimeType} stop failed: $e\n$s');
        }
      }
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
