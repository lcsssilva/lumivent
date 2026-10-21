import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../devices/devices.dart';
import '../domain/led_layout.dart' show ledsPerFan;
import '../domain/light_device.dart';
import '../domain/light_outputs.dart';
import '../domain/lighting_config.dart';
import '../domain/rgb.dart';
import 'light_io_worker.dart';

/// [LightOutputs] over the devices module drivers: AL V2 hub (a proxy to its
/// worker isolate, shared with monitoring and fans, which is who releases it);
/// the ITE IT5702, Kingston Fury and GPU drivers live in their own I/O workers
/// ([LightIoClient]) because their calls block. Nothing here blocks the engine
/// isolate.
class DeviceLightOutputs implements LightOutputs {
  /// [io] serves the ITE (and the other drivers too when [ramIo]/[gpuIo] are
  /// omitted, as in tests with a single fake worker).
  DeviceLightOutputs(
    this._hub, {
    required LightIoClient io,
    LightIoClient? ramIo,
    LightIoClient? gpuIo,
  }) : _ioClient = io,
       _ramClient = ramIo ?? io,
       _gpuClient = gpuIo ?? io;

  /// Spawns the three I/O workers, ITE, RAM and GPU, each with its own isolate
  /// (they open their drivers inside it). Called inside the engine isolate.
  factory DeviceLightOutputs.open(Alv2HubProxy hub) => DeviceLightOutputs(
    hub,
    io: IsolateLightIo(LightIoKind.board),
    ramIo: IsolateLightIo(LightIoKind.ram),
    gpuIo: IsolateLightIo(LightIoKind.gpu),
  );

  final Alv2HubProxy _hub;
  final LightIoClient _ioClient;
  final LightIoClient _ramClient;
  final LightIoClient _gpuClient;

  /// Set by [close]: no call reaches a driver after this.
  bool _closed = false;

  // ── Fans ────────────────────────────────────────────────────────────────

  @override
  Future<bool> initFans(List<int> quantity) async {
    if (_closed) return false;
    // Queued in the hub worker in this order; the answers are awaited together.
    final results = await Future.wait([
      _hub.disableArgbSync(),
      _hub.setMergeOrder(const [0, 1, 2, 3]),
      _setQuantity(quantity),
    ]);
    return results.every((ok) => ok);
  }

  @override
  Future<bool> setFanQuantity(List<int> quantity) async =>
      !_closed && await _setQuantity(quantity);

  Future<bool> _setQuantity(List<int> quantity) async {
    final results = await Future.wait([
      for (var g = 0; g < alv2Groups; g++) _hub.setQuantity(g, quantity[g]),
    ]);
    return results.every((ok) => ok);
  }

  @override
  Future<bool> sendFanFrames(Map<int, List<Rgb>> frames) => _async(
    // Canvas streaming: fast path (2 ms gap, unpadded, no frame commit).
    () => _hub.streamCanvas(
      alv2ServiceOrder([
        for (final MapEntry(key: group, value: leds) in frames.entries)
          ...alv2CanvasWrites(group, leds.length ~/ ledsPerFan, _flat(leds)),
      ]),
    ),
  );

  @override
  Future<bool> setFanHardware(int group, Alv2HardwareConfig config) =>
      _async(() {
        final writes = switch (config.scope) {
          Alv2Scope.whole => alv2WholeWrites(
            group,
            _effect(_wholeMode(config.mode), config),
          ),
          Alv2Scope.innerOuter => alv2PairWrites(
            group,
            _effect(_ringMode(config.mode, Alv2LightScope.inner), config),
            _effect(_ringMode(config.mode, Alv2LightScope.outer), config),
          ),
        };
        return _hub.sendLighting(writes);
      });

  @override
  bool supportsFanMerge(String mode) => _mergeMode(mode) != null;

  @override
  Future<bool> setFanMergeOrder(List<int> order) async =>
      !_closed && await _hub.setMergeOrder(order);

