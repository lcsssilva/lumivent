import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/system/domain/autostart_exception.dart';
import 'package:lumivent/features/system/infrastructure/systemd_autostart.dart';

void main() {
  test('systemdQuote escapes quotes, backslash, % and \$', () {
    expect(systemdQuote('/usr/bin/lumivent'), '"/usr/bin/lumivent"');
    expect(systemdQuote(r'/a b/"x"\%$'), r'"/a b/\"x\"\\%%$$"');
  });

  test('unit starts minimized, restarts only on failure, and starts in the graphical session', () {
    final unit = buildAutostartUnit('/usr/lib/lumivent/lumivent');
    expect(
      unit,
      contains('ExecStart="/usr/lib/lumivent/lumivent" --minimized\n'),
    );
    expect(unit, contains('Restart=on-failure\n'));
    expect(unit, contains('WantedBy=graphical-session.target\n'));
    expect(unit, contains('PartOf=graphical-session.target\n'));
  });

  group('SystemdAutostart', () {
    late Directory tmp;
    late List<String> calls;
    late SystemdAutostart svc;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('lumivent-unit-');
      calls = [];
      svc = SystemdAutostart(
        executable: '/usr/lib/lumivent/lumivent',
        unitDir: Directory('${tmp.path}/systemd/user'),
        run: (exe, args) async {
          calls.add('$exe ${args.join(' ')}');
          final enabled = svc.unitFile.existsSync();
          return ProcessResult(
            0,
            0,
            args.contains('is-enabled') && enabled ? 'enabled\n' : '',
            '',
          );
        },
      );
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    test('enable writes, reloads, and enables the unit', () async {
      expect(await svc.isEnabled(), isFalse);
      await svc.enable();
      expect(
        svc.unitFile.readAsStringSync(),
        buildAutostartUnit('/usr/lib/lumivent/lumivent'),
      );
      expect(calls, [
        'systemctl --user daemon-reload',
        'systemctl --user enable lumivent.service',
      ]);
      expect(await svc.isEnabled(), isTrue);
      expect(await svc.pointsElsewhere(), isFalse);
    });

    test('disable disables and deletes the unit', () async {
      await svc.enable();
      calls.clear();
      await svc.disable();
      expect(svc.unitFile.existsSync(), isFalse);
      expect(calls, [
        'systemctl --user disable lumivent.service',
        'systemctl --user daemon-reload',
      ]);
    });

    test('unit pointing to another executable is detected', () async {
      svc.unitDir.createSync(recursive: true);
      svc.unitFile.writeAsStringSync(
        buildAutostartUnit('/build/antigo/lumivent'),
      );
      expect(await svc.pointsElsewhere(), isTrue);
    });

    test('systemctl failure becomes AutostartException', () async {
      final failing = SystemdAutostart(
        executable: '/x',
        unitDir: Directory('${tmp.path}/u'),
        run: (_, _) async =>
            ProcessResult(0, 1, '', 'Failed to connect to bus'),
      );
      expect(failing.enable(), throwsA(isA<AutostartException>()));
    });
  });
}
