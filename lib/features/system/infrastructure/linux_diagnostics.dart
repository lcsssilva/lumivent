// Environment checks (phase 0) shown in Settings.
import 'dart:io';

import '../../../core/platform/smbus_ffi.dart';
import '../../devices/devices.dart' show furyBusName;
import '../../monitoring/monitoring.dart'
    show findNvmeSmartHelper, nvmeHelperHint;
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
  const label = 'Helper NVMe SMART';
  if (helper == null) {
    return const DiagnosticCheck(label, CheckState.warn, nvmeHelperHint);
  }
  getcap ??= _getcap;
  final caps = getcap(helper);
  return caps.contains('cap_sys_admin')
      ? DiagnosticCheck(label, CheckState.ok, helper)
      : DiagnosticCheck(
          label,
          CheckState.warn,
          '$helper não tem capabilities. $nvmeHelperHint',
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
  return [
    DiagnosticCheck(
      'Regras udev',
      udev ? CheckState.ok : CheckState.warn,
      udev
          ? '99-lumivent.rules instalada'
          : 'instale o pacote lumivent (99-lumivent.rules)',
    ),
    DiagnosticCheck(
      'Sensores da placa-mãe (it87)',
      superIo.isNotEmpty ? CheckState.ok : CheckState.warn,
      superIo.isNotEmpty ? superIo.join(' + ') : 'módulo it87 não carregado',
    ),
    DiagnosticCheck(
      'SMBus da memória',
      bus != null ? CheckState.ok : CheckState.warn,
      bus ?? 'PIIX4 0x0B00 ausente (acpi_enforce_resources=lax)',
    ),
    DiagnosticCheck(
      'Temperatura da memória',
      hwmon.contains('spd5118') ? CheckState.ok : CheckState.warn,
      hwmon.contains('spd5118') ? 'spd5118' : 'driver spd5118 não carregado',
    ),
    (nvmeHelper ?? () => nvmeHelperCheck(helper: findNvmeSmartHelper()))(),
  ];
}
