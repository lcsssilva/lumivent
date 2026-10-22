import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/monitoring/infrastructure/nvme_ssd_reader.dart';
import 'package:lumivent/features/monitoring/monitoring.dart';

import 'smart_fixture.dart';

void main() {
  test('log 02h → campos do SMART', () {
    final s = parseNvmeSmartLog(smartLogBytes())!;
    expect(s.criticalWarning, 0);
    expect(s.compositeKelvin, 314);
    expect(s.availableSpare, 100);
    expect(s.availableSpareThreshold, 10);
    expect(s.percentageUsed, 2);
    expect(s.lifeRemaining, 98);
    expect(s.dataUnitsRead, 23456789);
    expect(s.dataUnitsWritten, 24218750);
    expect(s.bytesWritten, 12400000000000);
    expect(s.hostReadCommands, 111);
    expect(s.hostWriteCommands, 222);
    expect(s.controllerBusyMinutes, 333);
    expect(s.powerCycles, 1234);
    expect(s.powerOnHours, 1820);
    expect(s.unsafeShutdowns, 56);
    expect(s.mediaErrors, 0);
    expect(s.errorLogEntries, 7);
    expect(s.warningTempMinutes, 3);
    expect(s.criticalTempMinutes, 1);
    expect(s.sensorsKelvin, [315, 326, 0, 0, 0, 0, 0, 0]);
  });

  test('128-bit counter above 63 bits is clamped', () {
    final b = smartLogBytes();
    ByteData.sublistView(b)
        .setUint64(40, 1, Endian.little); // parte alta de "lidas"
    expect(parseNvmeSmartLog(b)!.dataUnitsRead, 0x7FFFFFFFFFFFFFFF);
    expect(parseNvmeSmartLog(Uint8List(100)), isNull);
  });

  test('helper lines: log, error, and garbage', () {
    final ok = parseHelperLine(
      '{"ctrl":"nvme0","log":"${toHex(smartLogBytes())}"}',
    )!;
    expect(ok.ctrl, 'nvme0');
    expect(ok.log!.powerOnHours, 1820);
    final err = parseHelperLine(
      '{"ctrl":"nvme1","error":"open: Permission denied"}',
    )!;
    expect((err.log, err.error?.kind), (null, SsdErrorKind.device));
    expect(err.error?.message, 'open: Permission denied');
    expect(
      parseHelperLine('{"ctrl":"nvme0","log":"zz"}')!.error?.kind,
      SsdErrorKind.invalidResponse,
    );
    expect(parseHelperLine('not json'), isNull);
    expect(parseHelperLine('{"x":1}'), isNull);
  });

  test('helper candidates: environment variable comes first', () {
    expect(
      nvmeHelperCandidates({'LUMIVENT_NVME_SMART': '/tmp/h'}).first,
      '/tmp/h',
    );
    expect(nvmeHelperCandidates({}), [
      '/usr/lib/lumivent/lumivent-nvme-smart',
      '/usr/local/lib/lumivent/lumivent-nvme-smart',
    ]);
  });

  group('NvmeSsdReader', () {
    late Directory root;
    setUp(() {
      root = Directory.systemTemp.createTempSync('lumivent-nvme-');
      void write(String path, String content) => (File(
        '${root.path}/$path',
      )..createSync(recursive: true)).writeAsStringSync(content);
      write(
        'class/nvme/nvme0/model',
        'KINGSTON SNV3S1000G                     \n',
      );
      write('class/nvme/nvme0/serial', '50026B7686E929D3    \n');
      write('class/nvme/nvme0/firmware_rev', 'ERFK1N.3\n');
      write('class/nvme/nvme0/nvme0n1/size', '1953525168\n');
      write('class/nvme/nvme1/model', 'KINGSTON SFYRS1000G\n');
      write('class/nvme/nvme10/model', 'outro\n');
    });
    tearDown(() => root.deleteSync(recursive: true));

    String fakeHelper(String body) {
      final f = File('${root.path}/helper.sh')
        ..writeAsStringSync('#!/bin/sh\n$body\n');
      Process.runSync('chmod', ['+x', f.path]);
      return f.path;
    }

    test(
      'sysfs identification and helper SMART data use numeric order',
      () async {
        final helper = fakeHelper('''
[ "\$*" = "nvme0 nvme1 nvme10" ] || { echo "args: \$*" >&2; exit 2; }
echo '{"ctrl":"nvme0","log":"${toHex(smartLogBytes())}"}'
echo '{"ctrl":"nvme1","error":"ioctl: Operation not permitted"}'
echo '{"ctrl":"nvme10","error":"open: No such device"}'
''');
        final ssds = await NvmeSsdReader(
          sysfsRoot: root.path,
          helper: helper,
        ).read();
        expect(ssds.map((s) => s.controller), ['nvme0', 'nvme1', 'nvme10']);
        final a = ssds.first;
        expect(
          (a.model, a.serial, a.firmware),
          ('KINGSTON SNV3S1000G', '50026B7686E929D3', 'ERFK1N.3'),
        );
        expect(a.capacityBytes, 1953525168 * 512);
        expect(a.smart!.health, SsdHealth.good);
        expect(a.smartError, isNull);
        expect(ssds[1].smart, isNull);
        expect(ssds[1].smartError?.kind, SsdErrorKind.device);
        expect(ssds[1].smartError?.message, 'ioctl: Operation not permitted');
        expect(ssds[1].capacityBytes, isNull);
      },
    );

    test('without helper: SSDs appear with the reason', () async {
      final ssds = await NvmeSsdReader(
        sysfsRoot: root.path,
        helper: '${root.path}/nao-existe',
      ).read();
      expect(ssds, hasLength(3));
      expect(ssds.first.smart, isNull);
      expect(ssds.first.smartError?.kind, SsdErrorKind.helperFailed);
    });

    test('helper failure with no output', () async {
      final helper = fakeHelper('echo "uso: ..." >&2; exit 2');
      final ssds = await NvmeSsdReader(
        sysfsRoot: root.path,
        helper: helper,
      ).read();
      expect(ssds.first.smartError?.kind, SsdErrorKind.helperExit);
      expect(ssds.first.smartError?.exitCode, 2);
      expect(ssds.first.smartError?.stderr, 'uso: ...');
    });
  });
}
