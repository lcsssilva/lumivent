// Gigabyte RX 9060 XT RGB controller: I²C protocol (phase 7).
//
// The byte layout comes from the protocol notes (`docs/hardware.md`). Every
// packet is 64 bytes and
// goes to the GPU's OEM I²C adapter at 7-bit address 0x75.
//
// Safety: the controller's identity is read before any effect write (SSID
// 0x2429). Commands that persist or synchronise the controller (0x13, 0x16,
// 0x17, 0x18) are never sent: a wrong packet could leave the GPU in a state
// that only a power cycle fixes.

import 'dart:typed_data';

/// Adapter name exposed by `amdgpu` for the GPU lighting controller. It is the
/// `ADL` "OEM" line; the display DDC buses must not be used.
const gpuI2cBusName = 'AMDGPU DM i2c OEM bus';

/// 7-bit address of the LED controller.
const gpuI2cAddress = 0x75;

/// Fixed packet size of the controller.
const gpuPacketLength = 64;

/// Every command is answered with 4 bytes.
const gpuReadLength = 4;

/// Subsystem ID of the supported board (Gigabyte RX 9060 XT GAMING OC 8G).
const gpuSsid = 0x2429;

const gpuCommandFirmware = 0x10;
const gpuCommandSsid = 0x11;
const gpuCommandEffect = 0x12;

/// Save, sync and two unknown registers: blocked by [checkGpuPacket].
const gpuCommandSave = 0x13;
const gpuCommandSync = 0x16;
const gpuCommandBlocked17 = 0x17;
const gpuCommandBlocked18 = 0x18;

/// The vendor software waits 200 ms after an identification read and 120 ms after an effect
/// write. The write wait is a hard requirement: at most ~8 effects/s.
const gpuReadSettle = Duration(milliseconds: 200);
const gpuEffectGap = Duration(milliseconds: 120);

const gpuSpeedMax = 10;
const gpuBrightnessMax = 10;

/// Firmware effect codes for device 1.
///
/// [style] is the user-facing effect id; the
/// firmware code is what goes in `packet[2]`. The two orders differ, so the
/// mapping is explicit instead of relying on the enum index.
enum GpuEffectCode {
  off(0x00, 0, 'Off'),
  staticColor(0x01, 1, 'Static'),
  pulse(0x02, 2, 'Pulse'),
  flash(0x03, 4, 'Flash'),
  doubleFlash(0x04, 8, 'DFlash'),
  cycle(0x05, 3, 'Cycle'),
  wave(0x06, 7, 'Wave'),
  gradient(0x07, 5, 'Gradient'),
  colorShift(0x08, 6, 'ColorShift', colors: 8),
  tricolor(0x09, 11, 'Tricolor'),
  dazzle(0x0A, 13, 'Dazzle'),
  rainbow(0x0B, 10, 'Rainbow'),
  claws(0x0C, 9, 'Claws');

  const GpuEffectCode(this.code, this.style, this.styleName, {this.colors = 0});

  /// Firmware byte written at `packet[2]`.
  final int code;

  /// User-facing effect id.
  final int style;

  /// Effect name, for logs and for matching the lighting domain enum.
  final String styleName;

  /// Palette size written in `packet[10]` and `packet[11..]` (0 = single
  /// color at `packet[5..7]`).
  final int colors;

  static GpuEffectCode? byCode(int code) =>
      values.where((e) => e.code == code).firstOrNull;

  static GpuEffectCode? byStyle(int style) =>
      values.where((e) => e.style == style).firstOrNull;

  /// Matches the lighting domain enum by name (`staticColor`, `doubleFlash`…).
  static GpuEffectCode? byName(String name) =>
      values.where((e) => e.name == name).firstOrNull;
}

/// One color in device order.
class GpuRgb {
  const GpuRgb(this.r, this.g, this.b)
    : assert(r >= 0 && r <= 255),
      assert(g >= 0 && g <= 255),
      assert(b >= 0 && b <= 255);

  static const black = GpuRgb(0, 0, 0);

  final int r, g, b;

  @override
  bool operator ==(Object other) =>
      other is GpuRgb && other.r == r && other.g == g && other.b == b;

  @override
  int get hashCode => Object.hash(r, g, b);

  @override
  String toString() => 'GpuRgb($r,$g,$b)';
}

/// Safety guard failure. The message is user-facing (Portuguese).
class GpuGuardException implements Exception {
  const GpuGuardException(this.message);
  final String message;
  @override
  String toString() => 'GpuGuardException: $message';
}

bool _isAllowedCommand(int command) =>
    command == gpuCommandFirmware ||
    command == gpuCommandSsid ||
    command == gpuCommandEffect;

bool _isBlockedCommand(int command) =>
    command == gpuCommandSave ||
    command == gpuCommandSync ||
    command == gpuCommandBlocked17 ||
    command == gpuCommandBlocked18;

