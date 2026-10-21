import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/fans/domain/fan_curve.dart';
import 'package:lumivent/features/fans/domain/fan_group.dart';
import 'package:lumivent/features/fans/domain/fan_response.dart';

void main() {
  group('dutyFor', () {
    test('RPM 0 becomes duty 1 (stop)', () {
      expect(dutyFor(0, FanSize.mm120), 1);
    });

    test('maximum RPM at 120 mm becomes 100%', () {
      expect(dutyFor(2000, FanSize.mm120), 100);
    });

    test('low RPM stays at the 10% minimum', () {
      expect(dutyFor(100, FanSize.mm120), 10);
    });

    test('maximum RPM at 140 mm becomes 100%', () {
      expect(dutyFor(1600, FanSize.mm140), 100);
    });

    test('RPM above the maximum is capped at 100%', () {
      expect(dutyFor(2500, FanSize.mm120), 100);
    });
  });

  group('toRpmPhases', () {
    const standardPhases = [
      RpmPhase(0, 250),
      RpmPhase(25, 400),
      RpmPhase(40, 1000),
      RpmPhase(55, 1240),
      RpmPhase(70, 1500),
      RpmPhase(90, 2000),
      RpmPhase(100, 2000),
    ];

    test(
      'without start/stop it starts at (0 °C, Min) and ends at (100 °C, Max)',
      () {
        expect(
          toRpmPhases(FanPresets.standard, FanSize.mm120, startStop: false),
          standardPhases,
        );
      },
    );

    test('with start/stop the first point becomes (T, 0 RPM)', () {
      final phases = toRpmPhases(
        FanPresets.standard,
        FanSize.mm120,
        startStop: true,
      );
      expect(phases, [
        const RpmPhase(25, 0),
        const RpmPhase(25, 400),
        const RpmPhase(40, 1000),
        const RpmPhase(55, 1240),
        const RpmPhase(70, 1500),
        const RpmPhase(90, 2000),
        const RpmPhase(100, 2000),
      ]);
    });

    test('out-of-order points are sorted', () {
      final embaralhados = FanPresets.standard.reversed.toList();
      expect(
        toRpmPhases(embaralhados, FanSize.mm120, startStop: false),
        standardPhases,
      );
    });
  });

  group('fixedRpmPhases', () {
    test('Fixed mode at 50% on 120 mm stays at 1000 RPM from 0 to 100 °C', () {
      final phases = fixedRpmPhases(50, FanSize.mm120);
      expect(phases, [const RpmPhase(0, 1000), const RpmPhase(100, 1000)]);
      expect(calculateSpeed(phases, 0), 1000);
      expect(calculateSpeed(phases, 100), 1000);
    });
  });

  group('calculateSpeed', () {
    final standard = toRpmPhases(
      FanPresets.standard,
      FanSize.mm120,
      startStop: false,
    );
    final startStop = toRpmPhases(
      FanPresets.standard,
      FanSize.mm120,
      startStop: true,
    );

    test('0 °C uses the first phase (250 RPM)', () {
      expect(calculateSpeed(standard, 0), 250);
    });

    test('below 0 °C it stays at the first phase', () {
      expect(calculateSpeed(standard, -10), 250);
    });

    test('exactly at a point it uses that point RPM', () {
      expect(calculateSpeed(standard, 25), 400);
    });

    test(
      'linearly interpolates in the middle of the segment (32.5 °C → 700)',
      () {
        expect(calculateSpeed(standard, 32.5), 700);
      },
    );

    test('linearly interpolates in the 40–55 °C segment (47.5 °C → 1120)', () {
      expect(calculateSpeed(standard, 47.5), 1120);
    });

    test('100 °C and above stay at the last phase (2000 RPM)', () {
      expect(calculateSpeed(standard, 100), 2000);
      expect(calculateSpeed(standard, 120), 2000);
    });

    test('with start/stop, 20 °C below the step it stops at 0 RPM', () {
      expect(calculateSpeed(startStop, 20), 0);
    });

    test('with start/stop, exactly at the step temperature it uses the first phase (0 RPM)', () {
      expect(calculateSpeed(startStop, 25), 0);
    });

    test('with start/stop, 30 °C interpolates between (25, 400) and (40, 1000) → 600', () {
      expect(calculateSpeed(startStop, 30), 600);
    });

    test('an empty phase list returns 0', () {
      expect(calculateSpeed(const [], 50), 0);
    });
  });

  group('FanTempSource', () {
    test('CPU and GPU are not motherboard sensors', () {
      expect(FanTempSource.cpuTctl.isBoard, isFalse);
      expect(FanTempSource.gpuJunction.isBoard, isFalse);
      expect(FanTempSource.gpuEdge.isBoard, isFalse);
    });

    test('motherboard sensors are isBoard', () {
      expect(FanTempSource.boardSystem1.isBoard, isTrue);
      expect(FanTempSource.boardVrm.isBoard, isTrue);
      expect(FanTempSource.boardPciex4.isBoard, isTrue);
    });
  });

  group('FanGroupConfig', () {
    FanGroupConfig grupo({
      FanPreset preset = FanPreset.standard,
      FanSize size = FanSize.mm120,
      Map<FanPreset, List<FanPoint>> userPoints = const {},
      double fixedPercent = FanPresets.defaultFixedPercent,
    }) => FanGroupConfig(
      group: 0,
      name: 'Grupo 0',
      size: size,
      preset: preset,
      userPoints: userPoints,
      fixedPercent: fixedPercent,
    );

    test('default preset is Standard', () {
      const cfg = FanGroupConfig(group: 0, name: 'G');
      expect(cfg.preset, FanPreset.standard);
      expect(cfg.size, FanSize.mm120);
      expect(cfg.startStop, isFalse);
    });

    test('default response is normal', () {
      const cfg = FanGroupConfig(group: 0, name: 'G');
      expect(cfg.response, FanResponse.normal);
    });

    test('duty(55) on 120 mm uses the 1240 RPM phase → 62%', () {
      expect(grupo().duty(55), 62);
    });

    test(
      'withPoints on a factory preset becomes custom with sorted points',
      () {
        final cfg = grupo().withPoints([
          const FanPoint(90, 100),
          const FanPoint(25, 20),
        ]);
        expect(cfg.preset, FanPreset.custom);
        expect(cfg.customPoints, [
          const FanPoint(25, 20),
          const FanPoint(90, 100),
        ]);
        expect(cfg.points, cfg.customPoints);
      },
    );

    test('withPoints on UserDefine stores userPoints and keeps the preset', () {
      final cfg = grupo(preset: FanPreset.user2)
          .withPoints([const FanPoint(30, 40)]);
      expect(cfg.preset, FanPreset.user2);
      expect(cfg.userPoints[FanPreset.user2], [const FanPoint(30, 40)]);
      expect(cfg.points, [const FanPoint(30, 40)]);
    });

    test(
      'withPoints on Fixed only changes fixedPercent from the first point',
      () {
        final original = grupo(preset: FanPreset.fixed);
        final cfg = original.withPoints([
          const FanPoint(60, 80),
          const FanPoint(10, 30),
        ]);
        expect(cfg.preset, FanPreset.fixed);
        expect(cfg.fixedPercent, 30);
        expect(cfg.customPoints, original.customPoints);
        expect(cfg.points, [const FanPoint(50, 30)]);
      },
    );

    test('withPoints limits to 8 points, keeping the lowest temperatures', () {
      final dez = [for (var i = 1; i <= 10; i++) FanPoint(10.0 * i, 10)];
      final cfg = grupo().withPoints(dez.reversed.toList());
      expect(cfg.customPoints.length, FanPresets.maxPoints);
      expect(cfg.customPoints.first.temp, 10);
      expect(cfg.customPoints.last.temp, 80);
    });

    test('exitDuty without temperature uses Standard at 70 °C (75%)', () {
      expect(grupo().exitDuty(null), 75);
      expect(grupo(preset: FanPreset.full).exitDuty(null), 75);
    });

    test('exitDuty on Standard 140 mm at 55 °C: 992 RPM → duty 62', () {
      expect(grupo(size: FanSize.mm140).exitDuty(55), 62);
    });

    test('exitDuty follows the group custom curve, not Standard', () {
      final cfg = grupo().withPoints([
        const FanPoint(25, 20),
        const FanPoint(47, 86),
      ]);
      expect(cfg.exitDuty(47), cfg.duty(47));
      expect(cfg.exitDuty(47), greaterThan(grupo().exitDuty(47)));
    });

    test('exitDuty keeps Fixed mode at its percentage', () {
      final cfg = grupo(preset: FanPreset.fixed, fixedPercent: 30);
      expect(cfg.exitDuty(80), cfg.duty(80));
    });

    test('exitDuty ignores start/stop so the fan never stays stopped', () {
      final cfg = grupo().copyWith(startStop: true);
      expect(cfg.duty(20), 1);
      expect(cfg.exitDuty(20), 19); // 250 RPM at 0 °C → 400 at 25 °C: 370 RPM
    });

    test('UserDefine without saved points uses Quiet points', () {
      final cfg = grupo(preset: FanPreset.user1);
      expect(cfg.points, FanPresets.quiet);
    });
  });

  group('FansConfig', () {
    test(
      'defaults have 4 groups; group 1 is 140 mm and the others are 120 mm',
      () {
        final cfg = FansConfig.defaults();
        expect(cfg.groups.length, fanGroupCount);
        expect(cfg.groups.map((g) => g.group), [0, 1, 2, 3]);
        expect(cfg.groups.map((g) => g.size), [
          FanSize.mm120,
          FanSize.mm140,
          FanSize.mm120,
          FanSize.mm120,
        ]);
      },
    );

    test(
      'curveAppliedToAll copies the curve to the others keeping name and size',
      () {
        final base = FansConfig.defaults();
        final origem = base[1].copyWith(
          preset: FanPreset.high,
          startStop: true,
          source: FanTempSource.gpuEdge,
          response: FanResponse.smooth,
        );
        final cfg = base.replaced(origem).curveAppliedToAll(1);

        for (final g in [0, 2, 3]) {
          expect(cfg[g].preset, FanPreset.high);
          expect(cfg[g].startStop, isTrue);
          expect(cfg[g].source, FanTempSource.gpuEdge);
          expect(cfg[g].response, FanResponse.smooth);
          expect(cfg[g].name, base[g].name);
          expect(cfg[g].size, base[g].size);
        }
        expect(cfg[1], origem);
      },
    );

    test('replaced changes only the given group', () {
      final base = FansConfig.defaults();
      final novo = base[2].copyWith(preset: FanPreset.full);
      final cfg = base.replaced(novo);

      expect(cfg[2].preset, FanPreset.full);
      for (final g in [0, 1, 3]) {
        expect(cfg[g], base[g]);
      }
    });
  });
}
