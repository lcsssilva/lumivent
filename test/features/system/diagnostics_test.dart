import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/devices/devices.dart' show furyBusName;
import 'package:lumivent/features/system/domain/diagnostics.dart';
import 'package:lumivent/features/system/infrastructure/linux_diagnostics.dart';

void main() {
  late Directory root;
  setUp(() => root = Directory.systemTemp.createTempSync('lumivent-sys-'));
  tearDown(() => root.deleteSync(recursive: true));

  void write(String path, String content) => (File(
    '${root.path}/$path',
  )..createSync(recursive: true)).writeAsStringSync(content);

  test('diagnostics with everything installed and nothing installed', () {
    expect(
      runDiagnostics(
        sysfsRoot: root.path,
        etcRoot: root.path,
        usrRoot: '${root.path}/usr',
        nvmeHelper: () => nvmeHelperCheck(),
      ).map((c) => c.state),
      [
        CheckState.warn,
        CheckState.warn,
        CheckState.warn,
        CheckState.warn,
        CheckState.warn,
      ],
    );
    // The package installs the rule under /usr/lib/udev/rules.d.
    write('usr/lib/udev/rules.d/99-lumivent.rules', '');
    write('class/hwmon/hwmon3/name', 'it8689\n');
    write('class/hwmon/hwmon4/name', 'it8792\n');
    write('class/hwmon/hwmon5/name', 'spd5118\n');
    write('class/i2c-dev/i2c-10/name', furyBusName);
    final checks = runDiagnostics(
      sysfsRoot: root.path,
      etcRoot: root.path,
      usrRoot: '${root.path}/usr',
      nvmeHelper: () => nvmeHelperCheck(
        helper: '/usr/lib/lumivent/lumivent-nvme-smart',
        getcap: (p) => '$p cap_dac_read_search,cap_sys_admin=ep\n',
      ),
    );
    expect(checks.map((c) => c.state), everyElement(CheckState.ok));
    expect(checks[1].data['modules'], ['it8689', 'it8792']);
  });

  test('udev rules are also found in the legacy /etc location', () {
    write('udev/rules.d/99-lumivent.rules', '');
    expect(udevRulesInstalled(etcRoot: root.path, usrRoot: root.path), isTrue);
  });

  test('NVMe helper without capabilities is a warning', () {
    final c = nvmeHelperCheck(
      helper: '/x/lumivent-nvme-smart',
      getcap: (_) => '',
    );
    expect(c.state, CheckState.warn);
    expect(c.data['path'], '/x/lumivent-nvme-smart');
    expect(c.data['hasCaps'], isFalse);
  });
}
