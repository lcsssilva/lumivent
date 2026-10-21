// Owner of the ITE IT5702 hidraw inside the engine: reads `CC 60`, controls the
// D_LED1 (case strip) in direct mode and the board zones. Every packet
// goes through `checkIteCommand`. Runs in the engine isolate.
import 'dart:io';
import 'dart:typed_data';

import '../../../../../core/platform/hidapi_ffi.dart';
import 'effects.dart';
import 'protocol.dart';

/// Minimal ITE transport (feature reports); tests use a fake.
abstract interface class IteTransport {
  void sendFeature(List<int> data, int length);
  Uint8List getFeature(int reportId, int length);
  void close();
}

class HidIteTransport implements IteTransport {
  HidIteTransport(this._dev);
  final HidDevice _dev;

  @override
  void sendFeature(List<int> data, int length) =>
      _dev.sendFeature(data, length);

  @override
  Uint8List getFeature(int reportId, int length) =>
      _dev.getFeature(reportId, length);

  @override
  void close() => _dev.close();
}

class IteController {
  /// [opener] returns the transport or `null` (ITE missing / permission denied);
  /// [pause] (blocking, used only by `init`) and [delay] (asynchronous, used by
  /// the zone effects) allow tests to avoid real delays.
  IteController(
    this._opener, {
    this.retry = const Duration(seconds: 5),
    this._pause = sleep,
    this._delay = _defaultDelay,
    this._onDispose,
  });

  static Future<void> _defaultDelay(Duration d) => Future<void>.delayed(d);

  /// Opens hidapi; without the library the controller only returns `false`.
  factory IteController.open() {
    HidApi? hid;
    try {
      hid = HidApi.open();
    } on Object {
      return IteController(() => null);
    }
    final api = hid;
    return IteController(() {
      final all = api.enumerate(vendorId: iteVendorId, productId: iteProductId);
      // On hidraw, collections 0x10 and 0xCC share the node; report ID selects
      // one. Without the 0xCC collection nothing is opened (no fallback).
      final target = all.where((d) => d.usage == iteUsage).firstOrNull;
      if (target == null) return null;
      try {
        return HidIteTransport(api.openPath(target.path));
      } on HidException {
        return null;
      }
    }, onDispose: api.dispose);
  }

  final IteTransport? Function() _opener;
  final Duration retry;
  final void Function(Duration) _pause;
  final Future<void> Function(Duration) _delay;
  final void Function()? _onDispose;

  IteTransport? _dev;
  DateTime? _nextTry;
  bool _ready = false;

  /// Set by [dispose]: nothing opens or touches the transport after this.
  bool _disposed = false;
  int? _sentEnum;
  int _streamLeds = 47;
  IteInfo? _info;
  final _zoneColors = <int, int>{};

  /// Info read during the last `init` (`null` before it).
  IteInfo? get info => _info;

  /// `CC 60` (info + calibration), `CC 32 01`, `CC 34 01`, wait 30 ms.
  ///
  /// The two short waits (20 + 30 ms) stay blocking: `init` is reached from the
  /// synchronous send paths (`streamCase`, `setZoneColors`) and runs only on
  /// (re)initialization, never per frame.
  bool init() {
    if (_disposed) return false;
    final dev = _dev ?? _open();
    if (dev == null) return false;
    // The hardware state is unknown after (re)init: forget what was sent.
    _zoneColors.clear();
    try {
      _send(dev, iteReadInfo);
      _pause(const Duration(milliseconds: 20));
      _info = parseIteInfo(dev.getFeature(iteReportId, iteReportLength));
      _send(dev, iteDirectModePacket(iteDirectBitDLed1));
      _sentEnum = null;
      _sendCount(dev, _streamLeds);
      _pause(const Duration(milliseconds: 30));
      _ready = true;
      return true;
    } on HidException {
      _fail();
      return false;
    }
  }

  /// D_LED1 frames: [rgb] is the flat R,G,B… list (47 case LEDs).
  bool streamCase(List<int> rgb) {
    if (_disposed || !_ensureReady()) return false;
    final dev = _dev!;
    final packets = iteStreamPackets(
      rgb,
      order: _info?.stripOrder ?? IteColorOrder.grb,
    );
    try {
      _streamLeds = rgb.length ~/ 3;
      _sendCount(dev, _streamLeds);
      for (final p in packets) {
        _send(dev, p);
      }
      return true;
    } on HidException {
      _fail();
      return false;
    }
  }

