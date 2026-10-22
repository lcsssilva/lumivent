import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/persistence/config_store.dart';
import 'package:lumivent/features/preferences/domain/preferences.dart';
import 'package:lumivent/features/preferences/infrastructure/preferences_codec.dart';
import 'package:lumivent/features/preferences/infrastructure/preferences_store.dart';

void main() {
  test('JSON round trip', () {
    const p = Preferences(
      closeToTray: false,
      temperatureUnit: TemperatureUnit.fahrenheit,
      effectsFps: 60,
    );
    expect(decodePreferences(encodePreferences(p)), p);
  });

  test('missing, unknown, or wrongly typed fields use defaults', () {
    final p = decodePreferences({
      'closeToTray': 'sim',
      'temperatureUnit': 'kelvin',
      'effectsFps': 144,
      'chaveNova': 1,
    });
    expect(p, const Preferences());
  });

  test('repository uses the preferences section', () async {
    final tmp = Directory.systemTemp.createTempSync('lumivent-prefs-');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final store = await ConfigStore.open(tmp);
    final repo = JsonPreferencesRepository(store);
    expect(repo.load(), const Preferences());
    await repo.save(const Preferences(effectsFps: 15));
    expect(store.section('preferences')['effectsFps'], 15);
    expect(
      JsonPreferencesRepository(await ConfigStore.open(tmp)).load(),
      const Preferences(effectsFps: 15),
    );
  });
}
