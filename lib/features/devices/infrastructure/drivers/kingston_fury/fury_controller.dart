// Kingston Fury DDR5 memory lighting control (Fury §4).
//
// DANGER: the same bus contains the SPD hub and PMIC. Only 0x61/0x63, and only
// after the 0xDD guard and "FURY" identity check. Runs in the engine isolate.
import 'dart:io';

import '../../../../../core/platform/smbus_exception.dart';
import 'protocol.dart';
import 'fury_bus.dart';
import 'sm_bus_fury_bus.dart';
import 'fury_slot.dart';

class FuryController {
  FuryController({
    FuryBus Function()? open,
    this.retry = const Duration(seconds: 5),
    this.attempts = 3,
    this.retryGap = const Duration(milliseconds: 20),
    DateTime Function()? clock,
    void Function(Duration)? pause,
  }) : _open = open ?? SmBusFuryBus.openByName,
       _now = clock ?? DateTime.now,
       _pause = pause ?? sleep;

  final FuryBus Function() _open;
  final Duration retry;

  /// Attempts per operation before the 5 s backoff. The SMBus controller on
  /// these modules NACKs intermittently (seen on hardware 2026-10-19), so a
  /// single failure must not drop the RAM for [retry].
  final int attempts;
  final Duration retryGap;
  final DateTime Function() _now;
  final void Function(Duration) _pause;

  FuryBus? _bus;
  DateTime? _nextTry;

  /// Set by [close]: nothing opens or touches the bus after this.
  bool _disposed = false;
  final _slots = {for (final a in furyAddresses) a: FurySlot()};

  /// Slots (0/1) still usable (not disabled).
  List<int> get activeSlots => [
    for (final (i, a) in furyAddresses.indexed)
      if (_slots[a]!.disabledReason == null) i,
  ];

  /// Reason the [slot] is disabled, or null.
  String? disabledReason(int slot) => slot < 0 || slot >= furyAddresses.length
      ? 'invalid slot'
      : _slots[furyAddresses[slot]]!.disabledReason;

  /// Direct mode: sends 12 [rgb] colors (36 bytes), only changed bytes. False if not applied.
  bool setColors(int slot, List<int> rgb) {
    if (rgb.length != furyColorBytes) {
      throw ArgumentError('expected $furyColorBytes bytes, got ${rgb.length}');
    }
    return _run(slot, (bus, addr, s) {
      if (s.mode != FurySlotMode.direct) {
        _enterDirect(bus, addr);
        s.mode = FurySlotMode.direct;
        s.cache = null;
      }
      final cache = s.cache;
      final changed = [
        for (var i = 0; i < furyColorBytes; i++)
          if (cache == null || cache[i] != rgb[i]) i,
      ];
      if (changed.isEmpty) return;
      bus.writeByte(addr, furyRegSession, furySessionBegin);
      for (final i in changed) {
        bus.writeByte(addr, furyRegLedBase + i, rgb[i] & 0xFF);
      }
      bus.writeByte(addr, furyRegSession, furySessionEnd);
      s.cache = [for (final v in rgb) v & 0xFF];
    });
  }

  /// Single color (for example, black for "Turn ARGB off"). Returning to direct mode reruns its sequence.
  bool setSingleColor(int slot, int r, int g, int b) {
    final color = [r & 0xFF, g & 0xFF, b & 0xFF];
    return _run(slot, (bus, addr, s) {
      final prev = s.single;
      if (s.mode == FurySlotMode.single &&
          prev != null &&
          prev[0] == color[0] &&
          prev[1] == color[1] &&
          prev[2] == color[2]) {
        return;
      }
      bus.writeByte(addr, furyRegSession, furySessionBegin);
      bus.writeByte(addr, furyRegMode, furyModeSingle);
      bus.writeByte(addr, furyRegSingleEnable, 0x01);
      for (var c = 0; c < 3; c++) {
        bus.writeByte(addr, furyRegSingleColor + c, color[c]);
      }
      bus.writeByte(addr, furyRegSession, furySessionEnd);
      s.mode = FurySlotMode.single;
      s.single = color;
      s.cache = null;
    });
  }

