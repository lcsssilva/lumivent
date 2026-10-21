// AL V2 lighting modes (AL-V2 §3 tables, §6 metadata) and the
// port write assembly (AL-V2 §2, §4). Pure Dart, no I/O.
import 'protocol.dart';

enum Alv2LightScope { whole, inner, outer, merge }

/// UI metadata for a mode (AL-V2 §6).
///
/// §6 only describes "whole fan" modes. Interpretation: every mode has speed
/// except StaticColor ("no speed"); only modes with `dir` have direction.
/// Inner/outer modes and merge **inherit** the metadata of the whole-fan mode of
/// the same base name (inferred); Lottery, PacMan, and outer-ring
/// Colorful/Rainbow variants have no pair and use assumed values.
class Alv2ModeMeta {
  const Alv2ModeMeta({
    this.speed = true,
    this.direction = false,
    this.colors = 0,
    this.defaultSpeedLevel = 3,
    this.defaultDirection = 0,
    this.whiteDefault = false,
  });

  /// Has speed control.
  final bool speed;

  /// Has direction control.
  final bool direction;

  /// How many colors the UI lets the user pick.
  final int colors;

  /// Level 0–4 (default 75% = 3).
  final int defaultSpeedLevel;

  /// 0 = right, 1 = left.
  final int defaultDirection;

  /// ElectricCurrent: default white colors.
  final bool whiteDefault;

  /// Default colors (flat R,G,B): §4 factory palette (red, blue, green, yellow,
  /// orange, cyan), truncated to [colors]. For non-static modes this is inferred
  /// (`ALV2FanProfile..cctor` is not in the documents).
  List<int> get defaultColors => [
    for (var i = 0; i < colors; i++)
      ...(whiteDefault ? const [255, 255, 255] : alv2FactoryPalette[i % 6]),
  ];
}

/// Factory palette (AL-V2 §4). The exact orange is not documented.
const alv2FactoryPalette = <List<int>>[
  [255, 0, 0],
  [0, 0, 255],
  [0, 255, 0],
  [255, 255, 0],
  [255, 128, 0],
  [0, 255, 255],
];

const _rainbow = Alv2ModeMeta(direction: true);
const _morph = Alv2ModeMeta();
const _static = Alv2ModeMeta(speed: false, colors: 6);
const _breathing = Alv2ModeMeta(colors: 6);
const _taichi = Alv2ModeMeta(direction: true, colors: 2);
const _colorCycle = Alv2ModeMeta(direction: true, colors: 4);
const _two = Alv2ModeMeta(colors: 2);
const _four = Alv2ModeMeta(colors: 4);
const _fourDir = Alv2ModeMeta(direction: true, colors: 4);
const _wave = Alv2ModeMeta(colors: 1);
const _warning = Alv2ModeMeta(colors: 4, defaultSpeedLevel: 2);
const _teacups = Alv2ModeMeta(
  direction: true,
  colors: 4,
  defaultSpeedLevel: 1,
  defaultDirection: 1,
);
const _stack = Alv2ModeMeta(direction: true, colors: 2, defaultDirection: 1);
const _contest = Alv2ModeMeta(direction: true, colors: 3);
const _electric = Alv2ModeMeta(colors: 4, whiteDefault: true);
const _noColor = Alv2ModeMeta();
const _meteorRainbow = Alv2ModeMeta(direction: true);
const _staticColorful = Alv2ModeMeta(speed: false, colors: 4);
const _breathingColorful = Alv2ModeMeta(colors: 4);

