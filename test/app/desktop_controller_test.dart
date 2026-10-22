// The desktop controller touches window and tray plugins, so tests here focus
// on the shutdown step that is platform free: reporting a pending persistence
// failure without stopping the rest of the shutdown.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/app/desktop/desktop_controller.dart';
import 'package:lumivent/core/persistence/config_store.dart';

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('lumivent-shutdown-'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('a pending failure is logged once and shutdown continues', () async {
    // Writes fail: the configuration directory path is an existing file.
    final blocked = File('${tmp.path}/blocked')
      ..writeAsStringSync('not a directory');
    final store = await ConfigStore.open(Directory(blocked.path));
    await expectLater(
      store.saveSection('preferences', {'effectsFps': 60}),
      throwsA(isA<ConfigWriteFailure>()),
    );

    final logged = <String>[];
    final previous = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logged.add(message);
    };
    addTearDown(() => debugPrint = previous);

    await flushPendingWrites(store);

    expect(logged, hasLength(1));
    // The cause and the stack trace are logged for troubleshooting.
    expect(logged.single, contains('Failed to save preferences'));
    expect(logged.single, contains('Not a directory'));
    expect(logged.single, contains('config_store.dart'));

    // Reported exactly once.
    await flushPendingWrites(store);
    expect(logged, hasLength(1));
  });

  test('a recovered failure logs nothing', () async {
    final blocked = File('${tmp.path}/blocked')
      ..writeAsStringSync('not a directory');
    final store = await ConfigStore.open(Directory(blocked.path));
    await expectLater(
      store.saveSection('preferences', {'effectsFps': 60}),
      throwsA(isA<ConfigWriteFailure>()),
    );

    final logged = <String>[];
    final previous = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logged.add(message);
    };
    addTearDown(() => debugPrint = previous);

    blocked.deleteSync();
    Directory(blocked.path).createSync();
    await store.saveSection('preferences', {'effectsFps': 30});

    await flushPendingWrites(store);
    expect(logged, isEmpty);
  });
}