/// Validates [packet] before it reaches the bus.
///
/// [busValidated] must only be `true` for the adapter found by [gpuI2cBusName]
/// (never for a display DDC bus). [ssidValidated] must be `true` after a
/// successful [gpuSsid] read; it is required for every `0x12`.
void checkGpuPacket(
  Uint8List packet, {
  required int address,
  required bool busValidated,
  required bool ssidValidated,
}) {
  if (!busValidated) {
    throw const GpuGuardException(
      'unvalidated bus: GPU RGB only uses the amdgpu OEM',
    );
  }
  if (address != gpuI2cAddress) {
    throw GpuGuardException(
      'address 0x${address.toRadixString(16)} is not the GPU controller '
      '(0x${gpuI2cAddress.toRadixString(16)})',
    );
  }
  if (packet.length != gpuPacketLength) {
    throw GpuGuardException(
      'packet has ${packet.length} B; the controller requires $gpuPacketLength B',
    );
  }
  final command = packet[0];
  if (_isBlockedCommand(command)) {
    throw GpuGuardException(
      'command 0x${command.toRadixString(16)} blocked for safety '
      '(save/sync are not used by the app)',
    );
  }
  if (!_isAllowedCommand(command)) {
    throw GpuGuardException(
      'command 0x${command.toRadixString(16)} not allowed; '
      'only 0x10, 0x11 and 0x12',
    );
  }
  if (packet[1] != 0x01) {
    throw GpuGuardException(
      'byte 1 = 0x${packet[1].toRadixString(16)}; expected 0x01',
    );
  }

  if (command == gpuCommandFirmware || command == gpuCommandSsid) {
    for (var i = 2; i < gpuPacketLength; i++) {
      if (packet[i] != 0) {
        throw GpuGuardException(
          'identification command with garbage at [$i]; expected zero',
        );
      }
    }
    return;
  }

  // 0x12: effect packet.
  if (!ssidValidated) {
    throw const GpuGuardException(
      'SSID 0x2429 not confirmed yet; no 0x12 effect is sent',
    );
  }
  final effect = GpuEffectCode.byCode(packet[2]);
  if (effect == null) {
    throw GpuGuardException('unknown effect 0x${packet[2].toRadixString(16)}');
  }
  if (packet[3] > gpuSpeedMax) {
    throw GpuGuardException('speed ${packet[3]} outside 0–$gpuSpeedMax');
  }
  if (packet[4] > gpuBrightnessMax) {
    throw GpuGuardException(
      'brightness ${packet[4]} outside 0–$gpuBrightnessMax',
    );
  }
  if (packet[9] != 0) {
    throw GpuGuardException('zone index ${packet[9]}; this board uses 0');
  }

  final count = packet[10];
  if (effect.colors == 0) {
    if (count != 0) {
      throw GpuGuardException(
        '${effect.styleName} has no palette, but the packet declares $count colors',
      );
    }
    for (var i = 10; i < gpuPacketLength; i++) {
      if (packet[i] != 0) {
        throw GpuGuardException(
          '${effect.styleName} has a palette at [$i], but it uses only the single color',
        );
      }
    }
    return;
  }
  if (count != effect.colors) {
    throw GpuGuardException(
      '${effect.styleName} requires ${effect.colors} colors; the packet declares $count',
    );
  }
  for (var i = 11 + 3 * effect.colors; i < gpuPacketLength; i++) {
    if (packet[i] != 0) {
      throw GpuGuardException('garbage after the palette at [$i]');
    }
  }
}

/// Identification packet: command + 0x01 + zeros.
Uint8List buildGpuCommand(int command) {
  final packet = Uint8List(gpuPacketLength);
  packet[0] = command;
  packet[1] = 0x01;
  return packet;
}

/// Effect packet (`0x12`).
///
/// [colors] is only used by [GpuEffectCode.colorShift] (8 entries); missing
/// entries are filled with black. Speed and brightness are clamped to 0–10 so
/// a bad config never produces an out-of-range packet.
Uint8List buildGpuEffectPacket({
  required GpuEffectCode effect,
  required int speed,
  required int brightness,
  required GpuRgb color,
  List<GpuRgb> colors = const [],
}) {
  final packet = Uint8List(gpuPacketLength);
  // The vendor software forces the color to black when the effect is Off; zero the whole
  // visible payload as well so an Off can never carry stale levels.
  final off = effect == GpuEffectCode.off;
  packet[0] = gpuCommandEffect;
  packet[1] = 0x01;
  packet[2] = effect.code;
  packet[3] = off ? 0 : speed.clamp(0, gpuSpeedMax);
  packet[4] = off ? 0 : brightness.clamp(0, gpuBrightnessMax);
  packet[5] = off ? 0 : color.r;
  packet[6] = off ? 0 : color.g;
  packet[7] = off ? 0 : color.b;
  packet[8] = 0; // angle/direction: not exposed
  packet[9] = 0; // zone index: this board has one
  if (effect.colors > 0) {
    packet[10] = effect.colors;
    for (var i = 0; i < effect.colors; i++) {
      final c = i < colors.length ? colors[i] : GpuRgb.black;
      final o = 11 + 3 * i;
      packet[o] = c.r;
      packet[o + 1] = c.g;
      packet[o + 2] = c.b;
    }
  }
  return packet;
}

/// Firmware version from a `0x10` read, or `null` when the answer does not
/// look like the controller's (other tools expect status 1 and family 1/2).
({String version, bool is4N})? parseGpuFirmware(Uint8List data) {
  if (data.length < gpuReadLength) return null;
  if (data[0] != 0x01 || (data[1] != 0x01 && data[1] != 0x02)) return null;
  return (version: '${data[2]}.${data[3]}', is4N: data[1] == 0x02);
}

/// SSID from a `0x11` read (`data[2] << 8 | data[3]`), or `null` when the
/// answer does not look like the controller's.
///
/// The RX 9060 XT answers `02 01 24 29` (read on Linux, 2026-10-20): byte 0 is
/// 0x02 here, not the 0x01 of the firmware answer. Only bytes `[2..3]` matter
/// for identification; the guard still requires the
/// SSID itself to be 0x2429 before any effect.
int? parseGpuSsid(Uint8List data) {
  if (data.length < gpuReadLength) return null;
  if ((data[0] != 0x01 && data[0] != 0x02) ||
      (data[1] != 0x01 && data[1] != 0x02)) {
    return null;
  }
  return (data[2] << 8) | data[3];
}
