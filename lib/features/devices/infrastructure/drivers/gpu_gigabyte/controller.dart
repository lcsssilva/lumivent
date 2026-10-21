// Gigabyte RX 9060 XT RGB controller (phase 7).
//
// The controller sits on the amdgpu OEM I²C adapter at 0x75. The driver only
// accepts that adapter (found by name), reads the firmware and the SSID before
// any effect packet, and waits 120 ms after every 0x12. It never saves/syncs
// the controller (0x13/0x16/0x17/0x18 are blocked by `protocol.dart`).
//
// Every command (and the read that answers it) runs under the adapter lock
// (`I2cTransport.exclusive`): the device probe and the lighting worker open
// the bus separately and must not interleave their transfers.
//
// All calls are blocking. The lighting module owns one in its own I/O worker,
// so the 120 ms wait never reaches the engine isolate. The device probe runs
// [GpuController.init] in the engine isolate: it sleeps only the 200 ms between
// the two identification reads; the settle after the last read becomes a
// quiet window that the next command (if any) waits for.

import 'dart:io' as io;
import 'dart:typed_data';

import '../../../../../core/platform/raw_i2c_ffi.dart';
import '../../../../../core/platform/smbus_ffi.dart' show findI2cBusByName;
import 'protocol.dart';

/// Failure while opening the adapter; [permissionDenied] maps to the udev hint.
class GpuException implements Exception {
  const GpuException(this.message, {this.permissionDenied = false});
  final String message;
  final bool permissionDenied;
  @override
  String toString() => message;
}

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
        'adaptador "$gpuI2cBusName" ausente: o amdgpu não expôs o OEM',
      );
    }
    try {
      final bus = RawI2cBus.open(path, address: gpuI2cAddress);
      return GpuController(bus, busPath: path, now: now, sleep: sleep);
    } on RawI2cException catch (e) {
      throw GpuException(
        e.permissionDenied
            ? 'sem permissão em $path (regra udev do OEM do amdgpu)'
            : 'não foi possível abrir $path: $e',
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

  /// Why the controller cannot be used (Portuguese, user-facing).
  String? get disabledReason => _disabledReason;

  /// Reads firmware (`0x10`) and SSID (`0x11`). Required before any `0x12`;
  /// safe to call again on the retry timer.
  bool init() {
    if (_closed) {
      _disabledReason = 'controlador da GPU já foi fechado';
      return false;
    }
    _ssidValidated = false;
    _disabledReason = null;

    final fwData = _readCommand(gpuCommandFirmware);
    if (fwData == null) return false;
    final fw = parseGpuFirmware(fwData);
    if (fw == null) {
      _disabledReason = 'resposta inesperada ao firmware 0x10: ${_hex(fwData)}';
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
      _disabledReason = 'resposta inesperada ao SSID 0x11: ${_hex(ssidData)}';
      return false;
    }
    _ssid = ssid;
    // It sleeps here too; a quiet window instead keeps the probe (which
    // closes the bus right after) from blocking its isolate for nothing.
    _notBefore = _now().add(gpuReadSettle);
    if (ssid != gpuSsid) {
      _disabledReason =
          'SSID 0x${ssid.toRadixString(16).padLeft(4, '0').toUpperCase()} '
          'difere de 0x2429: modelo não validado';
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
      _disabledReason = 'controlador da GPU já foi fechado';
      return false;
    }
    if (!_ssidValidated) {
      _disabledReason ??=
          'SSID 0x2429 não confirmado: o efeito 0x12 não é enviado';
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
      _disabledReason = 'escrita 0x12 falhou: ${e.message} (errno ${e.errno})';
      return false;
    } on Object catch (e) {
      _disabledReason = 'escrita 0x12 falhou: $e';
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
          'leitura do comando 0x${command.toRadixString(16)} falhou: '
          '${e.message} (errno ${e.errno})';
      return null;
    } on Object catch (e) {
      _disabledReason =
          'leitura do comando 0x${command.toRadixString(16)} falhou: $e';
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
