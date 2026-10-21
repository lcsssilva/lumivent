// Sole owner of the AL V2 hub hidraw inside the engine. Sent packets (safety
// guard: nothing else): RPM reads (`E0 50 00`), per-group duty, motherboard RPM
// sync, and lighting (effect/colors/frame, quantity, merge order, ping) plus
// the motherboard ARGB sync **only to turn it off** (`E0 10 61 00`). No
// firmware commands. Runs in its own worker isolate (`hub_worker.dart`).
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../../../../core/platform/hidapi_ffi.dart';
import 'protocol.dart';

/// Minimal hub transport (feature / output / input). The real [HidDevice]
/// comes in through an adapter; the tests use a fake.
abstract interface class Alv2Transport {
  void sendFeature(List<int> data, int length);
  void write(List<int> data, int length);
  Uint8List getInput(int reportId, int length);
  void close();
}

class _HidTransport implements Alv2Transport {
  _HidTransport(this._dev);
  final HidDevice _dev;

  @override
  void sendFeature(List<int> data, int length) =>
      _dev.sendFeature(data, length);
  @override
  void write(List<int> data, int length) => _dev.write(data, length);
  @override
  Uint8List getInput(int reportId, int length) =>
      _dev.getInput(reportId, length);
  @override
  void close() => _dev.close();
}

class Alv2Hub {
  Alv2Hub(
    this._hid, {
    this.retry = const Duration(seconds: 5),
    DateTime Function()? now,
    void Function(Duration)? sleeper,
    Future<void> Function(Duration)? delay,
  }) : _now = now ?? DateTime.now,
       _sleep = sleeper ?? sleep,
       _delay = delay ?? Future<void>.delayed;

  /// Hub over an already-open transport (without hidapi), for tests.
  Alv2Hub.withTransport(
    Alv2Transport transport, {
    DateTime Function()? now,
    void Function(Duration)? sleeper,
    Future<void> Function(Duration)? delay,
  }) : _hid = null,
       retry = const Duration(seconds: 5),
       _now = now ?? DateTime.now,
       _sleep = sleeper ?? sleep,
       _delay = delay ?? Future<void>.delayed,
       _dev = transport;

  /// Opens hidapi; without the library the hub only returns `null`/`false`.
  factory Alv2Hub.open() {
    try {
      return Alv2Hub(HidApi.open());
    } on Object {
      return Alv2Hub(null);
    }
  }

  final HidApi? _hid;

  /// Wait before searching for the hub again after a failure.
  final Duration retry;

  final DateTime Function() _now;
  final void Function(Duration) _sleep;
  final Future<void> Function(Duration) _delay;

  Alv2Transport? _dev;
  DateTime? _nextTry;

  /// Set by [dispose]: nothing touches the transport after this.
  bool _disposed = false;

  /// Until when the hub must remain quiet: end of the last send plus the
  /// type of that packet (20 ms control/duty, 5 ms light).
  DateTime? _quietUntil;

  /// End of the asynchronous lighting operation queue (see [_enqueue]).
  Future<void> _tail = Future<void>.value();

  /// Synchronously waits only for the remaining pause, at most [alv2PacketGap]
  /// (used by duty/RPM, which may run during an asynchronous frame).
  void _wait() {
    // Control packets (duty, RPM read, sync, quantity) keep the vendor software's
    // spacing: at least [alv2PacketGap] after *any* packet, even a 2 ms stream
    // packet. Measured 2026-10-19: with the canvas streaming, a duty squeezed
    // between colour packets made the rear fan slow down audibly.
    final last = _lastAt;
    var until = _quietUntil;
    if (last != null) {
      final control = last.add(alv2PacketGap);
      if (until == null || control.isAfter(until)) until = control;
    }
    if (until == null) return;
    var rem = until.difference(_now());
    if (rem <= Duration.zero) return;
    if (rem > alv2PacketGap) rem = alv2PacketGap;
    _sleep(rem);
  }

  Future<void> _waitAsync() async {
    final until = _quietUntil;
    if (until == null) return;
    final rem = until.difference(_now());
    if (rem > Duration.zero) await _delay(rem);
  }

