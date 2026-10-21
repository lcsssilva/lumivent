import 'dart:async';
import 'dart:io';

import '../../../core/engine/engine_host.dart';
import '../domain/frame_composer.dart';
import '../domain/hardware_equivalents.dart';
import '../domain/hardware_timing.dart';
import '../domain/light_device.dart';
import '../domain/light_outputs.dart';
import '../domain/lighting_config.dart';
import '../domain/power_events.dart';
import '../domain/rgb.dart';
import 'lighting_engine_commands.dart';
import 'lighting_messages.dart';

/// Lighting module part that runs in the engine.
///
/// * Frame loop at the preferred FPS: [composeFrame] and send only what
///   changed since the last send (plus a safety resend every [resendEvery]).
///   Each family (fans, ITE, RAM, GPU) has its own lane: at most one frame in
///   flight, composed at the moment it is sent, and the next one starts as soon
///   as the previous one returns (at least [fanFrameGap] / [iteFrameGap] /
///   [ramFrameGap] / [gpuFrameGap] after its start). The ITE, RAM and GPU
///   writes block, so they run in I/O workers and the tick never waits for I/O.
/// * Latency compensation: the engine measures how long each family takes to
///   send (EMA, see [latencyOf]) and composes each family for `t + latency`,
///   so fans, ITE, RAM and GPU show the same phase of the effect at the same
///   time.
/// * Hardware modes (fan modes, merge, motherboard effects) are sent at
///   startup and whenever the relevant part of the config changes. The global
///   brightness only affects canvas/fixed devices: hardware modes carry their
///   own brightness.
/// * "Turn all ARGB off" and suspend/shutdown (when `offOnSleep`) apply the
///   off sequence on every driver and stop the loop; turning back on redoes
///   the driver init and resends the hardware modes.
/// * [stop] stops timers and the power watcher but does **not** turn the LEDs
///   off: they stay as they were when the app exits.
///
/// Stop order: the engine stops modules in reverse list order, and the AL V2
/// hub is released by monitoring. `buildEngineModules` lists lighting last,
/// so it stops first (no frame after the hub closes), then fans (final safe
/// duty), then monitoring (releases the hub).
class LightingEngineModule implements EngineModule {
  LightingEngineModule({
    required this._openOutputs,
    required this._openWatcher,
    required LightingConfig initial,
    int fps = defaultFps,
    this.now = DateTime.now,
    this.resendEvery = const Duration(seconds: 5),
    this.retryEvery = const Duration(seconds: 5),
    this.fanFrameGap = alv2SafeStreamGap,
    this.iteFrameGap = const Duration(milliseconds: 33),
    this.ramFrameGap = const Duration(milliseconds: 66),
    this.gpuFrameGap = const Duration(milliseconds: 120),
    this.gpuRetryMax = const Duration(minutes: 5),
  }) : _user = initial,
       _fps = fps.clamp(minFps, maxFps) {
    _config = _derive(initial);
  }

  static const defaultFps = 30;
  static const minFps = 5;
  static const maxFps = 120;

  /// Tolerance of the frame-gap check when a tick (not the chain) asks.
  static const tickSlack = Duration(milliseconds: 4);

  /// Weight of the newest sample in the latency EMA.
  static const latencyAlpha = 0.25;

  /// Latency bounds, in milliseconds.
  static const minLatencyMs = 0.0;
  static const maxLatencyMs = 150.0;

  static const _fanIds = {
    LightDeviceId.alv2Group1,
    LightDeviceId.alv2Group2,
    LightDeviceId.alv2Group3,
  };

  /// Opens the drivers inside the engine isolate.
  final LightOutputs Function() _openOutputs;
  final PowerWatcher Function() _openWatcher;

  /// Clock (injectable in tests).
  final DateTime Function() now;

  /// Safety resend of an unchanged frame (a device may lose its state).
  final Duration resendEvery;

  /// Wait before retrying a device that failed (or was absent).
  final Duration retryEvery;

  /// Minimum interval between AL V2 canvas frames: faster streaming disturbs
  /// the fan speed ([alv2SafeStreamGap]).
  final Duration fanFrameGap;

  /// Minimum interval between ITE frame starts (capped by the tick period).
  final Duration iteFrameGap;

  /// Minimum interval between Kingston Fury frame starts (~15 fps): every
  /// write is several SMBus transactions.
  final Duration ramFrameGap;

  /// Minimum interval between GPU effect writes. The controller itself also
  /// sleeps 120 ms after each `0x12`; this lane keeps the engine from queueing
  /// animations faster than that.
  final Duration gpuFrameGap;

  /// Longest wait between GPU identification attempts. Each failed `init`
  /// doubles the wait from [retryEvery] up to this: on kernels where the OEM
  /// read fails (EIO) the attempt would otherwise write `10 01` every 5 s for
  /// as long as the app runs. Resume/restore start again from [retryEvery].
  final Duration gpuRetryMax;

  // [_user] is the config as the user set it; [_config] is what the engine
  // acts on: the same, with Canvas devices turned into hardware devices when
  // [withAutoHardware] finds a firmware equivalent of the effect.
  LightingConfig _user;
  late LightingConfig _config;
  int _fps;
  late void Function(EngineEvent) _emit;
  LightOutputs? _outputs;
  PowerWatcher? _watcher;
  Timer? _timer;
  Timer? _retryTimer;
  Timer? _hwResendTimer;
  bool _stopped = false;
  late DateTime _startedAt;

  /// Hardware modes are sent a second time this long after a change: the G2
  /// group was seen staying dark intermittently when the mode was applied once
  /// (phase 4 checklist, step 8).
  static const hardwareResendDelay = Duration(seconds: 1);

  /// Engine time (seconds, see [_seconds]) at which the firmware `Breathing`
  /// started, or `null` when the fans are not running it. The canvas devices
  /// are composed against this instant so they breathe in phase (see
  /// [breathingEffectTime]).
  double? _breathingSince;

  /// Colors sampled from the current HTML effect (UI isolate), and the
  /// effect they belong to. Frames from another effect are stale and dropped.
  Map<LightDeviceId, List<Rgb>>? _pixels;
  String? _pixelsEffect;

