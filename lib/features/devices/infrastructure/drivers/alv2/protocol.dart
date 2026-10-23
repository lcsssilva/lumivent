import 'alv2_forbidden_packet.dart';

// Lian Li UNI FAN AL V2 (hub `0CF2:A104`): packets from `AL-V2-protocolo.md`.

const alv2VendorId = 0x0CF2;
const alv2ProductId = 0xA104;

/// HID interface with `E0` reports (0 is only keyboard/consumer input).
const alv2Interface = 1;
const alv2ReportId = 0xE0;
const alv2FeatureLength = 7;

/// Output report (ID + 352): colors are sent through it (AL-V2 §1, §2).
const alv2OutputLength = 353;
const alv2InputLength = 65;

/// Pause between packets that the firmware needs (AL-V2 §2).
const alv2PacketGap = Duration(milliseconds: 20);

/// Pause between lighting packets (AL-V2 §3.3: 5 ms between write/commit).
const alv2LightingGap = Duration(milliseconds: 5);

/// Pause between packets while streaming canvas frames. Measured on hardware
/// (2026-10-19): 2 ms works, 1 ms makes the firmware drop packets.
const alv2StreamGap = Duration(milliseconds: 2);

/// Lighting ports (2 per group: even = inner ring, odd = outer ring).
const alv2Ports = 8;

/// Maximum fans per group.
const alv2MaxFans = 6;

const alv2ReadFirmware = [0xE0, 0x50, 0x01];

/// On hidraw, `hid_get_input_report` returns `[ID][payload]`: the `E0` appears
/// twice. Removes the first one.
List<int> alv2InputPayload(List<int> raw) => raw.sublist(1);

/// Firmware version from the `E0 50 80 C6 vv` payload (AL-V2 §8): high nibble
/// is major, low nibble is minor. `null` if this is not the expected response.
String? parseAlv2Firmware(List<int> payload) {
  if (payload.length < 5 ||
      payload[0] != 0xE0 ||
      payload[1] != 0x50 ||
      payload[2] != 0x80 ||
      payload[3] != 0xC6) {
    return null;
  }
  final v = payload[4];
  return '${v >> 4}.${v & 0x0F}';
}

const alv2ReadRpm = [0xE0, 0x50, 0x00];

/// Hub groups (physical ports).
const alv2Groups = 4;

/// RPM of the 4 groups from the payload `F0 hh ll hh ll…` (AL-V2 §2, §8):
/// u16 big-endian after the `F0` status. `null` if it is another response (the
/// The input buffer is shared; leftover data from a firmware request starts
/// with `E0`).
List<int>? parseAlv2Rpm(List<int> payload) {
  if (payload.length < 1 + 2 * alv2Groups || payload[0] != 0xF0) return null;
  return [
    for (var g = 0; g < alv2Groups; g++)
      payload[2 * g + 1] << 8 | payload[2 * g + 2],
  ];
}

/// Duty packet for group [group] (0–3): `E0 (20|g) 00 duty`. Duty is clamped
/// to 1–100 (1 is the firmware stop value; 0 is never sent).
List<int> alv2DutyPacket(int group, int duty) {
  _checkGroup(group);
  return [alv2ReportId, 0x20 | group, 0x00, duty.clamp(1, 100)];
}

/// RPM sync packet with the group [group] motherboard:
/// `E0 10 62 m 00 00`, with `m = (1 << (g + 4)) | (sync ? 1 : 0) << g`.
List<int> alv2MotherboardSyncPacket(int group, List<bool> sync) {
  _checkGroup(group);
  if (sync.length != alv2Groups) {
    throw ArgumentError.value(sync.length, 'sync.length', 'expected 4 values');
  }
  final m = (1 << (group + 4)) | ((sync[group] ? 1 : 0) << group);
  return [alv2ReportId, 0x10, 0x62, m, 0x00, 0x00];
}

/// The 4 sync packets (one per group) for the list [sync].
List<List<int>> alv2MotherboardSyncPackets(List<bool> sync) => [
  for (var g = 0; g < alv2Groups; g++) alv2MotherboardSyncPacket(g, sync),
];

// --- Lighting (AL-V2 §2, §6) ---

/// Effect for port [port] (0–7): `E0 (10|p) mode speed direction brightness`.
List<int> alv2EffectPacket(
  int port,
  int mode,
  int speed,
  int direction,
  int brightness,
) {
  _checkPort(port);
  return [alv2ReportId, 0x10 | port, mode, speed, direction, brightness];
}

/// Colors for port [port]: `E0 (30|p)` + N × `R B G` (R, B, G order, AL-V2 §2).
/// [rgb] is a flat R,G,B,R,G,B… list; input is RGB and output is reordered.
List<int> alv2ColorPacket(int port, List<int> rgb) {
  _checkPort(port);
  if (rgb.length % 3 != 0 || 2 + rgb.length > alv2OutputLength) {
    throw ArgumentError.value(rgb.length, 'rgb.length', 'invalid color list');
  }
  final out = [alv2ReportId, 0x30 | port];
  for (var i = 0; i + 2 < rgb.length; i += 3) {
    out
      ..add(rgb[i] & 0xFF)
      ..add(rgb[i + 2] & 0xFF)
      ..add(rgb[i + 1] & 0xFF);
  }
  return out;
}

