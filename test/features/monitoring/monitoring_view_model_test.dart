import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/engine/isolate_engine.dart';
import 'package:lumivent/core/i18n/app_strings.dart';
import 'package:lumivent/core/persistence/config_store.dart';
import 'package:lumivent/features/monitoring/monitoring.dart';
import 'package:lumivent/features/monitoring/presentation/view_models/monitoring_view_model.dart';
import 'package:lumivent/features/preferences/preferences.dart';

import '../../fake_engine.dart';

MonitoringViewModel _viewModel(
  Map<String, double> reading, {
  TemperatureUnit unit = TemperatureUnit.celsius,
}) => MonitoringViewModel(
  history: SensorHistory.from([SensorSample(DateTime(2026), reading)]),
  temperatureUnit: unit,
);

void main() {
  test('temperatures follow the user unit', () {
    final v = _viewModel({
      Metrics.cpuTctl: 50,
    }, unit: TemperatureUnit.fahrenheit);
    expect(v.temp(Metrics.cpuTctl), '122 °F');
    expect(v.tempLabel(100), '212 °F');
  });

  test('a missing reading shows a dash', () {
    final v = _viewModel(const {});
    expect(v.now(Metrics.cpuTctl), isNull);
    expect(v.temp(Metrics.cpuTctl), '—');
    expect(v.metric(Metrics.cpuUsage, MetricUnit.percent, AppStrings.en), '—');
  });

  test('metrics use the separators of the given catalog', () {
    final v = _viewModel({Metrics.cpuClock: 4250});
    expect(
      v.metric(Metrics.cpuClock, MetricUnit.megahertz, AppStrings.en),
      '4.25 GHz',
    );
    expect(
      v.metric(Metrics.cpuClock, MetricUnit.megahertz, AppStrings.pt),
      '4,25 GHz',
    );
  });

  test('the provider combines the history and the preferred unit', () async {
    final tmp = Directory.systemTemp.createTempSync('lumivent-monitoring-vm-');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final store = await ConfigStore.open(tmp);
    final engine = FakeEngine();
    final container = ProviderContainer(
      overrides: [
        engineProvider.overrideWithValue(engine),
        ...PreferencesModule.overrides(store),
      ],
    );
    addTearDown(container.dispose);
    container.listen(monitoringViewModelProvider, (_, _) {});
    engine.emit(
      SensorsUpdated(SensorSample(DateTime(2026), {Metrics.cpuTctl: 61})),
    );
    await Future<void>.delayed(Duration.zero);
    final v = container.read(monitoringViewModelProvider);
    expect(v.now(Metrics.cpuTctl), 61);
    expect(v.temperatureUnit, TemperatureUnit.celsius);
  });
}