  /// Static color by zone (IDs `0x20`–`0x26`) and one `CC 28 FF`; unchanged
  /// zones are not resent.
  bool setZoneColors(Map<int, (int, int, int)> colors) {
    if (_disposed || !_ensureReady()) return false;
    final dev = _dev!;
    final order = _info?.zoneOrder ?? IteColorOrder.bgr;
    try {
      var sent = false;
      for (final MapEntry(key: zone, value: (r, g, b)) in colors.entries) {
        final key = r << 16 | g << 8 | b;
        if (_zoneColors[zone] == key) continue;
        _send(dev, iteZoneStaticPacket(zone, r, g, b, order: order));
        _zoneColors[zone] = key;
        sent = true;
      }
      if (sent) _send(dev, iteApplyPacket());
      return true;
    } on HidException {
      _zoneColors.clear();
      _fail();
      return false;
    }
  }

  /// Hardware effects, keyed by zone index (0..6, `CC 2z`). Batch: every
  /// `CC 2z`, one 100 ms wait, a single `CC 28` with the mask of the zones,
  /// 25 ms. Asynchronous so the engine isolate is never blocked.
  Future<bool> setZoneEffects(Map<int, IteHardwareEffect> effects) async {
    if (effects.isEmpty) return true;
    if (_disposed || !_ensureReady()) return false;
    var dev = _dev!;
    try {
      var mask = 0;
      for (final MapEntry(key: z, value: effect) in effects.entries) {
        _send(dev, effect.packet(z));
        mask |= 1 << z;
      }
      await _delay(const Duration(milliseconds: 100));
      // Disposed or dropped while waiting: do not touch the device again.
      final cur = _dev;
      if (_disposed || cur == null) return false;
      dev = cur;
      _send(dev, iteApplyPacket(mask));
      for (final z in effects.keys) {
        _zoneColors.remove(iteZoneIoShield1 + z);
      }
      await _delay(const Duration(milliseconds: 25));
      return !_disposed;
    } on HidException {
      _fail();
      return false;
    }
  }

  /// Black static on the board zones (`0x20`, `0x22`, `0x23`, `0x25`), `CC 28
  /// FF`, and an all-black D_LED1. The empty 12 V zones and D_LED2 (`0x26`,
  /// which feeds the hub ARGB input) are never written. The next send reruns
  /// `init` (`CC 28 FF` may take D_LED1 out of direct mode).
  bool allOff() {
    if (_disposed || !_ensureReady()) return false;
    final dev = _dev!;
    try {
      for (final z in _offZones) {
        _send(dev, iteZoneStaticPacket(z, 0, 0, 0));
        _zoneColors[z] = 0;
      }
      _send(dev, iteApplyPacket());
      _send(dev, iteDirectModePacket(iteDirectBitDLed1));
      for (final p in iteStreamPackets(List.filled(_streamLeds * 3, 0))) {
        _send(dev, p);
      }
      _ready = false;
      return true;
    } on HidException {
      _fail();
      return false;
    }
  }

  static const _offZones = [
    iteZoneIoShield1,
    iteZoneCpu,
    iteZoneIoShield2,
    iteZoneDLed1,
  ];

  bool _ensureReady() => _ready || init();

  void _sendCount(IteTransport dev, int leds) {
    final e = iteLedCountEnum(leds);
    if (_sentEnum == e) return;
    _send(dev, iteLedCountPacket(leds));
    _sentEnum = e;
  }

  void _send(IteTransport dev, List<int> packet) {
    checkIteCommand(packet);
    dev.sendFeature(packet, iteReportLength);
  }

  IteTransport? _open() {
    if (_disposed) return null;
    final next = _nextTry;
    if (next != null && DateTime.now().isBefore(next)) return null;
    final dev = _opener();
    if (dev != null) return _dev = dev;
    _nextTry = DateTime.now().add(retry);
    return null;
  }

  void _fail() {
    _close();
    _nextTry = DateTime.now().add(retry);
  }

  void _close() {
    _dev?.close();
    _dev = null;
    _ready = false;
    _sentEnum = null;
    _zoneColors.clear();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _close();
    _onDispose?.call();
  }
}