/// Frame commit (the service always sends frame = 1).
const alv2FramePacket = [alv2ReportId, 0x60, 0x00, 0x01];

/// Fan quantity of group [group]: `E0 10 60 (g+1) q 00`, q 0–6.
List<int> alv2QuantityPacket(int group, int quantity) {
  _checkGroup(group);
  return [
    alv2ReportId,
    0x10,
    0x60,
    group + 1,
    quantity.clamp(0, alv2MaxFans),
    0x00,
  ];
}

/// Merge order: `E0 10 63 o0 o1 o2 o3 08`. It has 8 bytes, but the feature report
/// has 7: the final `08` never reaches the device (AL-V2 §7); the hub sends 7.
List<int> alv2MergeOrderPacket(List<int> order) {
  if (order.length != alv2Groups) {
    throw ArgumentError.value(order.length, 'order.length', 'expected 4');
  }
  for (final o in order) {
    _checkGroup(o);
  }
  return [alv2ReportId, 0x10, 0x63, ...order, 0x08];
}

/// Motherboard ARGB sync, **disable only** (safety, AL-V2 §8: enabling clears everything).
const alv2ArgbSyncOffPacket = [alv2ReportId, 0x10, 0x61, 0x00, 0x00, 0x00];

/// Ping/identify group [group]: `E0 (10|2g) 36 00 00 02` (AL-V2 §2, §8).
List<int> alv2PingPacket(int group) {
  _checkGroup(group);
  return [alv2ReportId, 0x10 | (2 * group), 0x36, 0x00, 0x00, 0x02];
}

/// Ping with merge active (group ≠ 0): `E0 10 50 g 00 00`.
List<int> alv2MergePingPacket(int group) {
  _checkGroup(group);
  return [alv2ReportId, 0x10, 0x50, group, 0x00, 0x00];
}

/// UI speed level (0–4) → byte: `02/01/00/FF/FE` (AL-V2 §6).
int alv2SpeedByte(int level) =>
    const [0x02, 0x01, 0x00, 0xFF, 0xFE][level.clamp(0, 4)];

/// UI brightness level (0–4) → byte: `08/03/02/01/00`. 0 = off.
int alv2BrightnessByte(int level) =>
    const [0x08, 0x03, 0x02, 0x01, 0x00][level.clamp(0, 4)];

void _checkGroup(int group) {
  if (group < 0 || group >= alv2Groups) {
    throw ArgumentError.value(group, 'group', 'outside 0..3');
  }
}

void _checkPort(int port) {
  if (port < 0 || port >= alv2Ports) {
    throw ArgumentError.value(port, 'port', 'outside 0..7');
  }
}

/// Throws [Alv2ForbiddenPacket] if [bytes] must not reach the hub. Every send
/// goes through here (the hub `_write`): report ID `E0`, size within the
/// 7-byte feature / 353-byte output report (an unpadded output report may be
/// any size from 2 to 353), port 0–7 on effect/color packets
/// and **no** motherboard ARGB sync enable (`E0 10 61` with a byte != 0
/// clears the hub, AL-V2 §8).
void checkAlv2Packet(List<int> bytes, {required bool output}) {
  if (bytes.isEmpty || bytes[0] != alv2ReportId) {
    throw Alv2ForbiddenPacket('report ID != E0');
  }
  final max = output ? alv2OutputLength : alv2FeatureLength;
  if (bytes.length < 2 || bytes.length > max) {
    throw Alv2ForbiddenPacket(
      'size ${bytes.length} outside 2..$max (${output ? 'output' : 'feature'})',
    );
  }
  final cmd = bytes[1];
  if (output) {
    // Output reports carry colors only: `E0 (30|p) ...`, p in 0..7.
    if (cmd < 0x30 || cmd >= 0x30 + alv2Ports) {
      throw Alv2ForbiddenPacket('output command ${_hex(cmd)} is not a color');
    }
    return;
  }
  if (cmd == 0x10 && bytes.length > 2 && bytes[2] == 0x61) {
    if (bytes.length < 4 || bytes.skip(3).any((b) => b != 0)) {
      throw Alv2ForbiddenPacket('motherboard ARGB sync enable (E0 10 61)');
    }
  }
  // Effect packets `E0 (10|p) mode ...` address ports 0..7 (0x10..0x17).
  if (cmd >= 0x10 && cmd < 0x18) return;
  if (cmd >= 0x20 && cmd < 0x24) return; // duty, groups 0..3
  if (cmd == 0x50 || cmd == 0x60) return; // reads, frame commit
  throw Alv2ForbiddenPacket('feature command ${_hex(cmd)} not allowed');
}

String _hex(int b) => b.toRadixString(16).padLeft(2, '0').toUpperCase();
