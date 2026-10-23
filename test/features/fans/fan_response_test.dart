import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/fans/domain/fan_curve.dart';
import 'package:lumivent/features/fans/domain/fan_group_config.dart';
import 'package:lumivent/features/fans/domain/fan_response.dart';
import 'package:lumivent/features/fans/domain/fan_smoother.dart';

// Fake clock: each loop step happens `n` seconds after `t0`.
final t0 = DateTime(2026);
DateTime seg(int n) => t0.add(Duration(seconds: n));

/// Grupo Standard de 120 mm (25 °C → duty 20; 70 °C → duty 75; 95 °C → duty 100).
FanGroupConfig grupo({
  FanResponse response = FanResponse.normal,
  bool startStop = false,
}) => const FanGroupConfig(
  group: 1,
  name: 'G',
  size: FanSize.mm120,
).copyWith(response: response, startStop: startStop);

void main() {
  group('primeiro passo', () {
    for (final r in FanResponse.values) {
      test('goes directly to the target with ${r.name}, without ramping', () {
        final s = FanSmoother();
        expect(s.next(grupo(response: r), 95, seg(0)).duty, 100);
        expect(FanSmoother().next(grupo(response: r), 70, seg(0)).duty, 75);
      });
    }
  });

  group('normal', () {
    test('a jump from 25 to 95 °C is averaged with the last 3 samples', () {
      final g = grupo();
      final s = FanSmoother();
      expect(s.next(g, 25, seg(0)).duty, 20);
      // The last 3 samples are always kept, even when older than the window.
      expect(s.next(g, 25, seg(5)).duty, 20);
      final passo = s.next(g, 95, seg(6));
      expect(passo.temp, closeTo(48.33, 0.01)); // (25 + 25 + 95) / 3
      expect(passo.duty, inInclusiveRange(21, 35)); // at most 20 + 15
    });

    test('increases by at most 15 per second and reaches 100', () {
      final g = grupo();
      final s = FanSmoother();
      s.next(g, 25, seg(0));
      s.next(g, 25, seg(5));
      var anterior = s.next(g, 95, seg(6)).duty;
      for (var t = 7; t <= 20; t++) {
        final duty = s.next(g, 95, seg(t)).duty;
        expect(duty - anterior, lessThanOrEqualTo(15), reason: 't = $t s');
        anterior = duty;
      }
      expect(anterior, 100);
    });

    test('decreases by at most 3 per second from 100 to 20', () {
      final g = grupo();
      final s = FanSmoother();
      for (var t = 0; t <= 5; t++) {
        expect(s.next(g, 95, seg(t)).duty, 100);
      }
      var anterior = 100;
      for (var t = 6; t <= 60; t++) {
        final duty = s.next(g, 25, seg(t)).duty;
        expect(anterior - duty, lessThanOrEqualTo(3), reason: 't = $t s');
        anterior = duty;
      }
      expect(anterior, 20);
    });

    test('two steps at the same instant do not change duty', () {
      final g = grupo();
      final s = FanSmoother();
      expect(s.next(g, 25, seg(0)).duty, 20);
      // The average rises to 60 (target 66), but dt = 0 prevents ramping.
      expect(s.next(g, 95, seg(0)).duty, 20);
    });

    test('a 60-second interval limits dt to 2 seconds, with a maximum rise of 30 points', () {
      final g = grupo();
      final s = FanSmoother();
      expect(s.next(g, 25, seg(0)).duty, 20);
      expect(s.next(g, 95, seg(60)).duty, 50); // 20 + 15 × 2
    });

    test('reset makes the next step go directly to the target and forget the average', () {
      final g = grupo();
      final s = FanSmoother();
      s.next(g, 25, seg(0));
      s.next(g, 95, seg(1)); // duty 35, with ramp
      s.reset();
      final passo = s.next(g, 95, seg(2));
      expect(passo.temp, 95);
      expect(passo.duty, 100);
    });
  });

  group('fast', () {
    test('follows the raw reading target at every step without averaging or ramping', () {
      final g = grupo(response: FanResponse.fast);
      final s = FanSmoother();
      // (reading, expected duty): 25 → 400 rpm → 20; 95 → 2000 rpm → 100; etc.
      const leituras = [
        (25.0, 20),
        (95.0, 100),
        (55.0, 62),
        (70.0, 75),
        (25.0, 20),
      ];
      for (var i = 0; i < leituras.length; i++) {
        final (temp, duty) = leituras[i];
        final passo = s.next(g, temp, seg(i));
        expect(passo.temp, temp, reason: 'passo $i');
        expect(passo.duty, duty, reason: 'passo $i');
      }
    });
  });

  group('smooth', () {
    test(
      'temp is the arithmetic average of readings from the last 10 seconds',
      () {
        final g = grupo(response: FanResponse.smooth);
        final s = FanSmoother();
        final leituras = <(int, double)>[];
        for (var t = 0; t <= 12; t++) {
          final temp = 30.0 + t;
          leituras.add((t, temp));
          final passo = s.next(g, temp, seg(t));
          // Readings 10 s or older leave the window.
          final janela = leituras
              .where((l) => t - l.$1 < 10)
              .map((l) => l.$2)
              .toList();
          final esperado = janela.reduce((a, b) => a + b) / janela.length;
          expect(passo.temp, closeTo(esperado, 1e-9), reason: 't = $t s');
        }
      },
    );

    test('increases by at most 5 per second and reaches 100', () {
      final g = grupo(response: FanResponse.smooth);
      final s = FanSmoother();
      var anterior = 0;
      for (var t = 0; t <= 12; t++) {
        anterior = s.next(g, 25, seg(t)).duty;
      }
      expect(anterior, 20);
      var maiorSubida = 0;
      for (var t = 13; t <= 60; t++) {
        final duty = s.next(g, 95, seg(t)).duty;
        final subida = duty - anterior;
        expect(subida, lessThanOrEqualTo(5), reason: 't = $t s');
        if (subida > maiorSubida) maiorSubida = subida;
        anterior = duty;
      }
      expect(maiorSubida, 5, reason: 'a rampa deveria limitar a subida');
      expect(anterior, 100);
    });
  });

  group('start/stop', () {
    test('below the first point it ramps down, stays at 10, and only then becomes 1', () {
      final g = grupo(startStop: true);
      final s = FanSmoother();
      expect(s.next(g, 95, seg(0)).duty, 100);

      final duties = <int>[];
      for (var t = 1; t <= 60; t++) {
        duties.add(s.next(g, 20, seg(t)).duty);
      }

      final fim = duties.indexOf(1);
      final primeiro10 = duties.indexOf(10);
      expect(fim, greaterThan(0), reason: 'the fan must reach the stop state');
      expect(
        primeiro10,
        greaterThan(0),
        reason: 'the ramp passes through 10 before stopping',
      );
      expect(fim, greaterThan(primeiro10));
      expect(duties.last, 1);

      // Antes de 10 a descida respeita a rampa de 3 por segundo.
      var anterior = 100;
      for (final d in duties.take(primeiro10)) {
        expect(anterior - d, lessThanOrEqualTo(3));
        anterior = d;
      }
      // Between the first 10 and the stop, duty stays at 10.
      expect(duties.sublist(primeiro10, fim), everyElement(10));
    });

    test('from stopped, rising to a high target goes from 1 to 15', () {
      final g = grupo(startStop: true);
      final s = FanSmoother();
      expect(s.next(g, 20, seg(0)).duty, 1);
      // Average (20 + 95) / 2 = 57.5 °C → 1283 RPM → duty 64; ramp rises 15 from 0.
      final passo = s.next(g, 95, seg(1));
      expect(passo.duty, 15);
      expect(passo.duty, greaterThanOrEqualTo(10));
    });
  });

  group('delayed and bursty cycles with a noisy source', () {
    // Tctl hovering around 52 °C with spikes. Cycles arrive late and in
    // bursts, as when the engine isolate is saturated: the duty must not flip
    // between two values.
    test('stable temperature with spikes does not make the duty alternate', () {
      final g = grupo();
      final s = FanSmoother();
      var t = DateTime(2026);
      final duties = <int>[];
      // Late cycles (3.5 s apart) and a burst (+50 ms) after each of them.
      for (var i = 0; i < 12; i++) {
        t = t.add(const Duration(milliseconds: 3500));
        final spike = i.isEven ? 52.0 : 40.0;
        duties.add(s.next(g, spike, t).duty);
        t = t.add(const Duration(milliseconds: 50));
        duties.add(s.next(g, spike, t).duty);
      }
      final tail = duties.skip(6).toList();
      final swing =
          tail.reduce((a, b) => a > b ? a : b) -
          tail.reduce((a, b) => a < b ? a : b);
      expect(swing, lessThanOrEqualTo(8), reason: '$duties');
    });

    test('a burst of cycles counts as one sample in the average', () {
      final g = grupo();
      final s = FanSmoother();
      final t = DateTime(2026);
      s.next(g, 40, t);
      for (var i = 1; i <= 10; i++) {
        s.next(g, 60, t.add(Duration(seconds: 1, milliseconds: i * 10)));
      }
      final step = s.next(g, 60, t.add(const Duration(seconds: 2)));
      expect(step.temp, closeTo((40 + 60 + 60) / 3, 0.01));
    });
  });
}