  // Measured send time per family in ms (EMA), starting from typical values.
  final _latencyMs = <OutputFamily, double>{
    OutputFamily.fans: 45,
    OutputFamily.ite: 1,
    OutputFamily.ram: 10,
    // Write only: the controller's mandatory 120 ms pause is subtracted in
    // _leadSeconds because the GPU shows the effect when the write lands.
    OutputFamily.gpu: 125,
  };

  // One lane per family: frame in flight + chaining timer.
  final _lanes = {for (final f in OutputFamily.values) f: _Lane()};

  /// Bumped when the off sequence or a re-init starts: replies of frames sent
  /// before it no longer describe the hardware.
  int _ioEpoch = 0;

  // Serial queue of async work (startup, config, off/restore, retry).
  Future<void> _queue = Future<void>.value();
  int _jobs = 0;
  bool _reconcilePending = false;

  // Off state: [_isOff] means the off sequence was applied.
  bool _powerOff = false;
  bool _isOff = false;

  // Driver families. A failed write drops the family until the retry re-inits it.
  bool _fansReady = false;
  bool _boardReady = false;
  bool _gpuReady = false;
  final _ramDown = <LightDeviceId>{};
  final _ramRetryAt = <LightDeviceId, DateTime>{};
  DateTime _nextRetry = DateTime.fromMillisecondsSinceEpoch(0);

  /// GPU identification backoff (see [gpuRetryMax]).
  int _gpuInitFailures = 0;
  DateTime? _gpuRetryAt;

  // What the hardware currently holds.
  List<int>? _appliedQty;

  /// Merge order the hub holds; `initFans` resets it to the default.
  List<int>? _appliedMergeOrder;
  final _applied = <Object, Object?>{};
  final _last = <LightDeviceId, _Sent>{};
  _GpuSent? _gpuLast;
  bool _fanMerged = false;

  // FPS and status.
  int _frames = 0;
  late DateTime _fpsWindowStart;
  double _measuredFps = 0;
  LightingStatus? _lastStatus;
  Map<OutputFamily, LoopStats> _loops = const {};
  DateTime _lastFpsEmit = DateTime.fromMillisecondsSinceEpoch(0);

  bool get _shouldBeOff => _config.argbOff || _powerOff;

  /// Current send-time estimate of [family] (EMA of the measured durations,
  /// clamped to 0-150 ms).
  Duration latencyOf(OutputFamily family) =>
      Duration(microseconds: (_latencyMs[family]! * 1000).round());

  void _observe(OutputFamily family, Duration took) {
    final ms = took.inMicroseconds / 1000;
    final next =
        _latencyMs[family]! + latencyAlpha * (ms - _latencyMs[family]!);
    _latencyMs[family] = next.clamp(minLatencyMs, maxLatencyMs);
  }

  /// Delay of the AL V2 firmware between receiving a canvas frame and showing
  /// it. Measured on hardware (2026-10-19, `tool/hw_test_fase4.dart sync`):
  /// with the fans streamed first, the case/board/RAM had to be sent ~150 ms
  /// after the fan send completed for both to change at the same instant.
  static const fanDisplayLatencyMs = 150.0;

  /// How far ahead of "now" a family must be composed. Synchronous outputs
  /// (ITE, RAM) show the colors when the send ends, so the lead is the send
  /// time. The fans show a frame only [fanDisplayLatencyMs] after the whole
  /// send, so their lead is the send time plus that delay. The GPU applies the
  /// effect when the write lands, before the controller's 120 ms pause, so
  /// only the write part of its measured send time is a lead.
  double _leadSeconds(OutputFamily family) {
    final ms = _latencyMs[family]!;
    if (family == OutputFamily.fans) {
      return (ms + fanDisplayLatencyMs) / 1000;
    }
    if (family == OutputFamily.gpu) {
      return (ms - gpuFrameGap.inMilliseconds).clamp(0, 50) / 1000;
    }
    return ms / 1000;
  }

  // ── EngineModule ────────────────────────────────────────────────────────

  @override
  void start(void Function(EngineEvent) emit) {
    _emit = emit;
    _startedAt = _fpsWindowStart = now();
    _breathingSince = null;
    _config = _derive(_user);
    _emit(ArgbStateChanged(_config.argbOff));
    _emitStatus();
    unawaited(_startWatcher());
    unawaited(_run(_startup));
  }

  @override
  bool handle(EngineCommand command) {
    switch (command) {
      case SetArgbOff(:final off):
        _setConfig(_config.copyWith(argbOff: off));
      case SetLightingConfig(:final config):
        _setConfig(config);
      case SetLightingFps(:final fps):
        final next = fps.clamp(minFps, maxFps);
        if (next != _fps) {
          _fps = next;
          _timer?.cancel();
          _timer = null;
          _syncTimer();
        }
      case SetHtmlEffectFrame(:final effectId, :final pixels):
        if (effectId == _config.effectId) {
          _pixelsEffect = effectId;
          _pixels = pixels;
        }
      case IdentifyFanGroup(:final group):
        _identify(group);
      default:
        return false;
    }
    return true;
  }

  @override
  Future<void> stop() async {
    _stopped = true;
    try {
      _timer?.cancel();
      _timer = null;
      _retryTimer?.cancel();
      _retryTimer = null;
      _hwResendTimer?.cancel();
      _hwResendTimer = null;
      for (final lane in _lanes.values) {
        lane.timer?.cancel();
        lane.timer = null;
      }
    } on Object catch (e) {
      _log('timers: $e');
    }
    try {
      final watcher = _watcher;
      if (watcher != null) {
        unawaited(watcher.stop().catchError((Object e) => _log('watcher: $e')));
      }
    } on Object catch (e) {
      _log('watcher: $e');
    }
    try {
      await _outputs?.close();
    } on Object catch (e) {
      _log('outputs: $e');
    }
  }

  // ── Async work ──────────────────────────────────────────────────────────

  Future<void> _run(Future<void> Function() job) {
    _jobs++;
    final done = _queue
        .then((_) async {
          if (_stopped) return;
          try {
            await job();
          } on Object catch (e) {
            _log('$e');
          }
        })
        .whenComplete(() => _jobs--);
    return _queue = done;
  }

