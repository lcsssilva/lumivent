import 'ite_forbidden_command.dart';
import 'ite_color_order.dart';
import 'ite_calibration.dart';
import 'ite_info.dart';

// Gigabyte RGB Fusion 2 (MCU ITE IT5702, `048D:5702`): packets from the
// protocol notes (`docs/hardware.md`).

const iteVendorId = 0x048D;
const iteProductId = 0x5702;

/// HID collection for `CC` commands (`0x10` is not used).
const iteUsage = 0xCC;
const iteReportId = 0xCC;
const iteReportLength = 64;

const iteReadInfo = [0xCC, 0x60];

/// Commands this app never sends (ITE §1.2): writing to the MCU flash,
/// the two commands this firmware does not accept (`SuppCmdFlag = 0`) and
/// header 2 (`0x59`), connected to the AL V2 hub ARGB input (ITE §0.1.1).
const iteForbiddenCommands = <int, String>{
  0x5E: 'write to MCU flash',
  0x47: 'persist configuration after power-off (unsupported)',
  0x48: 'MSDL switch (unsupported)',
  0x59: 'D_LED2 data, which powers the hub ARGB input',
};

/// Throws [IteForbiddenCommand] if [packet] is forbidden, including
/// `CC 32` with bit1 (D_LED2). Every send to the ITE goes through here.
void checkIteCommand(List<int> packet) {
  if (packet.length < 2 || packet[0] != iteReportId) return;
  final cmd = packet[1];
  if (iteForbiddenCommands.containsKey(cmd)) throw IteForbiddenCommand(cmd);
  if (cmd == 0x32 && packet.length > 2 && packet[2] & iteDirectBitDLed2 != 0) {
    throw IteForbiddenCommand(cmd, 'D_LED2 direct mode (hub header 2)');
  }
}

/// Zones (`CC (20+z)` / static ID): ITE §1.5 and §2.4.1.
const iteZoneIoShield1 = 0x20;
const iteZone12v1 = 0x21; // empty
const iteZoneCpu = 0x22;
const iteZoneIoShield2 = 0x23;
const iteZone12v2 = 0x24; // empty
const iteZoneDLed1 = 0x25;
const iteZoneDLed2 = 0x26;

/// Board LEDs exposed by the app.
const iteBoardZones = [iteZoneIoShield1, iteZoneCpu, iteZoneIoShield2];

/// D_LED1 data header (case strip). `0x59` is never used.
const iteDLed1Header = 0x58;
const iteDirectBitDLed1 = 0x01;
const iteDirectBitDLed2 = 0x02;
const iteMaxLedsPerPacket = 19;

IteInfo? parseIteInfo(List<int> table) {
  if (table.length < 40 || table[0] != iteReportId) return null;
  final desc = String.fromCharCodes(
    table.sublist(12, 40).takeWhile((c) => c != 0),
  );
  int u32(int o) =>
      table[o] | table[o + 1] << 8 | table[o + 2] << 16 | table[o + 3] << 24;
  return IteInfo(
    firmware: table.sublist(4, 8).join('.'),
    description: desc,
    calibration: table.length < 64
        ? null
        : IteCalibration(
            strip3: u32(40),
            strip0: u32(44),
            strip1: u32(48),
            strip2: u32(52),
            chipId: u32(56),
            strip4: u32(60),
          ),
  );
}

/// `CC 32` bits: only bit 0 (D_LED1). Requesting bit 1 (D_LED2) throws.
List<int> iteDirectModePacket(int bits) {
  final p = [iteReportId, 0x32, bits];
  checkIteCommand(p);
  if (bits & ~iteDirectBitDLed1 != 0) {
    throw ArgumentError.value(bits, 'bits', 'only bit 0 is allowed');
  }
  return p;
}

/// `CC 34` count code (ITE §2.2).
int iteLedCountEnum(int leds) {
  if (leds <= 32) return 0;
  if (leds <= 64) return 1;
  if (leds <= 256) return 2;
  if (leds <= 512) return 3;
  if (leds <= 1024) return 4;
  throw ArgumentError.value(leds, 'leds', 'maximum of 1024 LEDs');
}

/// `CC 34 mask` for header 1 only (the high nibble from header 2 stays 0).
List<int> iteLedCountPacket(int leds) => [
  iteReportId,
  0x34,
  iteLedCountEnum(leds),
];

/// `CC <hdr> off_lo off_hi n data` (ITE §1.2). [offset] and [data] in bytes.
List<int> iteStreamPacket(int header, int offset, List<int> data) {
  final p = [
    iteReportId,
    header,
    offset & 0xFF,
    (offset >> 8) & 0xFF,
    data.length,
    ...data,
  ];
  checkIteCommand(p);
  if (header != iteDLed1Header) {
    throw ArgumentError.value(header, 'header', 'only 0x58 is allowed');
  }
  if (data.isEmpty || data.length > iteMaxLedsPerPacket * 3) {
    throw ArgumentError.value(
      data.length,
      'data.length',
      '1..57 bytes per packet',
    );
  }
  return p;
}

/// D_LED1 stream: [rgb] is the flat R,G,B… list; output uses [order],
/// in packets of up to 19 LEDs (47 LEDs → 57/57/27 bytes at offsets 0/57/114).
List<List<int>> iteStreamPackets(
  List<int> rgb, {
  IteColorOrder order = IteColorOrder.grb,
}) {
  if (rgb.isEmpty || rgb.length % 3 != 0) {
    throw ArgumentError.value(
      rgb.length,
      'rgb.length',
      'must be a non-empty multiple of 3',
    );
  }
  final wire = <int>[
    for (var i = 0; i < rgb.length; i += 3)
      ...order.bytes(rgb[i], rgb[i + 1], rgb[i + 2]),
  ];
  const chunk = iteMaxLedsPerPacket * 3;
  return [
    for (var off = 0; off < wire.length; off += chunk)
      iteStreamPacket(
        iteDLed1Header,
        off,
        wire.sublist(
          off,
          off + chunk > wire.length ? wire.length : off + chunk,
        ),
      ),
  ];
}

/// Static zone color (ITE §2.4): `[1]=zone [2]=1<<(zone-0x20)
/// [0x0B]=01 [0x0C]=5A [0x0D]=00 [0x0E..0x10]=color` in calibration order.
List<int> iteZoneStaticPacket(
  int zone,
  int r,
  int g,
  int b, {
  IteColorOrder order = IteColorOrder.bgr,
}) {
  if (zone < iteZoneIoShield1 || zone > iteZoneDLed2) {
    throw ArgumentError.value(zone, 'zone', '0x20..0x26');
  }
  final p = List<int>.filled(0x11, 0);
  p[0] = iteReportId;
  p[1] = zone;
  p[2] = 1 << (zone - iteZoneIoShield1);
  p[0x0B] = 0x01;
  p[0x0C] = 0x5A;
  p[0x0D] = 0x00;
  p.setRange(0x0E, 0x11, order.bytes(r, g, b));
  checkIteCommand(p);
  return p;
}

/// `CC 28 mask`: applies the zones (all = `FF`).
List<int> iteApplyPacket([int mask = 0xFF]) => [iteReportId, 0x28, mask & 0xFF];
