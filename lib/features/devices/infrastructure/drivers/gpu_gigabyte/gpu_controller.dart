import 'dart:io' as io;
import 'dart:typed_data';

import '../../../../../core/platform/raw_i2c_bus.dart';
import '../../../../../core/platform/i2c_transport.dart';
import '../../../../../core/platform/smbus.dart' show findI2cBusByName;
import 'protocol.dart';
import 'gpu_rgb.dart';
import 'gpu_guard_exception.dart';
import 'gpu_exception.dart';

class GpuController {
  GpuController(
    this._transport, {
    this.busPath,
    DateTime Function()? now,
    void Function(Duration)? sleep,
  }) : _now = now ?? DateTime.now,
       _sleep = sleep ?? io.sleep;

  /// Finds the OEM adapter and opens it. Throws [GpuException] when the
  /// adapter is absent or the user has no permission.
  ///
  /// The adapter name is the only accepted identity: DDC buses of monitors
  /// expose 0x50 (EDID) and are never touched by this driver.
  static GpuController open({
    String sysfsRoot = '/sys',
    DateTime Function()? now,
    void Function(Duration)? sleep,
  }) {
    final path = findI2cBusByName(gpuI2cBusName, sysfsRoot: sysfsRoot);
    if (path == null) {
      throw const GpuException(
        'adapter "$gpuI2cBusName" missing: amdgpu did not expose the OEM',
      );
    }
    try {
      final bus = RawI2cBus.open(path, address: gpuI2cAddress);
      return GpuController(bus, busPath: path, now: now, sleep: sleep);
    } on RawI2cException catch (e) {
      throw GpuException(
        e.permissionDenied
            ? 'no permission on $path (amdgpu OEM udev rule)'
            : 'could not open $path: $e',
        permissionDenied: e.permissionDenied,
      );
    }
  }

  final I2cTransport _transport;
  final DateTime Function() _now;
  final void Function(Duration) _sleep;

  /// `/dev/i2c-N` in use (number changes between boots).
  final String? busPath;

  String? _firmware;
  int? _ssid;
  bool _is4N = false;
  bool _ssidValidated = false;
  bool _closed = false;
  String? _disabledReason;

  /// The controller must not receive a command before this instant (settle
  /// after an identification read, pause after a 0x12).
  DateTime? _notBefore;

  String? get firmware => _firmware;
  int? get ssid => _ssid;
  bool get is4N => _is4N;

  /// Why the controller cannot be used (English technical message).
  String? get disabledReason => _disabledReason;

  /// Reads firmware (`0x10`) and SSID (`0x11`). Required before any `0x12`;
  /// safe to call again on the retry timer.
  bool init() {
    if (_closed) {
      _disabledReason = 'GPU controller is already closed';
      return false;
    }
    _ssidValidated = false;
    _disabledReason = null;

    final fwData = _readCommand(gpuCommandFirmware);
    if (fwData == null) return false;
    final fw = parseGpuFirmware(fwData);
    if (fw == null) {
      _disabledReason = 'unexpected reply to firmware 0x10: ${_hex(fwData)}';
      return false;
    }
    _firmware = fw.version;
    _is4N = fw.is4N;
    // The vendor software sleeps after each identification read before talking again.
    _sleep(gpuReadSettle);

    final ssidData = _readCommand(gpuCommandSsid);
    if (ssidData == null) return false;
    final ssid = parseGpuSsid(ssidData);
    if (ssid == null) {
      _disabledReason = 'unexpected reply to SSID 0x11: ${_hex(ssidData)}';
      return false;
    }
    _ssid = ssid;
    // It sleeps here too; a quiet window instead keeps the probe (which
    // closes the bus right after) from blocking its isolate for nothing.
    _notBefore = _now().add(gpuReadSettle);
    if (ssid != gpuSsid) {
      _disabledReason =
          'SSID 0x${ssid.toRadixString(16).padLeft(4, '0').toUpperCase()} '
          'differs from 0x2429: model not validated';
      return false;
    }
    _ssidValidated = true;
    _disabledReason = null;
    return true;
  }

  /// Writes one effect (`0x12`). Fails unless [init] confirmed SSID 0x2429.
  ///
  /// The method returns after [gpuEffectGap], so the next call already respects
  /// the controller's pause.
  bool sendEffect({
    required GpuEffectCode effect,
    required int speed,
    required int brightness,
    required GpuRgb color,
    List<GpuRgb> colors = const [],
  }) {
    if (_closed) {
      _disabledReason = 'GPU controller is already closed';
      return false;
    }
    if (!_ssidValidated) {
      _disabledReason ??= 'SSID 0x2429 not confirmed: effect 0x12 is not sent';
      return false;
    }
    final packet = buildGpuEffectPacket(
      effect: effect,
      speed: speed,
      brightness: brightness,
      color: color,
      colors: colors,
    );
    try {
      checkGpuPacket(
        packet,
        address: gpuI2cAddress,
        busValidated: true,
        ssidValidated: _ssidValidated,
      );
      _waitQuiet();
      _transport.exclusive(() => _transport.write(packet));
      _notBefore = _now().add(gpuEffectGap);
      _sleep(gpuEffectGap);
      return true;
    } on GpuGuardException catch (e) {
      _disabledReason = e.message;
      return false;
    } on RawI2cException catch (e) {
      _disabledReason = '0x12 write failed: ${e.message} (errno ${e.errno})';
      return false;
    } on Object catch (e) {
      _disabledReason = '0x12 write failed: $e';
      return false;
    }
  }

  /// Effect 0 with black and brightness 0 (the "turn all ARGB off" path).
  ///
  /// Off is also a `0x12`, so it needs the SSID guard too. When the engine
  /// starts with ARGB already off it never called [init]; this method reads the
  /// identity itself instead of requiring a second path in the engine.
  bool turnOff() {
    if (!_ssidValidated && !init()) return false;
    return sendEffect(
      effect: GpuEffectCode.off,
      speed: 0,
      brightness: 0,
      color: GpuRgb.black,
    );
  }

  /// Forgets the identity so the next [init] reads it again (resume/restore).
  void invalidate() {
    _ssidValidated = false;
    _disabledReason = null;
  }

  Uint8List? _readCommand(int command) {
    final packet = buildGpuCommand(command);
    try {
      checkGpuPacket(
        packet,
        address: gpuI2cAddress,
        busValidated: true,
        ssidValidated: _ssidValidated,
      );
      _waitQuiet();
      return _transport.exclusive(() {
        _transport.write(packet);
        return _transport.read(gpuReadLength);
      });
    } on GpuGuardException catch (e) {
      _disabledReason = e.message;
      return null;
    } on RawI2cException catch (e) {
      _disabledReason =
          'read of command 0x${command.toRadixString(16)} failed: '
          '${e.message} (errno ${e.errno})';
      return null;
    } on Object catch (e) {
      _disabledReason =
          'read of command 0x${command.toRadixString(16)} failed: $e';
      return null;
    }
  }

  void _waitQuiet() {
    final until = _notBefore;
    if (until == null) return;
    final wait = until.difference(_now());
    if (wait > Duration.zero) _sleep(wait);
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _ssidValidated = false;
    _transport.close();
  }

  static String _hex(Uint8List data) =>
      data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
}
