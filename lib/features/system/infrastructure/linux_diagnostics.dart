// Environment checks (phase 0) shown in Settings.
import 'dart:io';

import '../../../core/platform/smbus_ffi.dart';
import '../../devices/devices.dart' show furyBusName;
import '../../monitoring/monitoring.dart' show findNvmeSmartHelper;
import '../domain/diagnostics.dart';

class LinuxDiagnostics implements EnvironmentDiagnostics {
  const LinuxDiagnostics();

  @override
  List<DiagnosticCheck> run() => runDiagnostics();
}

/// Names of the hwmon chips present (`/sys/class/hwmon/*/name`).
Set<String> hwmonNames({String sysfsRoot = '/sys'}) {
  final dir = Directory('$sysfsRoot/class/hwmon');
  if (!dir.existsSync()) return const {};
  return {
    for (final e in dir.listSync())
      if (File('${e.path}/name').existsSync())
        File('${e.path}/name').readAsStringSync().trim(),
  };
}

/// Is the SMART helper installed with `cap_sys_admin`?
DiagnosticCheck nvmeHelperCheck({
  String? helper,
  String Function(String path)? getcap,
}) {
  if (helper == null) {
    return const DiagnosticCheck(DiagnosticId.nvmeHelper, CheckState.warn, {
      'path': null,
      'hasCaps': false,
    });
  }
  getcap ??= _getcap;
  final hasCaps = getcap(helper).contains('cap_sys_admin');
  return DiagnosticCheck(
    DiagnosticId.nvmeHelper,
    hasCaps ? CheckState.ok : CheckState.warn,
    {'path': helper, 'hasCaps': hasCaps},
  );
}

String _getcap(String path) {
  try {
    return Process.runSync('getcap', [path]).stdout as String;
  } on ProcessException {
    return '';
  }
}

/// Is the udev rule installed by the package (`/usr/lib/udev/rules.d`) or by
/// the legacy manual setup (`/etc/udev/rules.d`)?
bool udevRulesInstalled({String etcRoot = '/etc', String usrRoot = '/usr'}) {
  const name = '99-lumivent.rules';
  return [
    '$etcRoot/udev/rules.d/$name',
    '$usrRoot/lib/udev/rules.d/$name',
  ].any((path) => File(path).existsSync());
}

List<DiagnosticCheck> runDiagnostics({
  String sysfsRoot = '/sys',
  String etcRoot = '/etc',
  String usrRoot = '/usr',
  DiagnosticCheck Function()? nvmeHelper,
}) {
  final hwmon = hwmonNames(sysfsRoot: sysfsRoot);
  final udev = udevRulesInstalled(etcRoot: etcRoot, usrRoot: usrRoot);
  final bus = findI2cBusByName(furyBusName, sysfsRoot: sysfsRoot);
  final superIo = ['it8689', 'it8792'].where(hwmon.contains).toList();
  final spd = hwmon.contains('spd5118');
  return [
    DiagnosticCheck(
      DiagnosticId.udevRules,
      udev ? CheckState.ok : CheckState.warn,
      {'installed': udev, 'file': '99-lumivent.rules'},
    ),
    DiagnosticCheck(
      DiagnosticId.boardSensors,
      superIo.isNotEmpty ? CheckState.ok : CheckState.warn,
      {'modules': superIo},
    ),
    DiagnosticCheck(
      DiagnosticId.memorySmbus,
      bus != null ? CheckState.ok : CheckState.warn,
      {'bus': bus},
    ),
    DiagnosticCheck(
      DiagnosticId.memoryTemperature,
      spd ? CheckState.ok : CheckState.warn,
      {'driver': spd ? 'spd5118' : null},
    ),
    (nvmeHelper ?? () => nvmeHelperCheck(helper: findNvmeSmartHelper()))(),
  ];
}