  Future<void> _startup() async {
    _outputs = _openOutputs();
    if (_shouldBeOff) {
      await _turnOff();
    } else {
      await _initDevices();
      if (_stopped) return;
      await _reconcile();
    }
    if (_stopped) return;
    _syncTimer();
  }

  Future<void> _startWatcher() async {
    try {
      final watcher = _watcher = _openWatcher();
      await watcher.start(
        beforeSleep: _powerDown,
        afterResume: _powerUp,
        beforeShutdown: _powerDown,
      );
      if (_stopped) await watcher.stop();
    } on Object catch (e) {
      _log('power watcher: $e');
    }
  }

  /// Suspend/shutdown: turn everything off and wait (logind holds the system).
  Future<void> _powerDown() async {
    try {
      if (!_config.offOnSleep || _stopped) return;
      _powerOff = true;
      _syncTimer();
      await _run(_turnOff);
    } on Object catch (e) {
      _log('before sleep: $e');
    }
  }

  /// Resume: USB may have been reset during suspend, so the devices can lose
  /// their hardware mode even when `offOnSleep` is off. Always re-init the
  /// drivers, resend hardware modes and force the next canvas/static frames.
  void _powerUp() {
    if (_stopped) return;
    _powerOff = false;
    if (_config.argbOff) return;
    unawaited(_run(_reinit));
  }

  // ── Config ──────────────────────────────────────────────────────────────

  void _setConfig(LightingConfig nextUser) {
    if (nextUser == _user) return;
    _user = nextUser;
    if (_trace) {
      final fans = [
        for (final id in LightDeviceId.values.where((d) => d.isFan))
          '${id.hubGroup}:${nextUser.device(id).enabled ? 'on' : 'off'}/'
              '${nextUser.device(id).mode.name}',
      ];
      _traceFans(
        'config effect ${nextUser.effectId} auto ${nextUser.autoHardware} '
        'merge ${nextUser.alv2Merge} fans ${fans.join(' ')}',
      );
    }
    final next = _derive(nextUser);
    if (next == _config) {
      _syncTimer();
      return;
    }
    final prev = _config;
    _config = next;
    if (prev.effectId != next.effectId) {
      _pixels = null;
      _pixelsEffect = null;
    }
    if (!_usesFirmwareBreathing(next)) _breathingSince = null;
    if (prev.argbOff != next.argbOff) {
      _emit(ArgbStateChanged(next.argbOff));
      unawaited(_run(next.argbOff ? _turnOff : _restore));
    } else if (!_shouldBeOff) {
      _scheduleReconcile();
    }
    _syncTimer();
  }

  /// The config the engine acts on for the user config [user]: the firmware
  /// equivalents of [withAutoHardware].
  LightingConfig _derive(LightingConfig user) => withAutoHardware(user);

  /// Whether any enabled fan group runs the firmware `Breathing` for the
  /// current effect: only then the canvas devices follow the firmware clock.
  bool _usesFirmwareBreathing(LightingConfig c) {
    if (c.effectId != 'breathing') return false;
    for (final id in LightDeviceId.values.where((d) => d.isFan)) {
      final d = c.device(id);
      if (d.enabled &&
          d.mode == LightMode.hardware &&
          c.alv2Hardware[id.hubGroup!].mode == 'Breathing') {
        return true;
      }
    }
    return false;
  }

  /// Several config commands in a row (pointer moves) become one job, which
  /// reads the latest config when it runs.
  void _scheduleReconcile() {
    if (_reconcilePending) return;
    _reconcilePending = true;
    unawaited(_run(_reconcile));
  }

  // ── Init, off, restore ──────────────────────────────────────────────────

  /// Inits the families that are not ready (startup, restore, retry).
  Future<void> _initDevices() async {
    final out = _outputs;
    if (out == null) return;
    if (!_fansReady) {
      final qty = _quantity(_config);
      final ok = await out.initFans(qty);
      if (_stopped) return;
      if (ok) {
        _appliedQty = qty;
        _appliedMergeOrder = LightingConfig.defaultMergeOrder;
        _forgetFans();
        _fansReady = true;
      } else {
        _nextRetry = now().add(retryEvery);
      }
    }
    if (!_boardReady) {
      final ok = await out.initBoard();
      if (_stopped) return;
      if (ok) {
        _forgetBoard();
        _boardReady = true;
      } else {
        _nextRetry = now().add(retryEvery);
      }
    }
    final gpuRetryAt = _gpuRetryAt;
    if (!_gpuReady && (gpuRetryAt == null || !now().isBefore(gpuRetryAt))) {
      final ok = await out.initGpu();
      if (_stopped) return;
      if (ok) {
        _forgetGpu();
        _gpuReady = true;
        _resetGpuBackoff();
      } else {
        _gpuInitFailures++;
        _gpuRetryAt = now().add(_gpuBackoff());
      }
    }
    _emitStatus();
  }

  /// [retryEvery] doubled per consecutive failed GPU `init`, capped.
  Duration _gpuBackoff() {
    final shift = (_gpuInitFailures - 1).clamp(0, 20);
    final wait = retryEvery * (1 << shift);
    return wait > gpuRetryMax ? gpuRetryMax : wait;
  }

  void _resetGpuBackoff() {
    _gpuInitFailures = 0;
    _gpuRetryAt = null;
  }

  Future<void> _turnOff() async {
    final out = _outputs;
    if (out == null || _isOff || !_shouldBeOff) return;
    _isOff = true;
    _ioEpoch++;
    _syncTimer();
    // The offs go out at once; the workers drop the ITE/RAM/GPU frames that
    // have not started, so only the one being written is ahead of them.
    final fansOffF = out.turnAllFansOff();
    final boardOffF = out.turnBoardOff();
    final ramOffF = out.turnRamOff();
    final gpuOffF = out.turnGpuOff();
    final fansOff = await fansOffF;
    final boardOff = await boardOffF;
    final ramOk = await ramOffF;
    final gpuOff = await gpuOffF;
    if (_stopped) return;
    _fansReady = fansOff;
    _boardReady = boardOff;
    _gpuReady = gpuOff;
    _ramDown
      ..clear()
      ..addAll(ramOk ? const [] : [LightDeviceId.ram1, LightDeviceId.ram2]);
    _forgetFans();
    _forgetBoard();
    _forgetGpu();
    _last.clear();
    _breathingSince = null;
    _pixels = null;
    _pixelsEffect = null;
    _emitStatus();
  }

