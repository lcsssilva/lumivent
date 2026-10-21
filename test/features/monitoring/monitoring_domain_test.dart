import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/monitoring/monitoring.dart';

import 'smart_fixture.dart';

void main() {
  SensorSample sample(int i) =>
      SensorSample(DateTime(2026, 1, 1, 0, 0, i), {'x': i.toDouble()});

  group('5-minute history', () {
    test('keeps only the last [capacity] readings, oldest first', () {
      var h = const SensorHistory(capacity: 3);
      for (var i = 0; i < 5; i++) {
        h = h.added(sample(i));
      }
      expect(h.series('x'), [2, 3, 4]);
      expect(h.latest!['x'], 4);
      expect(
        SensorHistory.from([
          for (var i = 0; i < 5; i++) sample(i),
        ], capacity: 2).series('x'),
        [3, 4],
      );
    });

    test('missing metric becomes a gap in the series', () {
      final h = const SensorHistory()
          .added(SensorSample(DateTime(2026), {'x': 1}))
          .added(SensorSample(DateTime(2026), {}))
          .added(SensorSample(DateTime(2026), {'x': 0}));
      expect(h.series('x'), [1, null, 0]);
      expect(h.seen('x'), isTrue);
      expect(h.seen('y'), isFalse);
      expect(h.everPositive('x'), isTrue);
    });

    test('default is 300 readings (5 minutes at 1 second)', () {
      expect(const SensorHistory().capacity, 300);
    });
  });

  group('SSD health', () {
    test('life = 100 − PercentageUsed, clamped to 0–100', () {
      expect(smartLog(percentageUsed: 2).lifeRemaining, 98);
      expect(smartLog(percentageUsed: 0).lifeRemaining, 100);
      expect(smartLog(percentageUsed: 120).lifeRemaining, 0);
    });

    test('0 → Poor, ≤ 10% → Caution, > 10% → Good', () {
      expect(SsdHealth.fromLife(0), SsdHealth.bad);
      expect(SsdHealth.fromLife(1), SsdHealth.caution);
      expect(SsdHealth.fromLife(10), SsdHealth.caution);
      expect(SsdHealth.fromLife(11), SsdHealth.good);
      expect(smartLog(percentageUsed: 90).health, SsdHealth.caution);
      expect(smartLog(percentageUsed: 89).health, SsdHealth.good);
    });

    test('critical warning bits and conversions', () {
      final s = smartLog(criticalWarning: 0x09, dataUnitsWritten: 1000);
      expect(s.warnings, ['reserva abaixo do limite', 'mídia somente leitura']);
      expect(s.bytesWritten, 512000000);
      expect(smartLog().compositeCelsius, closeTo(40.85, 1e-9));
    });
  });
}