  /// When the last packet of any kind left (see [_wait]).
  DateTime? _lastAt;

  void _mark(Duration gap) {
    final now = _now();
    _lastAt = now;
    _quietUntil = now.add(gap);
  }

  /// RPM for the 4 groups, or `null` if the hub is currently inaccessible. The
  /// hidraw node stays open between operations and is reopened if the hub disappears.
  List<int>? readRpm() {
    if (_disposed) return null;
    final dev = _dev ?? _open();
    if (dev == null) return null;
    try {
      _wait();
      dev.sendFeature(alv2ReadRpm, alv2FeatureLength);
      _mark(alv2PacketGap);
      _wait(); // the firmware needs the pause before responding
      return parseAlv2Rpm(
        alv2InputPayload(dev.getInput(alv2ReportId, alv2InputLength)),
      );
    } on HidException {
      _fail();
      return null;
    }
  }

  /// Sends duty (1–100) for [group] (0–3). `false` if the hub does not respond.
  bool setDuty(int group, int duty) {
    if (group < 0 || group >= alv2Groups) return false;
    return _send([Alv2Packet(alv2DutyPacket(group, duty))], alv2PacketGap);
  }

  /// Enables/disables motherboard RPM sync for each group ([sync] has 4 values).
  /// `false` if the hub does not respond.
  bool setMotherboardSync(List<bool> sync) {
    if (sync.length != alv2Groups) return false;
    return _send([
      for (final p in alv2MotherboardSyncPackets(sync)) Alv2Packet(p),
    ], alv2PacketGap);
  }

  /// Fan quantity (0–6) for [group]. The service resends
  /// all ports (AL-V2 §4); this is up to the caller.
  bool setQuantity(int group, int q) {
    if (group < 0 || group >= alv2Groups || q < 0 || q > alv2MaxFans) {
      return false;
    }
    return _send([Alv2Packet(alv2QuantityPacket(group, q))], alv2PacketGap);
  }

  /// Merge order (4 groups, values 0–3). Only 7 bytes are sent: the final `08` is
  /// truncated by the feature report (AL-V2 §7).
  bool setMergeOrder(List<int> order) {
    if (order.length != alv2Groups ||
        order.any((o) => o < 0 || o >= alv2Groups)) {
      return false;
    }
    return _send([Alv2Packet(alv2MergeOrderPacket(order))], alv2PacketGap);
  }

  /// Disables motherboard ARGB sync (`E0 10 61 00`). Enabling is never sent.
  bool disableArgbSync() =>
      _send([const Alv2Packet(alv2ArgbSyncOffPacket)], alv2PacketGap);

  /// Sends [writes] in the given order (colors before the effect on each port) and, if
  /// [frame], and finishes with `E0 60 00 01`. **Asynchronous**: waits 5 ms
  /// between packets with `Future.delayed`, without blocking fan/sensor loops.
  /// Concurrent calls enter a queue: the second starts only when the
  /// first one finishes (packets from different frames are never interleaved).
  ///
  /// With [priority] (turn-off before sleep/shutdown) the send skips the queue,
  /// so it never waits behind a 2.5 s [identify]. It also invalidates everything
  /// already queued or in progress: those operations are dropped (they return
  /// `false`) instead of relighting the LEDs after the off.
  Future<bool> sendLighting(
    List<Alv2PortWrite> writes, {
    bool frame = true,
    bool priority = false,
  }) {
    if (_disposed) return Future.value(false);
    final packets = [
      for (final w in writes) ...w.packets,
      if (frame) const Alv2Packet(alv2FramePacket),
    ];
    if (priority) {
      _epoch++;
      return _sendAsync(packets, alv2LightingGap);
    }
    return _enqueue((epoch) => _sendAsync(packets, alv2LightingGap, epoch));
  }

