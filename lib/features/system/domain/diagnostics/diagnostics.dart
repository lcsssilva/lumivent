import 'diagnostic_check.dart';

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

/// File name of the udev rule installed by the package.
const udevRulesFileName = '99-lumivent.rules';

/// Lighting output families with a measured loop.
enum LoopFamily { fans, board, ram, gpu }
