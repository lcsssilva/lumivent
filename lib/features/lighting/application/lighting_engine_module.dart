import 'dart:async';
import 'dart:io';

import '../../../core/engine/engine_command.dart';
import '../../../core/engine/engine_event.dart';
import '../../../core/engine/engine_module.dart';
import '../domain/hardware_equivalent.dart';
import '../domain/light_device.dart';
import '../domain/light_outputs.dart';
import '../domain/lighting_config.dart';
import '../domain/power_watcher.dart';
import '../domain/rgb.dart';
import 'device_health_monitor.dart';
import 'set_lighting_fps.dart';
import 'lighting_frame_compositor.dart';
import 'lighting_frame_deduplicator.dart';
import 'lighting_hardware_applier.dart';
import 'lighting_hardware_state.dart';
import 'lighting_latency_model.dart';
import 'light_output_state.dart';
import 'set_argb_off.dart';
import 'set_lighting_config.dart';
import 'set_html_effect_frame.dart';
import 'identify_fan_group.dart';
import 'argb_state_changed.dart';
import 'lighting_reconciler.dart';
import 'hardware_family_job.dart';
import 'lighting_reconcile_job.dart';
import 'lighting_status_reporter.dart';
import 'lighting_trace.dart';
import 'output_lane.dart';
import 'output_scheduler.dart';

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
/// Responsibilities keep their own files: what the hardware holds lives in
/// [LightingHardwareState] and the mode writes in
/// [LightingHardwareApplier] ([lighting_hardware_applier.dart]); frame
/// composition in [LightingFrameCompositor]; status emission in
/// [LightingStatusReporter]; lane pacing in [OutputScheduler]; and the
/// coalescing/retry of config changes in [LightingReconciler].
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
    _latency = LightingLatencyModel();
    _deduplicator = LightingFrameDeduplicator(resendEvery);
    _hardware = LightingHardwareState(_deduplicator);
    _compositor = LightingFrameCompositor(leadOf: _leadSeconds);
    _hardwareApplier = LightingHardwareApplier(
      state: _hardware,
      onFamilyDown: _familyDown,
      onBreathingStarted: () => _compositor.anchorBreathing(_seconds(now())),
      trace: _traceFans,
      stopped: () => _stopped,
    );
    _status = LightingStatusReporter(
      emit: (event) => _emit(event),
      now: now,
      outputs: () => _outputs,
      health: _health,
      lanes: () => _lanes,
      leadOf: _leadSeconds,
    );
    _scheduler = OutputScheduler(
      now: now,
      fps: () => _fps,
      isActive: () => !_stopped && _needsLoop,
      canSend: (family) =>
          _blocking[family]! == 0 &&
          switch (family) {
            OutputFamily.fans => _health.fansReady && !_hardware.fanMerged,
            OutputFamily.ite => _health.boardReady,
            OutputFamily.ram => true,
            OutputFamily.gpu => _health.gpuReady,
          },
      gap: _gap,
      send: (family, at) {
        final out = _outputs;
        if (out == null) return Future.value(false);
        final epoch = _ioEpoch;
        return switch (family) {
          OutputFamily.fans => _sendFans(out, at, epoch),
          OutputFamily.ite => _sendIte(out, epoch),
          OutputFamily.ram => _sendRam(out, epoch),
          OutputFamily.gpu => _sendGpu(out, at, epoch),
        };
      },
      status: _status,
      onError: _log,
    );
  }

  static const defaultFps = 30;
  static const minFps = 5;
  static const maxFps = 120;
  static const fanDisplayLatencyMs = LightingLatencyModel.fanDisplayLatencyMs;

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
  Timer? _retryTimer;
  Timer? _hwResendTimer;
  bool _stopped = false;
  late DateTime _startedAt;

  /// Hardware modes are sent a second time this long after a change: the G2
  /// group was seen staying dark intermittently when the mode was applied once
  /// (phase 4 checklist, step 8).
  static const hardwareResendDelay = Duration(seconds: 1);

  late final LightingFrameDeduplicator _deduplicator;
  late final LightingHardwareState _hardware;
  late final LightingHardwareApplier _hardwareApplier;
  late final LightingFrameCompositor _compositor;
  late final LightingStatusReporter _status;
  late final LightingLatencyModel _latency;

  late final OutputScheduler _scheduler;
  Map<OutputFamily, OutputLane> get _lanes => _scheduler.lanes;

  /// Bumped when the off sequence or a re-init starts: replies of frames sent
  /// before it no longer describe the hardware.
  int _ioEpoch = 0;

  // Serial queue of async work (startup, config, off/restore, retry).
  Future<void> _queue = Future<void>.value();

  /// How many running jobs block [OutputFamily] from starting a frame. The
  /// power sequence (turn-off, re-init) blocks every family; the other jobs
  /// block only the families whose hardware they are writing (see the
  /// `_gated` call sites), so a config write no longer freezes ITE, RAM and
  /// GPU frames on the hub's account.
  final _blocking = <OutputFamily, int>{
    for (final f in OutputFamily.values) f: 0,
  };
  final _reconciler = LightingReconciler();

  // Off state: [_isOff] means the off sequence was applied.
  bool _powerOff = false;
  bool _isOff = false;

  bool get _shouldBeOff => _config.argbOff || _powerOff;

  final _health = DeviceHealthMonitor();

  // ── EngineModule ────────────────────────────────────────────────────────

  @override
  void start(void Function(EngineEvent) emit) {
    _emit = emit;
    _startedAt = now();
    _status.loopStarted(_startedAt);
    _compositor.clearBreathing();
    _config = _derive(_user);
    _emit(ArgbStateChanged(_config.argbOff));
    _status.emitStatus();
    unawaited(_startWatcher());
    unawaited(_run(_startup));
  }

  @override
  bool handle(EngineCommand command) {
    switch (command) {
      case SetArgbOff(:final off):
        _setConfig(_user.copyWith(argbOff: off));
      case SetLightingConfig(:final config):
        _setConfig(config);
      case SetLightingFps(:final fps):
        final next = fps.clamp(minFps, maxFps);
        if (next != _fps) {
          _fps = next;
          _scheduler.restart();
        }
      case SetHtmlEffectFrame(:final effectId, :final pixels):
        if (effectId == _config.effectId) {
          _compositor.accept(effectId, pixels);
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
      _scheduler.stop();
      _retryTimer?.cancel();
      _retryTimer = null;
      _hwResendTimer?.cancel();
      _hwResendTimer = null;
    } on Object catch (e, st) {
      _log('timers: $e', st);
    }
    try {
      final watcher = _watcher;
      if (watcher != null) {
        unawaited(
          watcher.stop().catchError(
            (Object e, StackTrace st) => _log('watcher: $e', st),
          ),
        );
      }
    } on Object catch (e, st) {
      _log('watcher: $e', st);
    }
    try {
      await _outputs?.close();
    } on Object catch (e, st) {
      _log('outputs: $e', st);
    }
  }

  // ── Async work ──────────────────────────────────────────────────────────

  Future<void> _run(Future<void> Function() job) {
    final done = _queue.then((_) async {
      if (_stopped) return;
      try {
        await job();
      } on Object catch (e, st) {
        _log('$e', st);
      }
    });
    return _queue = done;
  }

  /// Runs [body] while the lanes of [families] may not start a frame: the
  /// writes of one family must not interleave with its own frames. Nested
  /// gates (`_reinit` runs an init and a reconcile inside its own) are fine.
  Future<T> _gated<T>(
    Iterable<OutputFamily> families,
    Future<T> Function() body,
  ) async {
    for (final f in families) {
      _blocking[f] = _blocking[f]! + 1;
    }
    try {
      return await body();
    } finally {
      for (final f in families) {
        _blocking[f] = _blocking[f]! - 1;
      }
    }
  }

  Future<void> _startup() async {
    try {
      _outputs = _openOutputs();
      if (_shouldBeOff) {
        await _turnOff();
      } else {
        await _initDevices();
        if (_stopped) return;
        await _reconcile();
      }
      if (_stopped) return;
    } finally {
      if (!_stopped) _syncTimer();
    }
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
    } on Object catch (e, st) {
      _log('power watcher: $e', st);
    }
  }

  /// Suspend/shutdown: turn everything off and wait (logind holds the system).
  Future<void> _powerDown() async {
    try {
      if (!_config.offOnSleep || _stopped) return;
      _powerOff = true;
      _syncTimer();
      await _run(_turnOff);
    } on Object catch (e, st) {
      _log('before sleep: $e', st);
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
    if (lightingTrace) {
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
    if (prev.effectId != next.effectId) _compositor.invalidate();
    if (!_compositor.usesFirmwareBreathing(next)) _compositor.clearBreathing();
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

  /// Several config commands in a row (pointer moves) become one job, which
  /// reads the latest config when it runs.
  void _scheduleReconcile() => _reconciler.schedule(() => _run(_reconcile));

  // ── Init, off, restore ──────────────────────────────────────────────────

  /// Inits the families that are not ready (startup, restore, retry).
  Future<void> _initDevices() async {
    final out = _outputs;
    if (out == null) return;
    if (!_health.fansReady) {
      final qty = LightingHardwareState.quantityOf(_config);
      final ok = await _gated([OutputFamily.fans], () => out.initFans(qty));
      if (_stopped) return;
      if (ok) {
        _hardware
          ..appliedQuantity = qty
          ..appliedMergeOrder = LightingConfig.defaultMergeOrder
          ..forgetFans();
        _health.setReady(OutputFamily.fans, true);
      } else {
        _health.scheduleRetry(now(), retryEvery);
      }
    }
    if (!_health.boardReady) {
      final ok = await _gated([OutputFamily.ite], () => out.initBoard());
      if (_stopped) return;
      if (ok) {
        _hardware.forgetBoard();
        _health.setReady(OutputFamily.ite, true);
      } else {
        _health.scheduleRetry(now(), retryEvery);
      }
    }
    final gpuRetryAt = _health.gpuRetryAt;
    if (!_health.gpuReady &&
        (gpuRetryAt == null || !now().isBefore(gpuRetryAt))) {
      final ok = await _gated([OutputFamily.gpu], () => out.initGpu());
      if (_stopped) return;
      if (ok) {
        _hardware.forgetGpu();
        _health
          ..setReady(OutputFamily.gpu, true)
          ..resetGpuBackoff();
      } else {
        _health.recordGpuInitFailure(
          now(),
          retryEvery: retryEvery,
          retryMax: gpuRetryMax,
        );
      }
    }
    _status.emitStatus();
  }

  Future<void> _turnOff() async {
    final out = _outputs;
    if (out == null || _isOff || !_shouldBeOff) return;
    // The power sequence is the one job that blocks every family.
    return _gated(OutputFamily.values, () async {
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
      _health
        ..setReady(OutputFamily.fans, fansOff)
        ..setReady(OutputFamily.ite, boardOff)
        ..setReady(OutputFamily.gpu, gpuOff)
        ..setRamOff(ok: ramOk);
      _hardware.forgetFans();
      _hardware.forgetBoard();
      _hardware.forgetGpu();
      _deduplicator.clear();
      _compositor
        ..clearBreathing()
        ..invalidate();
      _status.emitStatus();
    });
  }

  Future<void> _restore() async {
    if (!_isOff) return;
    await _reinit();
  }

  /// Re-inits the drivers and resends everything the hardware should hold.
  Future<void> _reinit() async {
    final out0 = _outputs;
    if (out0 == null || _shouldBeOff) return;
    // Like the turn-off, the re-init resets every family's state at once.
    return _gated(OutputFamily.values, () async {
      _isOff = false;
      _ioEpoch++;
      _deduplicator.clear();
      _compositor
        ..clearBreathing()
        ..invalidate();
      _config = _derive(_user);
      // Resume/restore may have fixed the bus: the reset also clears the GPU
      // backoff so it is identified right away.
      _health.reset();
      // The drivers' caches no longer reflect the hardware (suspend, turn-off).
      out0.invalidate();
      await _initDevices();
      if (_stopped) return;
      await _reconcile();
      if (_stopped) return;
      _syncTimer();
    });
  }

  // ── Hardware modes ──────────────────────────────────────────────────────

  /// Compares the config with what the hardware holds and sends the
  /// difference. Idempotent. A failure drops the family so the retry redoes it.
  ///
  /// With [hardwareResend] the hardware signatures are forgotten first, so the
  /// modes are written again even though the config did not change (see
  /// [hardwareResendDelay]).
  Future<void> _reconcile({bool hardwareResend = false}) async {
    final out = _outputs;
    await _reconciler.reconcile(
      LightingReconcileJob(
        active: out != null && !_shouldBeOff,
        hardwareResend: hardwareResend,
        forgetHardwareModes: _hardware.forgetHardwareModes,
        families: [
          HardwareFamilyJob(
            ready: () => _health.fansReady,
            reconcile: () => _gated(
              [OutputFamily.fans],
              () => _hardwareApplier.reconcileFans(
                config: _config,
                user: _user,
                out: out!,
              ),
            ),
          ),
          HardwareFamilyJob(
            ready: () => _health.boardReady,
            reconcile: () => _gated(
              [OutputFamily.ite],
              () => _hardwareApplier.reconcileBoard(config: _config, out: out!),
            ),
          ),
          HardwareFamilyJob(
            ready: () => _health.gpuReady,
            reconcile: () => _gated([
              OutputFamily.gpu,
            ], () => _hardwareApplier.reconcileGpu(config: _config, out: out!)),
          ),
        ],
        isStopped: () => _stopped,
        emitStatus: _status.emitStatus,
        syncTimer: _syncTimer,
        scheduleHardwareResend: _scheduleHardwareResend,
      ),
    );
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

  /// A write to [family] failed: it drops, its signatures are forgotten and
  /// the retry redoes the init.
  void _familyDown(OutputFamily family) {
    _health.markDown(family, now(), retryEvery);
    switch (family) {
      case OutputFamily.fans:
        _hardware.forgetFans();
      case OutputFamily.ite:
        _hardware.forgetBoard();
      case OutputFamily.gpu:
        _hardware.forgetGpu();
      case OutputFamily.ram:
        throw ArgumentError.value(family, 'family', 'RAM fails per stick');
    }
    _syncRetry();
    _status.emitStatus();
  }

  void _identify(int group) {
    final out = _outputs;
    final id = LightDeviceId.forHubGroup(group);
    if (out == null || id == null || !_health.fansReady || _shouldBeOff) return;
    final merge = _hardware.fanMerged;
    unawaited(
      out
          .identifyFanGroup(group, merge: merge)
          .then((_) {
            // The ping overwrote the effect: send it again (merge included).
            _hardware
              ..forget(id)
              ..forgetFrameColors(id);
            if (merge) {
              _hardware.forget(LightingHardwareState.mergeKey);
            }
            if (!_stopped && !_shouldBeOff) _scheduleReconcile();
          })
          .catchError((Object e, StackTrace st) => _log('identify: $e', st)),
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
    final due = _outputs != null && !_shouldBeOff ? _health.retryDue() : null;
    if (due == null) {
      _retryTimer?.cancel();
      _retryTimer = null;
      return;
    }
    if (_retryTimer != null) return;
    var wait = due.difference(now());
    if (wait < const Duration(milliseconds: 50)) {
      wait = const Duration(milliseconds: 50);
    }
    _retryTimer = Timer(wait, _onRetry);
  }

  void _onRetry() {
    _retryTimer = null;
    if (_stopped || _outputs == null || _shouldBeOff) return;
    if (!_health.hasUnavailableFamilies) return;
    _health.scheduleRetry(now(), retryEvery);
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
    _scheduler.sync();
  }

  double _seconds(DateTime at) =>
      at.difference(_startedAt).inMicroseconds / 1e6;

  /// How far ahead of "now" a family must be composed. Synchronous outputs
  /// (ITE, RAM) show the colors when the send ends, so the lead is the send
  /// time. The fans show a frame only [fanDisplayLatencyMs] after the whole
  /// send, so their lead is the send time plus that delay. The GPU applies the
  /// effect when the write lands, before the controller's 120 ms pause, so
  /// only the write part of its measured send time is a lead.
  double _leadSeconds(OutputFamily family) =>
      _latency.leadSeconds(family, gpuFrameGap);

  /// Current send-time estimate of [family] (EMA of the measured durations,
  /// clamped to 0-150 ms).
  Duration latencyOf(OutputFamily family) => _latency.latencyOf(family);

  void _observe(OutputFamily family, Duration took) =>
      _latency.observe(family, took);

  void _traceFans(String what) =>
      traceLighting('${_seconds(now()).toStringAsFixed(3)} s $what');

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

  /// Whether a reply for a frame sent under [epoch] still matters.
  bool _alive(int epoch) => !_stopped && !_shouldBeOff && epoch == _ioEpoch;

  /// Composes and sends the due fan groups. A frame dropped by a priority
  /// turn-off is not a driver failure.
  Future<bool> _sendFans(LightOutputs out, DateTime at, int epoch) async {
    final frame = _compositor.composeFrame(
      _config,
      only: _fanIds,
      seconds: _seconds(at),
      family: OutputFamily.fans,
    );
    final fans = <int, List<Rgb>>{};
    for (final MapEntry(key: id, value: leds) in frame.entries) {
      if (leds.isNotEmpty && _deduplicator.shouldSendColors(id, leds, at)) {
        fans[id.hubGroup!] = leds;
      }
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
        _deduplicator.recordColors(
          LightDeviceId.forHubGroup(e.key)!,
          e.value,
          at,
        );
      }
    } else {
      _familyDown(OutputFamily.fans);
    }
    return true;
  }

  /// Chassis then board colors, each composed right before its own send.
  Future<bool> _sendIte(LightOutputs out, int epoch) async {
    var sent = false;
    final lane = _lanes[OutputFamily.ite]!;
    for (final id in const [LightDeviceId.chassis, LightDeviceId.motherboard]) {
      final at = now();
      final leds = _compositor.composeDevice(
        _config,
        id: id,
        seconds: _seconds(at),
        family: OutputFamily.ite,
      );
      if (leds == null || !_deduplicator.shouldSendColors(id, leds, at)) {
        continue;
      }
      sent = true;
      final ok = await (id == LightDeviceId.chassis
          ? out.sendChassis(leds)
          : out.sendBoardColors(leds));
      if (!_alive(epoch)) return true;
      if (!ok) {
        _familyDown(OutputFamily.ite);
        return true;
      }
      final took = now().difference(at);
      _observe(OutputFamily.ite, took);
      lane.record(took);
      if (lightingTrace && id == LightDeviceId.chassis) {
        traceLighting(
          '${_seconds(at).toStringAsFixed(3)} s chassis '
          '${leds.first.toHex()} took ${took.inMilliseconds} ms',
        );
      }
      _deduplicator.recordColors(id, leds, at);
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
      final retryAt = _health.ramRetryAt(id);
      if (retryAt != null && at.isBefore(retryAt)) continue;
      final leds = _compositor.composeDevice(
        _config,
        id: id,
        seconds: _seconds(at),
        family: OutputFamily.ram,
      );
      if (leds == null || !_deduplicator.shouldSendColors(id, leds, at)) {
        continue;
      }
      sent = true;
      final ok = await out.sendRam(id == LightDeviceId.ram1 ? 0 : 1, leds);
      if (!_alive(epoch)) return true;
      if (ok) {
        final took = now().difference(at);
        _observe(OutputFamily.ram, took);
        lane.record(took);
        wrote = true;
        _deduplicator.recordColors(id, leds, at);
        if (_health.recordRamSuccess(id)) _status.emitStatus();
      } else {
        _deduplicator.forget(id);
        _health.recordRamFailure(id, at.add(retryEvery));
        _status.emitStatus();
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
        : (d.mode == LightMode.fixed
                  ? d.fixedColor
                  : _compositor.gpuAverage(
                      _config,
                      seconds: _seconds(at) + _leadSeconds(OutputFamily.gpu),
                    ))
              .scaled(_gpuColorScale(_config.brightness));
    if (!_deduplicator.shouldSendGpu(color, brightness, at)) return false;

    final lane = _lanes[OutputFamily.gpu]!;
    final ok = off
        ? await out.turnGpuOff()
        : await out.sendGpuColor(color, brightness: brightness);
    if (!_alive(epoch)) return true;
    if (!ok) {
      _familyDown(OutputFamily.gpu);
      return true;
    }
    final took = now().difference(at);
    _observe(OutputFamily.gpu, took);
    lane
      ..record(took)
      ..countFrame();
    _deduplicator.recordGpu(color, brightness, at);
    return true;
  }

  /// Global brightness (0–1) as the controller's 0–10 byte. Byte 0 is never
  /// sent here (off is handled by the caller); below 10% the byte stays at 1
  /// and [_gpuColorScale] dims the color for the rest.
  static int _gpuBrightness(double brightness) =>
      (brightness * 10).round().clamp(1, 10);

  /// Color factor below the controller's lowest step (byte 1 ≈ 10%), so 1–9%
  /// is not shown at 10% while every other device follows the slider.
  static double _gpuColorScale(double brightness) =>
      brightness >= 0.1 ? 1.0 : brightness * 10;

  /// Logs to stderr; the stack trace follows when the cause has one.
  void _log(String message, [StackTrace? stack]) =>
      stderr.writeln('lighting: $message${stack == null ? '' : '\n$stack'}');
}