/// All AL-V2 §3 modes. `uiId` is the vendor UI enum value and `byte` is the
/// code sent to firmware.
enum Alv2LightMode {
  // --- Whole fan (port 2g) ---
  rainbow('Rainbow', 16, 0x2B, Alv2LightScope.whole, _rainbow),
  rainbowMorph(
    'RainbowMorph',
    17,
    0x04,
    Alv2LightScope.whole,
    _morph,
    splitInnerId: 55,
    splitOuterId: 85,
  ),
  staticColor(
    'StaticColor',
    26,
    0x01,
    Alv2LightScope.whole,
    _static,
    splitInnerId: 62,
    splitOuterId: 92,
  ),
  breathing(
    'Breathing',
    1,
    0x02,
    Alv2LightScope.whole,
    _breathing,
    splitInnerId: 36,
    splitOuterId: 70,
  ),
  taichi('Taichi', 27, 0x2F, Alv2LightScope.whole, _taichi),
  colorCycle('ColorCycle', 3, 0x2E, Alv2LightScope.whole, _colorCycle),
  runway(
    'Runway',
    19,
    0x1A,
    Alv2LightScope.whole,
    _two,
    splitInnerId: 58,
    splitOuterId: 88,
  ),
  mopUp('MopUp', 14, 0x3E, Alv2LightScope.whole, _two),
  meteor(
    'Meteor',
    12,
    0x19,
    Alv2LightScope.whole,
    _fourDir,
    splitInnerId: 47,
    splitOuterId: 80,
  ),
  wave('Wave', 35, 0x3B, Alv2LightScope.whole, _wave),
  spring('Spring', 22, 0x3C, Alv2LightScope.whole, _fourDir),
  tailChasing('TailChasing', 28, 0x3D, Alv2LightScope.whole, _fourDir),
  warning('Warning', 34, 0x30, Alv2LightScope.whole, _warning),
  voice('Voice', 33, 0x31, Alv2LightScope.whole, _fourDir),
  spanningTeacups('SpanningTeacups', 21, 0x41, Alv2LightScope.whole, _teacups),
  tornado('Tornado', 29, 0x3F, Alv2LightScope.whole, _fourDir),
  mixing('Mixing', 13, 0x32, Alv2LightScope.whole, _two),
  stack('Stack', 23, 0x43, Alv2LightScope.whole, _stack),
  staggered('Staggered', 25, 0x40, Alv2LightScope.whole, _four),
  tide('Tide', 30, 0x33, Alv2LightScope.whole, _four),
  scan('Scan', 20, 0x34, Alv2LightScope.whole, _two),
  contest('Contest', 5, 0x35, Alv2LightScope.whole, _contest),
  colorfulCity('ColorfulCity', 4, 0x38, Alv2LightScope.whole, _noColor),
  render('Render', 18, 0x39, Alv2LightScope.whole, _fourDir),
  electricCurrent('ElectricCurrent', 8, 0x42, Alv2LightScope.whole, _electric),
  twinkle('Twinkle', 32, 0x3A, Alv2LightScope.whole, _noColor),