  Future<void> _restore() async {
    if (!_isOff) return;
    await _reinit();
  }

  /// Re-inits the drivers and resends everything the hardware should hold.
  Future<void> _reinit() async {
    final out0 = _outputs;
    if (out0 == null || _shouldBeOff) return;
    _isOff = false;
    _ioEpoch++;
    _last.clear();
    _breathingSince = null;
    _pixels = null;
    _pixelsEffect = null;
    _config = _derive(_user);
    _fansReady = false;
    _boardReady = false;
    _gpuReady = false;
    _ramDown.clear();
    _ramRetryAt.clear();
    _gpuLast = null;
    // Resume/restore may have fixed the bus: identify the GPU right away.
    _resetGpuBackoff();
    // The drivers' caches no longer reflect the hardware (suspend, turn-off).
    out0.invalidate();
    await _initDevices();
    if (_stopped) return;
    await _reconcile();
    if (_stopped) return;
    _syncTimer();
  }

  void _forgetFans() {
    for (final id in LightDeviceId.values.where((d) => d.isFan)) {
      _applied.remove(id);
      _last.remove(id);
    }
    _applied
      ..remove(_mergeKey)
      ..remove(_group0Key);
    _fanMerged = false;
  }

  void _forgetBoard() {
    for (final z in boardZoneIds) {
      _applied.remove(z);
    }
    _last
      ..remove(LightDeviceId.motherboard)
      ..remove(LightDeviceId.chassis);
  }

  void _forgetGpu() {
    _applied.remove(LightDeviceId.gpu);
    _last.remove(LightDeviceId.gpu);
    _gpuLast = null;
  }

  // ── Hardware modes ──────────────────────────────────────────────────────

  static const _mergeKey = 'merge';
  static const _group0Key = 'group0';

  List<int> _quantity(LightingConfig c) => [0, ...c.fanQuantity.skip(1)];

  /// Merge needs: the toggle on, a merge variant of the mode, at least one
  /// enabled fan group, and every enabled group in hardware mode. Otherwise it
  /// is ignored and the groups follow their own modes. Disabled groups inside
  /// an active merge cannot be turned off separately (the merge covers all
  /// ports) and receive no canvas frames.
  bool _mergeWanted(LightingConfig c, LightOutputs out) {
    if (!c.alv2Merge || !out.supportsFanMerge(c.alv2MergeMode)) return false;
    // Judged on the user's modes: groups that only run a derived firmware
    // mode do not turn the merge on.
    final enabled = [
      for (final id in LightDeviceId.values)
        if (id.isFan && _user.device(id).enabled) _user.device(id),
    ];
    return enabled.isNotEmpty &&
        enabled.every((d) => d.mode == LightMode.hardware);
  }

  /// Compares the config with what the hardware holds and sends the
  /// difference. Idempotent. A failure drops the family so the retry redoes it.
  ///
  /// With [hardwareResend] the hardware signatures are forgotten first, so the
  /// modes are written again even though the config did not change (see
  /// [hardwareResendDelay]).
  Future<void> _reconcile({bool hardwareResend = false}) async {
    _reconcilePending = false;
    final out = _outputs;
    if (out == null || _shouldBeOff) return;
    if (hardwareResend) _forgetHardwareModes();
    var hardware = false;
    try {
      if (_fansReady) {
        hardware = await _reconcileFans(_config, out) || hardware;
      }
      if (_stopped) return;
      if (_boardReady) {
        hardware = await _reconcileBoard(_config, out) || hardware;
      }
      if (_stopped) return;
      if (_gpuReady) {
        hardware = await _reconcileGpu(_config, out) || hardware;
      }
    } finally {
      _emitStatus();
      _syncTimer();
    }
    if (hardware && !hardwareResend) _scheduleHardwareResend();
  }

  /// Forgets only the hardware-mode signatures, keeping quantities and canvas
  /// frames: the next reconcile writes the modes again.
  void _forgetHardwareModes() {
    for (final id in LightDeviceId.values.where((d) => d.isFan)) {
      _applied.remove(id);
    }
    _applied.remove(_mergeKey);
    for (final z in boardZoneIds) {
      _applied.remove(z);
    }
    _applied.remove(LightDeviceId.gpu);
  }

  /// Sends the hardware modes once more [hardwareResendDelay] after a change.
  void _scheduleHardwareResend() {
    if (_stopped || _hwResendTimer != null) return;
    _hwResendTimer = Timer(hardwareResendDelay, () {
      _hwResendTimer = null;
      if (_stopped || _shouldBeOff || _outputs == null) return;
      unawaited(_run(() => _reconcile(hardwareResend: true)));
    });
  }

  bool _changed(Object key, Object? sig) =>
      !_applied.containsKey(key) || _applied[key] != sig;