  @override
  Future<bool> setFanMerge(String mode, Alv2HardwareConfig config) =>
      _async(() {
        final m = _mergeMode(mode);
        if (m == null) return Future.value(false);
        return _hub.sendLighting(alv2MergeWrites(_effect(m, config)));
      });

  @override
  Future<bool> turnFanGroupOff(int group) => _async(
    () => _hub.sendLighting([
      for (final port in [2 * group + 1, 2 * group])
        Alv2PortWrite(
          port: port,
          mode: Alv2LightMode.rainbow.byte,
          brightness: 0x08,
        ),
    ]),
  );

  @override
  Future<bool> turnAllFansOff() => _async(
    // Priority: the off before sleep/shutdown must not wait behind an identify.
    () => _hub.sendLighting(alv2OffWrites(), priority: true),
  );

  @override
  Future<bool> identifyFanGroup(int group, {bool merge = false}) =>
      _async(() => _hub.identify(group, merge: merge));

  // Mode names: `Alv2HardwareConfig.mode` is a base name (`Runway`).

  /// Whole-fan mode; an unknown name (or one from another scope) falls back to
  /// StaticColor so the config never leaves the group undefined.
  Alv2LightMode _wholeMode(String name) {
    final m = Alv2LightMode.byName(_base(name));
    return m != null && m.scope == Alv2LightScope.whole
        ? m
        : Alv2LightMode.staticColor;
  }

  /// `<mode>_Inner` / `<mode>_Outer`. Fallback when the ring has no variant
  /// (for example `PacMan` has only inner): the split of the whole-fan mode
  /// and, as a last resort, StaticColor of that ring.
  Alv2LightMode _ringMode(String name, Alv2LightScope ring) {
    final inner = ring == Alv2LightScope.inner;
    final suffix = inner ? '_Inner' : '_Outer';
    final base = _base(name);
    final m = Alv2LightMode.byName('$base$suffix');
    if (m != null) return m;
    final whole = Alv2LightMode.byName(base);
    return (inner ? whole?.splitInner : whole?.splitOuter) ??
        (inner
            ? Alv2LightMode.staticColorInner
            : Alv2LightMode.staticColorOuter);
  }

  Alv2LightMode? _mergeMode(String name) {
    final m = Alv2LightMode.byName('${_base(name)}_Merge');
    return m != null && m.scope == Alv2LightScope.merge ? m : null;
  }

  static String _base(String name) =>
      name.replaceFirst(RegExp(r'_(Inner|Outer|Merge)$'), '');

  Alv2Effect _effect(Alv2LightMode mode, Alv2HardwareConfig c) => Alv2Effect(
    mode,
    // Exactly as many colors as the mode lets the user pick; missing ones
    // come from the defaults, as in the UI.
    colors: [
      for (var i = 0; i < mode.colorCount; i++) ...[
        for (final v in _colorAt(c, i)) v,
      ],
    ],
    speedLevel: c.speed,
    direction: c.directionLeft ? 1 : 0,
    brightnessLevel: c.brightness,
  );

  static List<int> _colorAt(Alv2HardwareConfig c, int i) {
    final rgb = i < c.colors.length
        ? c.colors[i]
        : Alv2HardwareConfig.defaultColors[i %
              Alv2HardwareConfig.defaultColors.length];
    return [rgb.r, rgb.g, rgb.b];
  }

  // ── ITE and Fury (I/O worker) ───────────────────────────────────────────

  @override
  Future<bool> initBoard() => _io(const IoInitBoard());

  @override
  Future<bool> sendChassis(List<Rgb> leds) => _io(IoChassis(_bytes(leds)));

  @override
  Future<bool> sendBoardColors(List<Rgb> zones) =>
      _io(IoBoardColors(_bytes(zones)));

  @override
  Future<bool> setBoardZones(Map<int, BoardZoneConfig> zones) =>
      _io(IoZoneEffects(Map.of(zones)));