  /// Forgets what the sticks hold (cache and mode) so the next write is
  /// complete, for example after a resume. Slots disabled by the guard stay
  /// disabled; the bus and the identity checks are kept.
  void invalidate() {
    for (final s in _slots.values) {
      s.mode = FurySlotMode.none;
      s.cache = null;
      s.single = null;
    }
  }

  /// Closes the bus for good. Safe to call twice.
  void close() {
    if (_disposed) return;
    _disposed = true;
    _dropBus();
  }

  // ---- internal ----

  bool _run(int slot, void Function(FuryBus, int, FurySlot) body) {
    if (slot < 0 || slot >= furyAddresses.length) {
      throw ArgumentError('invalid slot: $slot');
    }
    return _runAddr(furyAddresses[slot], body);
  }

  bool _runAddr(int addr, void Function(FuryBus, int, FurySlot) body) {
    // Defense in depth: nothing outside the list, no I/O.
    if (!furyAddresses.contains(addr)) {
      throw ArgumentError(
        'address 0x${addr.toRadixString(16)} is outside furyAddresses',
      );
    }
    if (_disposed) return false;
    final s = _slots[addr]!;
    if (s.disabledReason != null) return false;
    for (var attempt = 0; attempt < attempts; attempt++) {
      final bus = _ensureBus();
      if (bus == null) return false;
      try {
        if (!s.ready) {
          if (!_prepare(bus, addr, s)) return false;
        }
        body(bus, addr, s);
        return true;
      } on SmbusException {
        _dropBus();
        if (attempt + 1 >= attempts) {
          _nextTry = _now().add(retry);
          return false;
        }
        _pause(retryGap);
      }
    }
    return false;
  }

  FuryBus? _ensureBus() {
    if (_disposed) return null;
    if (_bus != null) return _bus;
    final next = _nextTry;
    if (next != null && _now().isBefore(next)) return null;
    try {
      return _bus = _open();
    } on SmbusException {
      _nextTry = _now().add(retry);
      return null;
    }
  }

  void _dropBus() {
    try {
      _bus?.close();
    } catch (_) {}
    _bus = null;
    for (final s in _slots.values) {
      s.ready = false;
      s.mode = FurySlotMode.none;
      s.cache = null;
      s.single = null;
    }
  }

  /// Quick write (ACK) -> 0xDD guard -> "FURY" identity. The first write happens only here.
  bool _prepare(FuryBus bus, int addr, FurySlot s) {
    bus.quick(addr);
    final dd = bus.readByte(addr, furyGuardRegister);
    if (!furyGuardAllows(dd)) {
      s.disabledReason =
          'PWM controller (0xDD = 0x${dd.toRadixString(16)}): address skipped for safety';
      return false;
    }
    bus.writeByte(addr, furyRegSession, furySessionBegin);
    final List<int> id;
    try {
      id = [
        for (final r in furyIdRegisters) (bus.readWord(addr, r) >> 8) & 0xFF,
      ];
    } finally {
      // Close the session even if the read fails (best effort).
      try {
        bus.writeByte(addr, furyRegSession, furySessionEnd);
      } on SmbusException {
        // the original error is already handled by the caller
      }
    }
    if (!furyIdMatches(id)) {
      s.disabledReason =
          'identity is not FURY (${id.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')})';
      return false;
    }
    s.ready = true;
    return true;
  }

  void _enterDirect(FuryBus bus, int addr) {
    bus.writeByte(addr, furyRegSession, furySessionBegin);
    bus.writeByte(addr, furyRegDirectB, 0x00);
    bus.writeByte(addr, furyRegMode, furyModeDirect);
    bus.writeByte(addr, furyRegDirectC, 0x01);
    bus.writeByte(addr, furyRegBrightness, furyBrightness);
    bus.writeByte(addr, furyRegSession, furySessionEnd);
  }
}
