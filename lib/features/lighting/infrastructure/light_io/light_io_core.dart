import 'dart:async';
import 'dart:io';

import '../../../devices/devices.dart';
import '../../domain/config/lighting_config.dart';
import 'isolate_light_io.dart';
import 'light_io_command.dart';
import 'light_io_reply.dart';

/// Runs the commands over the drivers, strictly in arrival order.
class LightIoCore {
  /// A driver left `null` belongs to another worker: its commands fail.
  /// [gpuReason] is the open failure when the controller itself is absent.
  LightIoCore({this._ite, this._fury, this._gpu, this.gpuReason});

  final IteController? _ite;
  final FuryController? _fury;
  final GpuController? _gpu;

  /// Last GPU failure reported inside the worker (also sent in replies).
  String? gpuReason;

  Future<void> _chain = Future<void>.value();

  /// Bumped on every priority command: droppable ones captured an older value.
  int _epoch = 0;
  bool _closed = false;

  /// Queues [command] and returns its reply. Never throws.
  Future<LightIoReply> handle(int id, LightIoCommand command) {
    if (command is PriorityIoCommand) _epoch++;
    final epoch = _epoch;
    final reply = _chain.then((_) async {
      if (command is DroppableIoCommand && epoch != _epoch) {
        return LightIoReply(id, false, 0, dropped: true);
      }
      final watch = Stopwatch()..start();
      final ok = await _run(command);
      return LightIoReply(
        id,
        ok,
        watch.elapsedMicroseconds,
        ramReasons: reportsRamReasons(command) ? _reasons() : null,
        gpuReason: reportsGpuReason(command)
            ? _gpu?.disabledReason ?? gpuReason
            : null,
      );
    });
    _chain = reply.then((_) {}, onError: (Object _) {});
    return reply.catchError((Object _) => LightIoReply.failed(id));
  }

  List<String?> _reasons() => [
    _fury?.disabledReason(0),
    _fury?.disabledReason(1),
  ];

  Future<bool> _run(LightIoCommand c) async {
    if (_closed) return false;
    final ite = _ite, fury = _fury, gpu = _gpu;
    try {
      switch (c) {
        case IoInitBoard():
          return ite?.init() ?? false;
        case IoChassis(:final rgb):
          return ite?.streamCase(rgb) ?? false;
        case IoBoardColors(:final rgb):
          if (ite == null) return false;
          return ite.setZoneColors({
            for (final (i, z) in boardZoneIds.indexed)
              z: (rgb[3 * i], rgb[3 * i + 1], rgb[3 * i + 2]),
          });
        case IoZoneEffects(:final zones):
          if (ite == null) return false;
          return await ite.setZoneEffects({
            for (final MapEntry(key: zone, value: config) in zones.entries)
              zone - iteZoneIoShield1: IteHardwareEffect(
                _iteMode(config.mode),
                color: (config.color.r, config.color.g, config.color.b),
                speed: config.speed,
                brightness: config.brightness,
              ),
          });
        case IoBoardOff():
          return ite?.allOff() ?? false;
        case IoRam(:final slot, :final rgb):
          return fury?.setColors(slot, rgb) ?? false;
        case IoRamOff():
          if (fury == null) return false;
          var ok = true;
          for (final slot in fury.activeSlots) {
            ok &= fury.setSingleColor(slot, 0, 0, 0);
          }
          return ok;
        case IoInitGpu():
          if (gpu == null) return false;
          final ok = gpu.init();
          gpuReason = gpu.disabledReason;
          return ok;
        case IoGpuStatic(:final r, :final g, :final b, :final brightness):
          if (gpu == null) return false;
          final ok = gpu.sendEffect(
            effect: GpuEffectCode.staticColor,
            speed: 0,
            brightness: brightness,
            color: GpuRgb(r, g, b),
          );
          gpuReason = gpu.disabledReason;
          return ok;
        case IoGpuEffect(:final config):
          if (gpu == null) return false;
          final effect = GpuEffectCode.byName(config.effect.name);
          if (effect == null) return false;
          // Off does not need speed/brightness/palette; force them to zero so
          // the packet is the same one used by "turn all ARGB off".
          final off = effect == GpuEffectCode.off;
          final ok = gpu.sendEffect(
            effect: effect,
            speed: off ? 0 : config.speed,
            brightness: off ? 0 : config.brightness,
            color: off
                ? GpuRgb.black
                : GpuRgb(config.color.r, config.color.g, config.color.b),
            colors: off
                ? const []
                : [for (final c in config.colors) GpuRgb(c.r, c.g, c.b)],
          );
          gpuReason = gpu.disabledReason;
          return ok;
        case IoGpuOff():
          if (gpu == null) return false;
          final ok = gpu.turnOff();
          gpuReason = gpu.disabledReason;
          return ok;
        case IoInvalidate():
          fury?.invalidate();
          gpu?.invalidate();
          return true;
        case IoClose():
          _closed = true;
          _closeDrivers();
          return true;
      }
    } on Object catch (e, st) {
      // Driver exceptions (safety guards, bus errors) become "unavailable".
      stderr.writeln('lighting io: $e\n$st');
      return false;
    }
  }

  void _closeDrivers() {
    try {
      _ite?.dispose();
    } on Object catch (e, st) {
      stderr.writeln('lighting: ITE close: $e\n$st');
    }
    try {
      _fury?.close();
    } on Object catch (e, st) {
      stderr.writeln('lighting: Fury close: $e\n$st');
    }
    try {
      _gpu?.close();
    } on Object catch (e, st) {
      stderr.writeln('lighting: GPU close: $e\n$st');
    }
  }

  static IteHardwareMode _iteMode(BoardEffectMode m) => switch (m) {
    BoardEffectMode.static => IteHardwareMode.staticColor,
    BoardEffectMode.pulse => IteHardwareMode.pulse,
    BoardEffectMode.flash => IteHardwareMode.flash,
    BoardEffectMode.doubleFlash => IteHardwareMode.doubleFlash,
    BoardEffectMode.colorCycle => IteHardwareMode.colorCycle,
    BoardEffectMode.wave => IteHardwareMode.wave,
  };
}
