// AL V2 lighting modes (AL-V2 §3 tables, §6 metadata). Pure Dart, no I/O.
import 'alv2_mode_meta.dart';

enum Alv2LightScope { whole, inner, outer, merge }

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