  /// Streams a canvas frame (sequence: colors + commit per port, no
  /// `E0 60 00 01` frame). Same queue and quiet-time rules as [sendLighting],
  /// but with a [alv2StreamGap] pause and output reports written with their
  /// real size (no padding up to 353 B). Only for canvas frames: one-shot
  /// sends must use [sendLighting], whose slower pacing is the safe one.
  Future<bool> streamCanvas(List<Alv2PortWrite> writes) {
    if (_disposed) return Future.value(false);
    final packets = [
      for (final w in writes)
        for (final p in w.packets)
          Alv2Packet(p.bytes, output: p.output, pad: false),
    ];
    return _enqueue((epoch) => _sendAsync(packets, alv2StreamGap, epoch));
  }

  /// Identifies [group]: ping, waits 2500 ms, frame (AL-V2 §4). With
  /// [merge] active and group ≠ 0 uses the merge ping; the caller reapplies the
  /// merge afterwards. Occupies the light queue during the wait.
  Future<bool> identify(int group, {bool merge = false}) {
    if (_disposed || group < 0 || group >= alv2Groups) {
      return Future.value(false);
    }
    final ping = merge && group != 0
        ? alv2MergePingPacket(group)
        : alv2PingPacket(group);
    return _enqueue((epoch) async {
      if (!await _sendAsync([Alv2Packet(ping)], alv2LightingGap, epoch)) {
        return false;
      }
      await _delay(const Duration(milliseconds: 2500));
      return _sendAsync(
        [const Alv2Packet(alv2FramePacket)],
        alv2LightingGap,
        epoch,
      );
    });
  }

  /// Incremented by a priority send: operations queued under an older epoch
  /// are dropped.
  int _epoch = 0;

  Future<bool> _enqueue(Future<bool> Function(int epoch) job) {
    final epoch = _epoch;
    final prev = _tail;
    final done = Completer<void>();
    _tail = done.future;
    return prev.then((_) => job(epoch)).whenComplete(done.complete);
  }

  Future<bool> _sendAsync(
    List<Alv2Packet> packets,
    Duration gap, [
    int? epoch,
  ]) async {
    for (final p in packets) {
      await _waitAsync();
      // Disposed (or superseded by a priority send) while waiting: stop before
      // the next packet.
      if (_disposed || (epoch != null && epoch != _epoch)) return false;
      final dev = _dev ?? _open();
      if (dev == null) return false;
      try {
        _write(dev, p);
      } on HidException {
        _fail();
        return false;
      }
      _mark(gap);
    }
    return true;
  }

  bool _send(List<Alv2Packet> packets, Duration gap) {
    if (_disposed) return false;
    final dev = _dev ?? _open();
    if (dev == null) return false;
    try {
      for (final p in packets) {
        _wait();
        _write(dev, p);
        _mark(gap);
      }
      return true;
    } on HidException {
      _fail();
      return false;
    }
  }

  void _write(Alv2Transport dev, Alv2Packet p) {
    if (p.output) {
      checkAlv2Packet(p.bytes, output: true);
      dev.write(p.bytes, p.pad ? alv2OutputLength : p.bytes.length);
    } else {
      // Seven-byte feature report: anything beyond this (merge order) is truncated.
      final b = p.bytes.length > alv2FeatureLength
          ? p.bytes.sublist(0, alv2FeatureLength)
          : p.bytes;
      checkAlv2Packet(b, output: false);
      dev.sendFeature(b, alv2FeatureLength);
    }
  }

  Alv2Transport? _open() {
    final hid = _hid;
    if (_disposed || hid == null) return null;
    final next = _nextTry;
    if (next != null && _now().isBefore(next)) return null;
    final all = hid.enumerate(vendorId: alv2VendorId, productId: alv2ProductId);
    // Only the expected interface: never fall back to another one.
    final target = all
        .where((d) => d.interfaceNumber == alv2Interface)
        .firstOrNull;
    try {
      if (target != null) {
        return _dev = _HidTransport(hid.openPath(target.path));
      }
    } on HidException {
      // permission denied or disconnected midway: retry later
    }
    _nextTry = _now().add(retry);
    return null;
  }

  void _fail() {
    _close();
    _nextTry = _now().add(retry);
  }

  void _close() {
    _dev?.close();
    _dev = null;
  }

  /// Closes the hub for good. Safe to call twice.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _close();
    _hid?.dispose();
  }
}