  /// Returns whether a hardware mode (merge or group mode) was written.
  Future<bool> _reconcileFans(LightingConfig c, LightOutputs out) async {
    var sent = false;
    final qty = _quantity(c);
    final appliedQty = _appliedQty;
    if (appliedQty == null || !_sameInts(appliedQty, qty)) {
      // The service resends every port after a quantity change (AL-V2 §4).
      final ok = await out.setFanQuantity(qty);
      if (_stopped) return sent;
      if (!ok) {
        _fansDown();
        return sent;
      }
      _appliedQty = qty;
      _forgetFans();
    }

    final merged = _mergeWanted(c, out);
    final appliedOrder = _appliedMergeOrder;
    if (merged &&
        (appliedOrder == null || !_sameInts(appliedOrder, c.alv2MergeOrder))) {
      final ok = await out.setFanMergeOrder(c.alv2MergeOrder);
      if (_stopped) return sent;
      if (!ok) {
        _fansDown();
        return sent;
      }
      _appliedMergeOrder = c.alv2MergeOrder;
      // The effect is sent again so it starts on the new path.
      _applied.remove(_mergeKey);
    }
    final mergeSig = merged
        ? ('merge', c.alv2MergeMode, c.alv2Hardware[0])
        : null;
    if (_changed(_mergeKey, mergeSig)) {
      // The merge config lives in the unused group-0 slot of the hardware list.
      if (merged) {
        final ok = await out.setFanMerge(c.alv2MergeMode, c.alv2Hardware[0]);
        if (_stopped) return sent;
        if (!ok) {
          _fansDown();
          return sent;
        }
        sent = true;
        _traceFans('merge ${c.alv2MergeMode} order ${c.alv2MergeOrder}');
      } else {
        _traceFans('merge off');
      }
      _applied[_mergeKey] = mergeSig;
    }
    _fanMerged = merged;

    // Hub group 0 is empty and always off, except port 0 inside a merge.
    final g0 = merged ? 'merge' : 'off';
    if (_changed(_group0Key, g0)) {
      if (!merged) {
        final ok = await out.turnFanGroupOff(0);
        if (_stopped) return sent;
        if (!ok) {
          _fansDown();
          return sent;
        }
        _traceFans('fan group 0 off');
      }
      _applied[_group0Key] = g0;
    }

    for (final id in LightDeviceId.values.where((d) => d.isFan)) {
      final d = c.device(id);
      final g = id.hubGroup!;
      final (String, Alv2HardwareConfig?) sig = merged
          ? ('merged', null)
          : d.mode != LightMode.hardware
          ? ('frame', null)
          : !d.enabled
          ? ('off', null)
          : ('mode', c.alv2Hardware[g]);
      if (!_changed(id, sig)) continue;
      _last.remove(id);
      final ok = switch (sig.$1) {
        'off' => await out.turnFanGroupOff(g),
        'mode' => await out.setFanHardware(g, sig.$2!),
        _ => true,
      };
      if (_stopped) return sent;
      if (!ok) {
        _fansDown();
        return sent;
      }
      if (sig.$1 != 'mode') _traceFans('fan group $g ${sig.$1}');
      if (sig.$1 == 'mode') {
        sent = true;
        final m = sig.$2!;
        _traceFans(
          'fan group $g ${m.mode} speed ${m.speed} brightness ${m.brightness} '
          'left ${m.directionLeft} colors '
          '${m.colors.take(2).map((c) => c.toHex()).join(',')}',
        );
        // A Breathing mode starts its own clock now: the canvas follows it.
        if (sig.$2!.mode == 'Breathing' && c.effectId == 'breathing') {
          _breathingSince = _seconds(now());
        }
      }
      _applied[id] = sig;
    }
    return sent;
  }

  void _traceFans(String what) {
    if (_trace) {
      stderr.writeln('lighting: ${_seconds(now()).toStringAsFixed(3)} s $what');
    }
  }

  /// Returns whether any zone effect was written.
  Future<bool> _reconcileBoard(LightingConfig c, LightOutputs out) async {
    final d = c.device(LightDeviceId.motherboard);
    // Zones whose hardware effect changed go out in a single batch.
    final batch = <int, BoardZoneConfig>{};
    final sigs = <int, Object?>{};
    for (final z in boardZoneIds) {
      final (String, BoardZoneConfig?) sig = d.mode != LightMode.hardware
          ? ('frame', null)
          : !d.enabled
          ? ('off', null)
          : ('mode', c.boardZones[z]);
      if (!_changed(z, sig)) continue;
      _last.remove(LightDeviceId.motherboard);
      switch (sig.$1) {
        case 'off':
          batch[z] = const BoardZoneConfig(
            mode: BoardEffectMode.static,
            color: Rgb.black,
          );
          sigs[z] = sig;
        case 'mode':
          batch[z] = sig.$2!;
          sigs[z] = sig;
        default:
          _applied[z] = sig;
      }
    }
    if (batch.isEmpty) return false;
    final ok = await out.setBoardZones(batch);
    if (_stopped) return false;
    if (!ok) {
      _boardDown();
      return false;
    }
    _applied.addAll(sigs);
    return true;
  }

  void _fansDown() {
    _fansReady = false;
    _forgetFans();
    _nextRetry = now().add(retryEvery);
    _syncRetry();
    _emitStatus();
  }

  /// Returns whether a GPU hardware effect was written.
  Future<bool> _reconcileGpu(LightingConfig c, LightOutputs out) async {
    final d = c.device(LightDeviceId.gpu);
    final (String, GpuHardwareConfig?) sig = d.mode != LightMode.hardware
        ? ('frame', null)
        : !d.enabled
        ? ('off', null)
        : ('mode', c.gpuHardware);
    if (!_changed(LightDeviceId.gpu, sig)) return false;
    // Frame mode must resend its color on the next tick; hardware/off must not
    // be considered already applied by the old frame.
    _gpuLast = null;
    var ok = true;
    var hardware = false;
    switch (sig.$1) {
      case 'off':
        ok = await out.turnGpuOff();
      case 'mode':
        ok = await out.setGpuHardware(sig.$2!);
        hardware = true;
      default:
        break;
    }
    if (_stopped) return false;
    if (!ok) {
      _gpuDown();
      return false;
    }
    _applied[LightDeviceId.gpu] = sig;
    return hardware;
  }

  void _boardDown() {
    _boardReady = false;
    _forgetBoard();
    _nextRetry = now().add(retryEvery);
    _syncRetry();
    _emitStatus();
  }

  void _gpuDown() {
    _gpuReady = false;
    _forgetGpu();
    _nextRetry = now().add(retryEvery);
    _syncRetry();
    _emitStatus();
  }

  void _identify(int group) {
    final out = _outputs;
    final id = LightDeviceId.forHubGroup(group);
    if (out == null || id == null || !_fansReady || _shouldBeOff) return;
    final merge = _fanMerged;
    unawaited(
      out
          .identifyFanGroup(group, merge: merge)
          .then((_) {
            // The ping overwrote the effect: send it again (merge included).
            _applied.remove(id);
            _last.remove(id);
            if (merge) _applied.remove(_mergeKey);
            if (!_stopped && !_shouldBeOff) _scheduleReconcile();
          })
          .catchError((Object e) => _log('identify: $e')),
    );
  }

  // ── Frame loop ──────────────────────────────────────────────────────────