  @override
  Future<bool> turnBoardOff() => _io(const IoBoardOff());

  @override
  Future<bool> sendRam(int slot, List<Rgb> leds) =>
      _io(IoRam(slot, _bytes(leds)), client: _ramClient);

  @override
  Future<bool> turnRamOff() => _io(const IoRamOff(), client: _ramClient);

  // ── GPU (I/O worker) ────────────────────────────────────────────────────

  @override
  Future<bool> initGpu() => _io(const IoInitGpu(), client: _gpuClient);

  @override
  Future<bool> sendGpuColor(Rgb color, {int brightness = 10}) => _io(
    IoGpuStatic(color.r, color.g, color.b, brightness),
    client: _gpuClient,
  );

  @override
  Future<bool> setGpuHardware(GpuHardwareConfig config) =>
      _io(IoGpuEffect(config), client: _gpuClient);

  @override
  Future<bool> turnGpuOff() => _io(const IoGpuOff(), client: _gpuClient);

  // ── Common ──────────────────────────────────────────────────────────────

  /// Last reasons reported by the worker (slot 0/1); `null` = usable.
  List<String?> _ramReasons = const [null, null];

  /// Why the GPU is unusable (missing adapter, permission, failed identity
  /// read, SSID mismatch); `null` = usable.
  String? _gpuReason;

  @override
  String? blockedReason(LightDeviceId id) => switch (id) {
    LightDeviceId.ram1 => _ramReasons[0],
    LightDeviceId.ram2 => _ramReasons[1],
    LightDeviceId.gpu => _gpuReason,
    _ => null,
  };

  @override
  void invalidate() {
    if (_closed) return;
    for (final client in {_ramClient, _gpuClient}) {
      unawaited(_io(const IoInvalidate(), client: client));
    }
  }

  /// Orderly shutdown: each worker closes its drivers after what it is
  /// running, then the isolate is released; after [closeTimeout] it is killed.
  /// Completes when all are done (or timed out).
  @override
  Future<void> close() {
    if (_closed) return Future.value();
    _closed = true;
    final clients = {_ioClient, _ramClient, _gpuClient};
    return Future.wait([
      for (final c in clients)
        _io(
          const IoClose(),
          force: true,
          client: c,
        ).timeout(closeTimeout, onTimeout: () => false).whenComplete(c.dispose),
    ]);
  }

  /// How long [close] waits for a worker before killing it.
  static const closeTimeout = Duration(seconds: 1);

  Future<bool> _io(
    LightIoCommand command, {
    bool force = false,
    LightIoClient? client,
  }) async {
    if (_closed && !force) return false;
    try {
      final reply = await (client ?? _ioClient).request(command);
      final reasons = reply.ramReasons;
      if (reasons != null) _ramReasons = reasons;
      final gpuReason = reply.gpuReason;
      if (gpuReason != null ||
          command is IoInitGpu ||
          command is IoGpuStatic ||
          command is IoGpuEffect ||
          command is IoGpuOff ||
          command is IoInvalidate) {
        _gpuReason = gpuReason;
      }
      return reply.ok;
    } on Object catch (e) {
      stderr.writeln('lighting: $e');
      return false;
    }
  }

  static Uint8List _bytes(List<Rgb> leds) {
    final out = Uint8List(leds.length * 3);
    for (var i = 0; i < leds.length; i++) {
      out[3 * i] = leds[i].r;
      out[3 * i + 1] = leds[i].g;
      out[3 * i + 2] = leds[i].b;
    }
    return out;
  }

  static List<int> _flat(List<Rgb> leds) => [
    for (final c in leds) ...[c.r, c.g, c.b],
  ];

  Future<bool> _async(Future<bool> Function() op) async {
    if (_closed) return false;
    try {
      return await op();
    } on Object catch (e) {
      stderr.writeln('lighting: $e');
      return false;
    }
  }
}
