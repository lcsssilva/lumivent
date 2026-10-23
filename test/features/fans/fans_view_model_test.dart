import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/engine/isolate_engine.dart';
import 'package:lumivent/core/persistence/config_store.dart';
import 'package:lumivent/features/fans/fans.dart';
import 'package:lumivent/features/fans/presentation/view_models/fans_ui_state.dart';
import 'package:lumivent/features/fans/presentation/view_models/fans_view_model.dart';
import 'package:lumivent/features/monitoring/monitoring.dart';
import 'package:lumivent/features/preferences/preferences.dart';

import '../../fake_engine.dart';
import 'memory_fans_repository.dart';

FansUiState _ui({
  Map<String, double> reading = const {},
  FansStatus? status,
  int? selectedGroup,
  FansConfig? config,
}) => FansUiState(
  config: config ?? FansConfig.defaults(),
  history: SensorHistory.from([SensorSample(DateTime(2026), reading)]),
  status: status,
  temperatureUnit: TemperatureUnit.celsius,
  selectedGroup: selectedGroup,
);

void main() {
  group('FansUiState', () {
    test('selects the first group with a fan, else group 1', () {
      expect(_ui().selectedIndex, 1);
      expect(_ui(reading: {Metrics.alv2Rpm(2): 900}).selectedIndex, 2);
      expect(
        _ui(reading: {Metrics.alv2Rpm(2): 900}, selectedGroup: 0).selectedIndex,
        0,
      );
    });

    test('shows the raw temperature only when it differs by .5 °C', () {
      FansUiState withTemps(double filtered, double raw) => _ui(
        status: FansStatus([
          FanGroupStatus(group: 1, temp: filtered, rawTemp: raw),
        ], hubOk: true),
      );
      expect(withTemps(50, 50.4).showsRawTemperature, isFalse);
      expect(withTemps(50, 50.5).showsRawTemperature, isTrue);
      expect(withTemps(50, 50.5).temperature, 50);
    });

    test('falls back to the source reading without an engine cycle', () {
      final ui = _ui(reading: {Metrics.cpuTctl: 61});
      expect(ui.temperature, 61);
      expect(ui.rawTemperature, 61);
      expect(ui.showsRawTemperature, isFalse);
    });

    test('offers board sources only while they report or when selected', () {
      expect(_ui().sourceOptions.any((s) => s.isBoard), isFalse);
      expect(
        _ui(reading: {Metrics.boardVrm: 40}).sourceOptions,
        contains(FanTempSource.boardVrm),
      );
      final config = FansConfig.defaults();
      final onPch = config.replaced(
        config[1].copyWith(source: FanTempSource.boardPch),
      );
      expect(
        _ui(config: onPch).sourceOptions,
        contains(FanTempSource.boardPch),
      );
    });

    test('the trace keeps the last 60 readings with temperature and RPM', () {
      final samples = [
        for (var i = 0; i < 70; i++)
          SensorSample(DateTime(2026, 1, 1, 0, 0, i), {
            Metrics.cpuTctl: 40.0 + i,
            if (i != 69) Metrics.alv2Rpm(1): 1000.0 + i,
          }),
      ];
      final ui = FansUiState(
        config: FansConfig.defaults(),
        history: SensorHistory.from(samples),
        status: null,
        temperatureUnit: TemperatureUnit.celsius,
      );
      expect(ui.trace, hasLength(59));
      expect(ui.trace.first, (temp: 50.0, rpm: 1010.0));
    });
  });

  group('FansViewModel', () {
    late Directory tmp;
    late FakeEngine engine;
    late MemoryFansRepository repo;
    late ProviderContainer container;

    setUp(() async {
      tmp = Directory.systemTemp.createTempSync('lumivent-fans-vm-');
      final store = await ConfigStore.open(tmp);
      engine = FakeEngine();
      repo = MemoryFansRepository();
      container = ProviderContainer(
        overrides: [
          engineProvider.overrideWithValue(engine),
          fansRepositoryProvider.overrideWithValue(repo),
          ...PreferencesModule.overrides(store),
        ],
      );
      container.listen(fansViewModelProvider, (_, _) {});
    });
    tearDown(() {
      container.dispose();
      tmp.deleteSync(recursive: true);
    });

    FansViewModel viewModel() => container.read(fansViewModelProvider.notifier);
    FansUiState ui() => container.read(fansViewModelProvider);

    test('the selected group survives new sensor readings', () async {
      viewModel().selectGroup(3);
      engine.emit(
        SensorsUpdated(SensorSample(DateTime(2026), {Metrics.alv2Rpm(0): 800})),
      );
      await Future<void>.delayed(Duration.zero);
      expect(ui().history.latest, isNotNull);
      expect(ui().selectedIndex, 3);
    });

    test('renaming trims the name and ignores a blank one', () {
      viewModel().selectGroup(2);
      viewModel().renameGroup('  Rear  ');
      expect(container.read(fansProvider)[2].name, 'Rear');
      final saves = repo.saves;
      viewModel().renameGroup('   ');
      expect(container.read(fansProvider)[2].name, 'Rear');
      expect(repo.saves, saves);
    });

    test('a dragged curve is applied without saving until committed', () {
      final dragged = ui().group.copyWith(preset: FanPreset.custom);
      viewModel().previewCurve(dragged);
      expect(engine.sent.whereType<SetFansConfig>(), isNotEmpty);
      expect(repo.saves, 0);
      viewModel().commitCurve();
      expect(repo.saves, 1);
    });

    test('options change the selected group and are saved', () {
      viewModel().selectGroup(0);
      viewModel().setStartStop(true);
      viewModel().setSource(FanTempSource.gpuEdge);
      viewModel().setResponse(FanResponse.smooth);
      final group = container.read(fansProvider)[0];
      expect(group.startStop, isTrue);
      expect(group.source, FanTempSource.gpuEdge);
      expect(group.response, FanResponse.smooth);
      expect(repo.saves, 3);
    });

    test('apply to all copies the selected group curve', () {
      viewModel().selectGroup(1);
      viewModel().setPreset(FanPreset.full);
      viewModel().applyCurveToAll();
      final config = container.read(fansProvider);
      for (var g = 0; g < fanGroupCount; g++) {
        expect(config[g].preset, FanPreset.full, reason: 'group $g');
      }
    });
  });
}