  /// The frame loop runs only while a canvas/fixed device needs it. Drivers
  /// waiting for a retry use their own one-shot timer ([_syncRetry]).
  bool get _needsLoop {
    if (_outputs == null || _shouldBeOff) return false;
    return LightDeviceId.values.any(
      (id) => id.isSupported && _config.device(id).mode != LightMode.hardware,
    );
  }

  /// One-shot timer for the retry of families that are down, independent of
  /// the frame loop (a hardware-only setup must not run at 30–120 Hz for it).
  void _syncRetry() {
    final need =
        _outputs != null &&
        !_shouldBeOff &&
        (!_fansReady || !_boardReady || !_gpuReady);
    if (!need) {
      _retryTimer?.cancel();
      _retryTimer = null;
      return;
    }
    if (_retryTimer != null) return;
    // A GPU in backoff waits for its own time; the hub/ITE keep [retryEvery].
    final due = [
      if (!_fansReady || !_boardReady) _nextRetry,
      if (!_gpuReady) _gpuRetryAt ?? _nextRetry,
    ].reduce((a, b) => a.isBefore(b) ? a : b);
    var wait = due.difference(now());
    if (wait < const Duration(milliseconds: 50)) {
      wait = const Duration(milliseconds: 50);
    }
    _retryTimer = Timer(wait, _onRetry);
  }

  void _onRetry() {
    _retryTimer = null;
    if (_stopped || _outputs == null || _shouldBeOff) return;
    if (_fansReady && _boardReady && _gpuReady) return;
    _nextRetry = now().add(retryEvery);
    unawaited(
      _run(() async {
        await _initDevices();
        if (_stopped) return;
        await _reconcile();
        if (_stopped) return;
        _syncTimer();
      }),
    );
  }

  void _syncTimer() {
    if (_stopped) return;
    _syncRetry();
    if (!_needsLoop) {
      if (_timer != null) {
        _timer!.cancel();
        _timer = null;
        _measuredFps = 0;
        _emitStatus(force: true);
      }
      return;
    }
    if (_timer != null) return;
    _frames = 0;
    _fpsWindowStart = now();
    _timer = Timer.periodic(
      Duration(microseconds: 1000000 ~/ _fps),
      (_) => _tick(),
    );
  }

  void _tick() {
    if (_stopped || _outputs == null || _shouldBeOff || _jobs > 0) return;
    final at = now();
    try {
      _frames++;
      _pump(OutputFamily.ite, fromTick: true);
      _pump(OutputFamily.ram, fromTick: true);
      _pump(OutputFamily.gpu, fromTick: true);
      _pump(OutputFamily.fans, fromTick: true);
    } on Object catch (e) {
      _log('frame: $e');
    }
    _updateFps(at);
  }

  double _seconds(DateTime at) =>
      at.difference(_startedAt).inMicroseconds / 1e6;

  /// Sampled colors to use for canvas devices, when they belong to the effect
  /// the engine is actually showing.
  Map<LightDeviceId, List<Rgb>>? get _activePixels =>
      _pixelsEffect == _config.effectId ? _pixels : null;

  /// [showAt] (effect seconds) as the canvas devices must evaluate it so a
  /// firmware `Breathing` keeps its phase with the fans.
  double _composeTime(double showAt) {
    final since = _breathingSince;
    final values = _config.effectValuesFor();
    if (since == null || values == null || _config.effectId != 'breathing') {
      return showAt;
    }
    return breathingEffectTime(
      showAt: showAt,
      anchor: since,
      period: alv2BreathingPeriod(values.number('speed')),
    );
  }

  /// Minimum interval between frame starts of [family]. The ITE one is capped
  /// by the tick period so a high fps setting is not throttled.
  Duration _gap(OutputFamily family) => switch (family) {
    OutputFamily.fans => fanFrameGap,
    OutputFamily.ite => Duration(
      microseconds: iteFrameGap.inMicroseconds < 1000000 ~/ _fps
          ? iteFrameGap.inMicroseconds
          : 1000000 ~/ _fps,
    ),
    OutputFamily.ram => ramFrameGap,
    OutputFamily.gpu => gpuFrameGap,
  };

  /// Starts the next frame of [family] if none is in flight and its gap since
  /// the previous start has passed. The frame is composed here, at send time,
  /// for the instant it will show. Called by the tick and chained right after a
  /// frame returns.
  ///
  /// A tick may land a few ms before the gap ends (timer jitter): [fromTick]
  /// accepts that, so a gap equal to the tick period does not skip every
  /// other tick.
  void _pump(OutputFamily family, {bool fromTick = false}) {
    final lane = _lanes[family]!;
    lane.timer?.cancel();
    lane.timer = null;
    final out = _outputs;
    if (_stopped ||
        out == null ||
        _shouldBeOff ||
        _jobs > 0 ||
        _timer == null ||
        lane.sending ||
        !switch (family) {
          OutputFamily.fans => _fansReady && !_fanMerged,
          OutputFamily.ite => _boardReady,
          OutputFamily.ram => true,
          OutputFamily.gpu => _gpuReady,
        }) {
      return;
    }
    final at = now();
    final gap = fromTick ? _gap(family) - tickSlack : _gap(family);
    if (at.difference(lane.lastStart) < gap) return;

    final epoch = _ioEpoch;
    final Future<bool> started = switch (family) {
      OutputFamily.fans => _sendFans(out, at, epoch),
      OutputFamily.ite => _sendIte(out, epoch),
      OutputFamily.ram => _sendRam(out, epoch),
      OutputFamily.gpu => _sendGpu(out, at, epoch),
    };
    // `_send*` completes with false when nothing was due: no frame started,
    // so no gap applies and nothing is chained (the next tick looks again).
    lane.sending = true;
    lane.lastStart = at;
    var sent = false;
    started
        .then((v) => sent = v)
        .catchError((Object e) {
          _log('${family.name} frame: $e');
          return true;
        })
        .whenComplete(() {
          lane.sending = false;
          if (sent) {
            _chain(family);
          } else {
            lane.lastStart = DateTime.fromMillisecondsSinceEpoch(0);
          }
        });
  }

