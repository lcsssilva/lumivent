// Controllers save without awaiting: the store notifies the user, and each
// controller logs the technical details (section, cause, and stack trace) of
// a failed save.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/engine/engine_host.dart';
import 'package:lumivent/core/persistence/config_store.dart';
import 'package:lumivent/features/fans/fans.dart';
import 'package:lumivent/features/lighting/lighting.dart';
import 'package:lumivent/features/preferences/preferences.dart';

import '../fakes.dart';

void main() {
  late Directory tmp;
  late ConfigStore store;
  late ProviderContainer container;
  late List<String> logged;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('lumivent-save-failure-');
    // Writes fail: the configuration directory path is an existing file.
    final blocked = File('${tmp.path}/blocked')
      ..writeAsStringSync('not a directory');
    store = await ConfigStore.open(Directory(blocked.path));
    container = ProviderContainer(
      overrides: [
        engineProvider.overrideWithValue(FakeEngine()),
        ...FansModule.overrides(store),
        ...LightingModule.overrides(store),
        ...PreferencesModule.overrides(store),
      ],
    );

    logged = <String>[];
    final previous = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logged.add(message);
    };
    addTearDown(() => debugPrint = previous);
  });

  tearDown(() {
    container.dispose();
    tmp.deleteSync(recursive: true);
  });

  Future<void> settleFailedSave() async {
    await expectLater(store.flush(), throwsA(isA<ConfigWriteFailure>()));
    await Future<void>.delayed(Duration.zero);
  }

  void expectLoggedFailure(String section) {
    expect(logged, hasLength(1));
    expect(logged.single, startsWith('Failed to save $section: '));
    expect(logged.single, contains('Not a directory'));
    expect(logged.single, contains('config_store.dart'));
  }

  test('fans logs a failed save with its stack trace', () async {
    final fans = container.read(fansProvider.notifier);
    fans.updateGroup(container.read(fansProvider)[1].copyWith(name: 'Front'));
    await settleFailedSave();
    expectLoggedFailure('fans');
  });

  test('lighting logs a failed save with its stack trace', () async {
    container.read(lightingProvider.notifier).setArgbOff(true);
    await settleFailedSave();
    expectLoggedFailure('lighting');
  });

  test('preferences logs a failed save with its stack trace', () async {
    container
        .read(preferencesProvider.notifier)
        .change((p) => p.copyWith(effectsFps: 15));
    await settleFailedSave();
    expectLoggedFailure('preferences');
  });
}