  // --- Inner ring (port 2g) ---
  rainbowInner('Rainbow_Inner', 54, 0x05, Alv2LightScope.inner, _rainbow),
  rainbowMorphInner(
    'RainbowMorph_Inner',
    55,
    0x04,
    Alv2LightScope.inner,
    _morph,
  ),
  staticColorInner(
    'StaticColor_Inner',
    62,
    0x01,
    Alv2LightScope.inner,
    _static,
  ),
  breathingInner('Breathing_Inner', 36, 0x02, Alv2LightScope.inner, _breathing),
  colorCycleInner(
    'ColorCycle_Inner',
    38,
    0x18,
    Alv2LightScope.inner,
    _colorCycle,
  ),
  runwayInner('Runway_Inner', 58, 0x1A, Alv2LightScope.inner, _two),
  mopUpInner('MopUp_Inner', 52, 0x1B, Alv2LightScope.inner, _two),
  pacManInner('PacMan_Inner', 53, 0x27, Alv2LightScope.inner, _two),
  meteorInner('Meteor_Inner', 47, 0x19, Alv2LightScope.inner, _fourDir),
  meteorRainbowInner(
    'MeteorRainbow_Inner',
    50,
    0x08,
    Alv2LightScope.inner,
    _meteorRainbow,
  ),
  lotteryInner('Lottery_Inner', 46, 0x1D, Alv2LightScope.inner, _four),
  waveInner('Wave_Inner', 69, 0x1E, Alv2LightScope.inner, _wave),
  springInner('Spring_Inner', 60, 0x1F, Alv2LightScope.inner, _fourDir),
  tailChasingInner(
    'TailChasing_Inner',
    64,
    0x20,
    Alv2LightScope.inner,
    _fourDir,
  ),
  warningInner('Warning_Inner', 68, 0x21, Alv2LightScope.inner, _warning),
  voiceInner('Voice_Inner', 67, 0x22, Alv2LightScope.inner, _fourDir),
  mixingInner('Mixing_Inner', 51, 0x23, Alv2LightScope.inner, _two),
  stackInner('Stack_Inner', 61, 0x24, Alv2LightScope.inner, _stack),
  tideInner('Tide_Inner', 65, 0x25, Alv2LightScope.inner, _four),
  scanInner('Scan_Inner', 59, 0x26, Alv2LightScope.inner, _two),
  colorfulCityInner(
    'ColorfulCity_Inner',
    39,
    0x28,
    Alv2LightScope.inner,
    _noColor,
  ),
  renderInner('Render_Inner', 56, 0x29, Alv2LightScope.inner, _fourDir),
  twinkleInner('Twinkle_Inner', 66, 0x2A, Alv2LightScope.inner, _noColor),

  // --- Outer ring (port 2g+1) ---
  rainbowOuter('Rainbow_Outer', 84, 0x05, Alv2LightScope.outer, _rainbow),
  rainbowMorphOuter(
    'RainbowMorph_Outer',
    85,
    0x04,
    Alv2LightScope.outer,
    _morph,
  ),
  staticColorOuter(
    'StaticColor_Outer',
    92,
    0x01,
    Alv2LightScope.outer,
    _static,
  ),
  staticColorfulOuter(
    'StaticColorful_Outer',
    93,
    0x01,
    Alv2LightScope.outer,
    _staticColorful,
  ),
  breathingOuter('Breathing_Outer', 70, 0x02, Alv2LightScope.outer, _breathing),
  breathingColorfulOuter(
    'BreathingColorful_Outer',
    71,
    0x02,
    Alv2LightScope.outer,
    _breathingColorful,
  ),
  breathingRainbowOuter(
    'BreathingRainbow_Outer',
    72,
    0x06,
    Alv2LightScope.outer,
    _noColor,
  ),
  colorCycleOuter(
    'ColorCycle_Outer',
    73,
    0x1C,
    Alv2LightScope.outer,
    _colorCycle,
  ),
  runwayOuter('Runway_Outer', 88, 0x1A, Alv2LightScope.outer, _two),
  mopUpOuter('MopUp_Outer', 83, 0x1B, Alv2LightScope.outer, _two),
  meteorOuter('Meteor_Outer', 80, 0x19, Alv2LightScope.outer, _fourDir),
  meteorRainbowOuter(
    'MeteorRainbow_Outer',
    81,
    0x08,
    Alv2LightScope.outer,
    _meteorRainbow,
  ),
  lotteryOuter('Lottery_Outer', 79, 0x1D, Alv2LightScope.outer, _four),
  waveOuter('Wave_Outer', 99, 0x1E, Alv2LightScope.outer, _wave),
  springOuter('Spring_Outer', 90, 0x1F, Alv2LightScope.outer, _fourDir),
  tailChasingOuter(
    'TailChasing_Outer',
    94,
    0x20,
    Alv2LightScope.outer,
    _fourDir,
  ),
  warningOuter('Warning_Outer', 98, 0x21, Alv2LightScope.outer, _warning),
  voiceOuter('Voice_Outer', 97, 0x22, Alv2LightScope.outer, _fourDir),
  mixingOuter('Mixing_Outer', 82, 0x23, Alv2LightScope.outer, _two),
  stackOuter('Stack_Outer', 91, 0x24, Alv2LightScope.outer, _stack),
  tideOuter('Tide_Outer', 95, 0x25, Alv2LightScope.outer, _four),
  scanOuter('Scan_Outer', 89, 0x26, Alv2LightScope.outer, _two),
  colorfulCityOuter(
    'ColorfulCity_Outer',
    74,
    0x28,
    Alv2LightScope.outer,
    _noColor,
  ),
  renderOuter('Render_Outer', 87, 0x29, Alv2LightScope.outer, _fourDir),
  twinkleOuter('Twinkle_Outer', 96, 0x2A, Alv2LightScope.outer, _noColor),