  /// Next frame of [family] right after one returns, no earlier than its gap
  /// after the previous start.
  void _chain(OutputFamily family) {
    if (_stopped || _shouldBeOff) return;
    final lane = _lanes[family]!;
    final wait = _gap(family) - now().difference(lane.lastStart);
    if (wait <= Duration.zero) {
      _pump(family);
    } else {
      lane.timer?.cancel();
      lane.timer = Timer(wait, () {
        try {
          _pump(family);
        } on Object catch (e) {
          _log('${family.name} frame: $e');
        }
      });
    }
  }

  /// Whether a reply for a frame sent under [epoch] still matters.
  bool _alive(int epoch) => !_stopped && !_shouldBeOff && epoch == _ioEpoch;

  /// Composes and sends the due fan groups. A frame dropped by a priority
  /// turn-off is not a driver failure.
  Future<bool> _sendFans(LightOutputs out, DateTime at, int epoch) async {
    final t = _seconds(at);
    final lead = _leadSeconds(OutputFamily.fans);
    final frame = composeFrame(
      _config,
      t,
      only: _fanIds,
      pixels: _activePixels,
      timeFor: (_) => _composeTime(t + lead),
    );
    final fans = <int, List<Rgb>>{};
    for (final MapEntry(key: id, value: leds) in frame.entries) {
      if (leds.isNotEmpty && _due(id, leds, at)) fans[id.hubGroup!] = leds;
    }
    if (fans.isEmpty) return false;
    final lane = _lanes[OutputFamily.fans]!;
    final ok = await out.sendFanFrames(fans);
    if (!_alive(epoch)) return true;
    if (ok) {
      final took = now().difference(at);
      _observe(OutputFamily.fans, took);
      lane
        ..record(took)
        ..countFrame();
      for (final e in fans.entries) {
        _last[LightDeviceId.forHubGroup(e.key)!] = _Sent(e.value, at);
      }
    } else {
      _fansDown();
    }
    return true;
  }

  /// Chassis then board colors, each composed right before its own send.
  Future<bool> _sendIte(LightOutputs out, int epoch) async {
    var sent = false;
    final lane = _lanes[OutputFamily.ite]!;
    for (final id in const [LightDeviceId.chassis, LightDeviceId.motherboard]) {
      final at = now();
      final leds = _compose(id, at, OutputFamily.ite);
      if (leds == null || !_due(id, leds, at)) continue;
      sent = true;
      final ok = await (id == LightDeviceId.chassis
          ? out.sendChassis(leds)
          : out.sendBoardColors(leds));
      if (!_alive(epoch)) return true;
      if (!ok) {
        _boardDown();
        return true;
      }
      final took = now().difference(at);
      _observe(OutputFamily.ite, took);
      lane.record(took);
      if (_trace && id == LightDeviceId.chassis) {
        stderr.writeln(
          'lighting: ${_seconds(at).toStringAsFixed(3)} s chassis '
          '${leds.first.toHex()} took ${took.inMilliseconds} ms',
        );
      }
      _last[id] = _Sent(leds, at);
    }
    if (sent) lane.countFrame();
    return sent;
  }

  /// Both Fury sticks in sequence (one frame in flight for the family).
  Future<bool> _sendRam(LightOutputs out, int epoch) async {
    var sent = false, wrote = false;
    final lane = _lanes[OutputFamily.ram]!;
    for (final id in const [LightDeviceId.ram1, LightDeviceId.ram2]) {
      final at = now();
      final retryAt = _ramRetryAt[id];
      if (retryAt != null && at.isBefore(retryAt)) continue;
      final leds = _compose(id, at, OutputFamily.ram);
      if (leds == null || !_due(id, leds, at)) continue;
      sent = true;
      final ok = await out.sendRam(id == LightDeviceId.ram1 ? 0 : 1, leds);
      if (!_alive(epoch)) return true;
      if (ok) {
        final took = now().difference(at);
        _observe(OutputFamily.ram, took);
        lane.record(took);
        wrote = true;
        _last[id] = _Sent(leds, at);
        _ramRetryAt.remove(id);
        if (_ramDown.remove(id)) _emitStatus();
      } else {
        _last.remove(id);
        _ramRetryAt[id] = at.add(retryEvery);
        _ramDown.add(id);
        _emitStatus();
      }
    }
    if (wrote) lane.countFrame();
    return sent;
  }

  /// Sends the GPU's single color (Canvas average or Fixed) or turns it off
  /// when disabled/brightness 0. Canvas colors are resent only when they
  /// change (or on the safety resend), so a static image costs one write.
  Future<bool> _sendGpu(LightOutputs out, DateTime at, int epoch) async {
    final d = _config.device(LightDeviceId.gpu);
    if (d.mode == LightMode.hardware) return false;
    final off = !d.enabled || _config.brightness <= 0;
    final brightness = off ? 0 : _gpuBrightness(_config.brightness);
    final color = off
        ? Rgb.black
        : d.mode == LightMode.fixed
        ? d.fixedColor
        : averageCanvasColor(
            _config,
            LightDeviceId.gpu,
            _composeTime(_seconds(at) + _leadSeconds(OutputFamily.gpu)),
            pixels: _activePixels,
          );
    if (!_dueGpu(color, brightness, at)) return false;

    final lane = _lanes[OutputFamily.gpu]!;
    final ok = off
        ? await out.turnGpuOff()
        : await out.sendGpuColor(color, brightness: brightness);
    if (!_alive(epoch)) return true;
    if (!ok) {
      _gpuDown();
      return true;
    }
    final took = now().difference(at);
    _observe(OutputFamily.gpu, took);
    lane
      ..record(took)
      ..countFrame();
    _gpuLast = _GpuSent(color, brightness, at);
    return true;
  }

  /// Global brightness (0–1) as the controller's 0–10 byte: 0 only at 0.
  static int _gpuBrightness(double brightness) =>
      (brightness * 10).round().clamp(1, 10);

  bool _dueGpu(Rgb color, int brightness, DateTime at) {
    final last = _gpuLast;
    return last == null ||
        last.color != color ||
        last.brightness != brightness ||
        at.difference(last.at) >= resendEvery;
  }

