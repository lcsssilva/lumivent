// Per-zone hardware effects: `CC (20+z)` + `DataFormat_8297` (ITE §1.3–1.4).
import 'protocol.dart';

enum IteHardwareMode {
  staticColor,
  pulse,
  flash,
  doubleFlash,
  colorCycle,
  wave,
}

/// `LedBrightness[bri]` (ITE §1.4).
const iteBrightnessTable = [
  0x1A,
  0x33,
  0x4D,
  0x66,
  0x80,
  0x99,
  0xB3,
  0xCC,
  0xFF,
  0xFF,
];

const _pulseTiming = [1600, 1400, 1200, 1000, 900, 800, 700, 600, 500, 400];
const _cycleTiming = [
  (2400, 2200), (1100, 900), (1000, 800), (900, 700), (800, 600),
  (700, 500), (600, 400), (500, 300), (400, 200), (300, 100), //
];
const _waveTiming = [300, 250, 205, 165, 130, 100, 75, 55, 40, 30];

/// A hardware effect: mode + color + speed and brightness (0–9).
class IteHardwareEffect {
  const IteHardwareEffect(
    this.mode, {
    required this.color,
    this.speed = 5,
    this.brightness = 9,
  });

  final IteHardwareMode mode;
  final (int, int, int) color;
  final int speed;
  final int brightness;

  /// The 32 bytes of `DataFormat_8297` for zone [z] (0..6).
  List<int> dataFormat(int z) {
    final sp = speed.clamp(0, 9);
    final bri = brightness.clamp(0, 9);
    final b = List<int>.filled(32, 0);
    void u16(int off, int v) {
      b[off] = v & 0xFF;
      b[off + 1] = (v >> 8) & 0xFF;
    }

    b[0] = 1 << z; // Zone_Sel0
    var maxBri = iteBrightnessTable[bri];
    switch (mode) {
      case IteHardwareMode.staticColor:
        b[9] = 1;
        maxBri = iteBrightnessTable[bri > 8 ? 8 : bri];
        u16(20, 0);
      case IteHardwareMode.pulse:
        b[9] = 2;
        maxBri = 100;
        u16(20, _pulseTiming[sp]);
        u16(22, _pulseTiming[sp]);
        u16(24, 200);
        b[29] = 1;
      case IteHardwareMode.flash:
      case IteHardwareMode.doubleFlash:
        final dbl = mode == IteHardwareMode.doubleFlash;
        b[9] = 3;
        u16(20, 100);
        u16(22, 100);
        u16(24, (dbl ? 2600 : 2400) - 200 * sp);
        b[29] = 1;
        b[30] = dbl ? 2 : 1;
      case IteHardwareMode.colorCycle:
        b[9] = 4;
        u16(20, _cycleTiming[sp].$1);
        u16(22, _cycleTiming[sp].$2);
        b[28] = 7;
      case IteHardwareMode.wave:
        b[9] = 6;
        u16(20, _waveTiming[sp]);
        // wTime_base1 is also required: with only wT0 the zone stays dark
        // (checked on the B650E ITE; the doc's Wave row lists only wT0).
        u16(22, _waveTiming[sp]);
        b[28] = 7;
        b[29] = 1;
    }
    b[10] = maxBri;
    b[11] = 0;
    // dwColor0 = 0x00RRGGBB in little-endian: bytes BB GG RR 00.
    b[12] = color.$3;
    b[13] = color.$2;
    b[14] = color.$1;
    return b;
  }

  /// `CC (20+z)` + `DataFormat_8297` in `buf[2..33]`.
  List<int> packet(int z) {
    if (z < 0 || z > iteZoneDLed2 - iteZoneIoShield1) {
      throw ArgumentError.value(z, 'z', '0..6');
    }
    final p = [iteReportId, iteZoneIoShield1 + z, ...dataFormat(z)];
    checkIteCommand(p);
    return p;
  }
}