  // --- Merge (port 0 only; spans all 4 groups) ---
  runwayMerge('Runway_Merge', 107, 0x46, Alv2LightScope.merge, _two),
  mopUpMerge('MopUp_Merge', 106, 0x4C, Alv2LightScope.merge, _two),
  waveMerge('Wave_Merge', 114, 0x49, Alv2LightScope.merge, _wave),
  springMerge('Spring_Merge', 109, 0x4B, Alv2LightScope.merge, _fourDir),
  tailChasingMerge(
    'TailChasing_Merge',
    112,
    0x4A,
    Alv2LightScope.merge,
    _fourDir,
  ),
  mixingMerge('Mixing_Merge', 105, 0x47, Alv2LightScope.merge, _two),
  tideMerge('Tide_Merge', 113, 0x48, Alv2LightScope.merge, _four),
  scanMerge('Scan_Merge', 108, 0x44, Alv2LightScope.merge, _two),
  contestMerge('Contest_Merge', 100, 0x45, Alv2LightScope.merge, _contest),
  electricCurrentMerge(
    'ElectricCurrent_Merge',
    102,
    0x4F,
    Alv2LightScope.merge,
    _electric,
  );

  const Alv2LightMode(
    this.firmwareName,
    this.uiId,
    this.byte,
    this.scope,
    this.meta, {
    this.splitInnerId,
    this.splitOuterId,
  });

  /// Firmware mode name (`Rainbow`, `StaticColor_Inner`…).
  final String firmwareName;
  final int uiId;

  /// Mode byte in firmware (may repeat across scopes: `0x01` is static).
  final int byte;
  final Alv2LightScope scope;
  final Alv2ModeMeta meta;
  final int? splitInnerId, splitOuterId;

  bool get hasSpeed => meta.speed;
  bool get hasDirection => meta.direction;
  int get colorCount => meta.colors;

  /// Static modes: the UI scales RGB by brightness (AL-V2 §6).
  bool get isStatic => const {26, 62, 92, 93}.contains(uiId);

  /// Pairs of the *split* (port 2g inner / 2g+1 outer) of a whole-fan mode.
  Alv2LightMode? get splitInner =>
      splitInnerId == null ? null : byUiId(splitInnerId!);
  Alv2LightMode? get splitOuter =>
      splitOuterId == null ? null : byUiId(splitOuterId!);

  static Alv2LightMode? byUiId(int id) =>
      Alv2LightMode.values.where((m) => m.uiId == id).firstOrNull;

  static Alv2LightMode? byName(String name) =>
      Alv2LightMode.values.where((m) => m.firmwareName == name).firstOrNull;
}

// --- Color payload normalization (AL-V2 §2) ---

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

/// Effect for a mode with its UI settings (levels 0–4, direction 0/1).
class Alv2Effect {
  const Alv2Effect(
    this.mode, {
    this.colors = const [],
    this.speedLevel = 3,
    this.direction = 0,
    this.brightnessLevel = 4,
  });

  final Alv2LightMode mode;

  /// UI colors, flat R,G,B.
  final List<int> colors;
  final int speedLevel, direction, brightnessLevel;
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
