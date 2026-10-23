// AL V2 color payload normalization (AL-V2 §2) and port write assembly
// (AL-V2 §2, §4). Pure Dart, no I/O.
import 'protocol.dart';
import 'alv2_port_write.dart';
import 'alv2_effect.dart';
import 'lighting.dart';

const _black = [0, 0, 0];

/// Color [i] from [colors] (flat R,G,B), or black if missing.
List<int> _at(List<int> colors, int i) =>
    (i + 1) * 3 <= colors.length ? colors.sublist(i * 3, i * 3 + 3) : _black;

/// Color payload of [mode] from the UI colors [colors] (flat R,G,B).
/// Returns 48 (inner), 72 (outer) or 36 colors as a flat R,G,B list, or
/// an empty list if [colors] is empty (then no color packet is sent).
/// Missing color (fewer colors than fans/corners) becomes black.
List<int> alv2NormalizeColors(Alv2LightMode mode, List<int> colors) {
  if (colors.length < 3) return const [];
  final n = colors.length ~/ 3;
  final out = <int>[];
  switch (mode.uiId) {
    case 62 || 36: // 6 fans × 8 LEDs, fan i = color i
      for (var f = 0; f < alv2MaxFans; f++) {
        for (var l = 0; l < 8; l++) {
          out.addAll(_at(colors, f));
        }
      }
    case 70 || 92: // 6 fans × 12 LEDs, fan i = color i
      for (var f = 0; f < alv2MaxFans; f++) {
        for (var l = 0; l < 12; l++) {
          out.addAll(_at(colors, f));
        }
      }
    case 71 || 93: // per fan: corner j (4 × 3 LEDs) = color j
      for (var f = 0; f < alv2MaxFans; f++) {
        for (var c = 0; c < 4; c++) {
          for (var l = 0; l < 3; l++) {
            out.addAll(_at(colors, c));
          }
        }
      }
    case 12 || 47 || 80: // Meteor: 6 blocks × 6 colors, cyclic
      for (var b = 0; b < 6; b++) {
        for (var j = 0; j < 6; j++) {
          out.addAll(_at(colors, j % n));
        }
      }
    default: // 6 blocks × 6 colors, black after the nth color
      for (var b = 0; b < 6; b++) {
        for (var j = 0; j < 6; j++) {
          out.addAll(_at(colors, j));
        }
      }
  }
  return out;
}

/// Scales RGB by brightness (level 0–4 → 0/25/50/75/100%, `floor`), as the UI
/// does for static modes (AL-V2 §6).
List<int> alv2ScaleByBrightness(List<int> rgb, int brightnessLevel) {
  final pct = brightnessLevel.clamp(0, 4) * 25;
  return [for (final c in rgb) (c * pct) ~/ 100];
}

Alv2PortWrite _portWrite(int port, Alv2LightMode mode, Alv2Effect e) {
  var colors = e.colors;
  if (mode.isStatic) colors = alv2ScaleByBrightness(colors, e.brightnessLevel);
  return Alv2PortWrite(
    port: port,
    mode: mode.byte,
    speed: alv2SpeedByte(e.speedLevel),
    direction: e.direction & 1,
    brightness: alv2BrightnessByte(e.brightnessLevel),
    colors: alv2NormalizeColors(mode, colors),
  );
}

/// Whole-fan mode of group [group]. Split modes become two ports
/// (2g+1 outer, 2g inner) with the same byte and colors converted per ring;
/// the others write only port 2g. Service order: highest port first, colors
/// before the effect (the order within each port is [Alv2PortWrite]).
List<Alv2PortWrite> alv2WholeWrites(int group, Alv2Effect e) {
  assert(e.mode.scope == Alv2LightScope.whole);
  final inner = e.mode.splitInner, outer = e.mode.splitOuter;
  if (inner == null || outer == null) return [_portWrite(2 * group, e.mode, e)];
  return [_portWrite(2 * group + 1, outer, e), _portWrite(2 * group, inner, e)];
}

/// Inner + outer pair of group [group] (individual mode).
List<Alv2PortWrite> alv2PairWrites(
  int group,
  Alv2Effect inner,
  Alv2Effect outer,
) {
  assert(
    inner.mode.scope == Alv2LightScope.inner &&
        outer.mode.scope == Alv2LightScope.outer,
  );
  return [
    _portWrite(2 * group + 1, outer.mode, outer),
    _portWrite(2 * group, inner.mode, inner),
  ];
}

/// Merge: port 0 with the merge mode and the colors; ports 1–7 with Rainbow `0x2B`,
/// brightness `08` (off) and no colors (AL-V2 §3). From port 7 down to 0.
List<Alv2PortWrite> alv2MergeWrites(Alv2Effect e) {
  assert(e.mode.scope == Alv2LightScope.merge);
  return [
    for (var p = alv2Ports - 1; p > 0; p--) _idleRainbow(p),
    _portWrite(0, e.mode, e),
  ];
}

Alv2PortWrite _idleRainbow(int port) => Alv2PortWrite(
  port: port,
  mode: Alv2LightMode.rainbow.byte,
  brightness: 0x08,
);

/// Turn everything off: effect with brightness `08` on all ports (7 → 0), without
/// colors. The mode is Rainbow `0x2B`, as on idle merge ports.
List<Alv2PortWrite> alv2OffWrites() => [
  for (var p = alv2Ports - 1; p >= 0; p--) _idleRainbow(p),
];

/// Canvas streaming (AL-V2 §3.3.1) for group [group] with [fans]
/// fans. [leds] is the flat linear R,G,B list consumed by each fan:
/// 8 LEDs of the inner ring then 12 of the outer, repeating. Port 2g takes
/// `fans × 8` LEDs and 2g+1 `fans × 12`; static effect `0x01`, speed `0x02`
/// (as measured), direction and brightness `00`. Sending only the fans the
/// group has (not 6) and speed `02` were measured on hardware (2026-10-19):
/// together with unpadded reports and a 2 ms gap, 8.3 -> 19.2 fps. With no
/// fans there is nothing to write.
List<Alv2PortWrite> alv2CanvasWrites(int group, int fans, List<int> leds) {
  final count = fans.clamp(0, alv2MaxFans);
  if (count == 0) return const [];
  final inner = List<int>.filled(count * 8 * 3, 0);
  final outer = List<int>.filled(count * 12 * 3, 0);
  for (var f = 0; f < count; f++) {
    for (var i = 0; i < 8 * 3; i++) {
      final src = f * 20 * 3 + i;
      if (src < leds.length) inner[f * 8 * 3 + i] = leds[src];
    }
    for (var i = 0; i < 12 * 3; i++) {
      final src = f * 20 * 3 + 8 * 3 + i;
      if (src < leds.length) outer[f * 12 * 3 + i] = leds[src];
    }
  }
  final staticByte = Alv2LightMode.staticColorInner.byte;
  return [
    Alv2PortWrite(
      port: 2 * group + 1,
      mode: staticByte,
      speed: 0x02,
      colors: outer,
    ),
    Alv2PortWrite(
      port: 2 * group,
      mode: staticByte,
      speed: 0x02,
      colors: inner,
    ),
  ];
}

/// Orders writes for multiple groups like the service: highest port to lowest
/// (stable, preserving colors before the effect within each port).
List<Alv2PortWrite> alv2ServiceOrder(Iterable<Alv2PortWrite> writes) {
  final list = writes.toList();
  final idx = {for (var i = 0; i < list.length; i++) list[i]: i};
  list.sort((a, b) => a.port != b.port ? b.port - a.port : idx[a]! - idx[b]!);
  return list;
}
