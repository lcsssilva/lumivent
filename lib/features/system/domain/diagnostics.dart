enum CheckState { ok, warn, pending }

/// Stable identity of a diagnostic check. The presentation owns the label and
/// the sentence built from [DiagnosticCheck.data] (plan D5).
enum DiagnosticId {
  udevRules,
  boardSensors,
  memorySmbus,
  memoryTemperature,
  nvmeHelper,
  hubRpmSync,
  hubArgbSync,
  lightingLoop,
}

/// Technical values behind a check; the UI translates and composes the text.
/// Each check id has its own subtype, so the presentation reads typed fields
/// instead of casting map entries. Checks built outside this module (the
/// runtime checks) extend it with their own subtype.
abstract class DiagnosticData {
  const DiagnosticData();
}

/// Checks that need nothing beyond [DiagnosticCheck.state].
class NoDiagnosticData extends DiagnosticData {
  const NoDiagnosticData();
}

/// File name of the udev rule installed by the package.
const udevRulesFileName = '99-lumivent.rules';

class UdevRulesData extends DiagnosticData {
  const UdevRulesData({required this.installed});
  final bool installed;
}

class BoardSensorsData extends DiagnosticData {
  const BoardSensorsData(this.modules);

  /// Super I/O hwmon drivers that are loaded.
  final List<String> modules;
}

class MemorySmbusData extends DiagnosticData {
  const MemorySmbusData({this.bus});

  /// SMBus the memory sits on, or null when it was not found.
  final String? bus;
}

class MemoryTemperatureData extends DiagnosticData {
  const MemoryTemperatureData({this.driver});

  /// hwmon driver reporting memory temperature, or null when absent.
  final String? driver;
}

class NvmeHelperData extends DiagnosticData {
  const NvmeHelperData({this.path, required this.hasCaps});

  /// Installed SMART helper, or null when it was not found.
  final String? path;
  final bool hasCaps;
}

/// Lighting output families with a measured loop.
enum LoopFamily { fans, board, ram, gpu }

/// Measured rate of one output loop.
class LoopSample {
  const LoopSample(this.family, {this.fps, this.sendMs});
  final LoopFamily family;
  final double? fps;
  final double? sendMs;
}

class LightingLoopData extends DiagnosticData {
  const LightingLoopData(this.loops);
  final List<LoopSample> loops;
}

/// An environment check (drivers, permissions, helpers).
class DiagnosticCheck {
  const DiagnosticCheck(
    this.id,
    this.state, [
    this.data = const NoDiagnosticData(),
  ]);
  final DiagnosticId id;
  final CheckState state;
  final DiagnosticData data;
}

/// Port for environment checks.
abstract interface class EnvironmentDiagnostics {
  List<DiagnosticCheck> run();
}