  /// Colors of one device for the instant [family] will show them.
  List<Rgb>? _compose(LightDeviceId id, DateTime at, OutputFamily family) {
    final t = _seconds(at);
    final lead = _leadSeconds(family);
    return composeFrame(
      _config,
      t,
      only: {id},
      pixels: _activePixels,
      timeFor: (_) => _composeTime(t + lead),
    )[id];
  }

  bool _due(LightDeviceId id, List<Rgb> leds, DateTime at) {
    final last = _last[id];
    return last == null ||
        !_sameColors(last.leds, leds) ||
        at.difference(last.at) >= resendEvery;
  }

  // ── Status ──────────────────────────────────────────────────────────────

  // Optional timing trace on stderr (LUMIVENT_LIGHTING_TRACE=1), for tuning the
  // latency compensation on real hardware.
  static final _trace = Platform.environment['LUMIVENT_LIGHTING_TRACE'] == '1';

  void _updateFps(DateTime at) {
    final elapsed = at.difference(_fpsWindowStart);
    if (elapsed < const Duration(seconds: 1)) return;
    _loops = {
      for (final MapEntry(key: f, value: lane) in _lanes.entries)
        f: LoopStats(
          fps: (lane.frames * 10000000 / elapsed.inMicroseconds).round() / 10,
          sendMs: lane.frames == 0
              ? null
              : (lane.sendUs / lane.frames / 100).round() / 10,
        ),
    };
    if (_trace) {
      String stats(OutputFamily f) {
        final lane = _lanes[f]!;
        return '${f.name} ${lane.frames} frames avg '
            '${_loops[f]!.sendMs ?? '-'} ms';
      }

      stderr.writeln(
        'lighting: ticks $_frames, ${stats(OutputFamily.fans)}, '
        'fan lead ${(_leadSeconds(OutputFamily.fans) * 1000).toStringAsFixed(0)} ms, '
        '${stats(OutputFamily.ite)}, ${stats(OutputFamily.ram)}, '
        '${stats(OutputFamily.gpu)}',
      );
    }
    for (final lane in _lanes.values) {
      lane.resetStats();
    }
    _measuredFps = (_frames * 1000000 / elapsed.inMicroseconds).roundToDouble();
    _frames = 0;
    _fpsWindowStart = at;
    _emitStatus();
  }

  Map<LightDeviceId, LightOutputStatus> _deviceStatus() {
    final out = _outputs;
    LightOutputStatus status(LightDeviceId id) {
      if (!id.isSupported) {
        return const LightOutputStatus(
          LightOutputState.unsupported,
          detail: 'Placa de vídeo ainda sem suporte.',
        );
      }
      if (out == null) return const LightOutputStatus(LightOutputState.ok);
      final (up, reason) = switch (id) {
        _ when id.isFan => (
          _fansReady,
          'Hub AL V2 não encontrado ou sem permissão de acesso.',
        ),
        LightDeviceId.chassis || LightDeviceId.motherboard => (
          _boardReady,
          'Controlador ITE da placa-mãe não encontrado ou sem permissão de acesso.',
        ),
        LightDeviceId.gpu => (
          _gpuReady,
          'Controlador RGB da GPU não encontrado ou sem permissão de acesso.',
        ),
        _ => (
          !_ramDown.contains(id),
          'Memória Kingston Fury não encontrada ou sem permissão de acesso ao barramento SMBus.',
        ),
      };
      if (up) return const LightOutputStatus(LightOutputState.ok);
      final blocked = out.blockedReason(id);
      if (id == LightDeviceId.gpu) {
        // The GPU guard has its own explanation (missing adapter, permission,
        // failed identification read, SSID mismatch); do not call it a
        // generic "safety block".
        return LightOutputStatus(
          LightOutputState.unavailable,
          detail: blocked ?? reason,
        );
      }
      return LightOutputStatus(
        LightOutputState.unavailable,
        detail: blocked == null ? reason : 'Bloqueado por segurança: $blocked',
      );
    }

    return {for (final id in LightDeviceId.values) id: status(id)};
  }

  /// Emits only when a device status changed or the FPS changed; the FPS
  /// goes out at most once per second ([force] skips that limit).
  void _emitStatus({bool force = false}) {
    final at = now();
    final devices = _deviceStatus();
    final last = _lastStatus;
    final fpsDue =
        force || at.difference(_lastFpsEmit) >= const Duration(seconds: 1);
    final fps = fpsDue ? _measuredFps : (last?.fps ?? 0);
    final loops = fpsDue ? _loops : (last?.loops ?? const {});
    if (last != null &&
        fps == last.fps &&
        _sameLoops(loops, last.loops) &&
        _sameStatus(last.devices, devices)) {
      return;
    }
    if (fps != (last?.fps ?? 0) ||
        !_sameLoops(loops, last?.loops ?? const {})) {
      _lastFpsEmit = at;
    }
    _emit(_lastStatus = LightingStatus(devices, fps: fps, loops: loops));
  }

  void _log(String message) => stderr.writeln('lighting: $message');
}

/// State of one output family's frame pipeline.
class _Lane {
  /// A frame is in flight (set when it starts, cleared when it returns).
  bool sending = false;
  DateTime lastStart = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? timer;

  // Frame counters for the current second (status and trace).
  int frames = 0;
  int sendUs = 0;

  /// One write of the frame (a family may write several devices per frame).
  void record(Duration took) => sendUs += took.inMicroseconds;

  /// The frame went out (at least one write accepted).
  void countFrame() => frames++;

  void resetStats() {
    frames = 0;
    sendUs = 0;
  }
}

class _Sent {
  const _Sent(this.leds, this.at);
  final List<Rgb> leds;
  final DateTime at;
}

class _GpuSent {
  const _GpuSent(this.color, this.brightness, this.at);
  final Rgb color;
  final int brightness;
  final DateTime at;
}

bool _sameColors(List<Rgb> a, List<Rgb> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _sameInts(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _sameLoops(
  Map<OutputFamily, LoopStats> a,
  Map<OutputFamily, LoopStats> b,
) => a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

bool _sameStatus(
  Map<LightDeviceId, LightOutputStatus> a,
  Map<LightDeviceId, LightOutputStatus> b,
) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (b[e.key] != e.value) return false;
  }
  return true;
}
