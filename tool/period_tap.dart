// Phase 4.1 tap timer: sends a firmware breathing mode and times the peaks
// the user marks with Enter (checklist-hardware-fase4-1.md §1 and §2).
//
//   dart run tool/period_tap.dart <fans|ite|case> [levels] [out.json] [r,g,b]
//
// The color defaults to white: with all channels the peak is easier to see.
//
// fans = AL V2 `Breathing` on groups 1–3, levels 0–4 by default.
// ite  = ITE `Pulse` on zone 0 (IO Shield 1), levels 1–8 by default.
// case = the case strip breathing in software (the app's sine) with the
//        period in ms given as the level (default 9510): checks the taps
//        against a known period.
// levels = comma-separated, e.g. `0,2,4`.
//
// For each level: everything else is dark, the mode is sent and the user
// presses Enter on every brightness peak. After 6 peaks the tool resends the
// same mode a quarter period after the last peak and asks for the next peak:
// right after the resend = restarts bright, half a period = restarts dark,
// three quarters = keeps running. Typing `n` skips to the next level, `q`
// quits. Run in a real terminal with the app closed.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:lumivent/features/devices/infrastructure/drivers/alv2/hub.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/lighting.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/ite5702/controller.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/ite5702/effects.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/kingston_fury/controller.dart';

const peaksPerLevel = 6;

final _clock = Stopwatch()..start();
double _now() => _clock.elapsedMicroseconds / 1e6;

/// Lines typed by the user, each with the instant Enter was pressed.
final _lines = <(String, double)>[];
Completer<void>? _waiting;

Future<(String, double)> nextLine() async {
  while (_lines.isEmpty) {
    _waiting = Completer<void>();
    await _waiting!.future;
  }
  return _lines.removeAt(0);
}

/// Period from peak instants: intervals are rounded to whole periods, so a
/// missed peak (an interval of ~2 periods) does not skew the result.
double? periodOf(List<double> peaks) {
  if (peaks.length < 2) return null;
  final gaps = [for (var i = 1; i < peaks.length; i++) peaks[i] - peaks[i - 1]];
  final sorted = [...gaps]..sort();
  final median = sorted[sorted.length ~/ 2];
  var total = 0.0;
  var cycles = 0;
  for (final g in gaps) {
    final k = (g / median).round();
    if (k < 1) continue; // double tap
    total += g;
    cycles += k;
  }
  return cycles == 0 ? null : total / cycles;
}

String verdict(double sinceResend, double period) {
  final f = (sinceResend / period) % 1.0;
  if (f < 0.25 || f > 0.9) return 'recomeça aceso';
  if (f < 0.62) return 'recomeça apagado';
  return 'continua (não recomeça)';
}

Future<void> main(List<String> args) async {
  final target = args.firstOrNull;
  if (!const {'fans', 'ite', 'case'}.contains(target)) {
    stderr.writeln(
      'usage: dart run tool/period_tap.dart <fans|ite|case> [levels] [out.json] [r,g,b]',
    );
    exitCode = 64;
    return;
  }
  final levels = args.length > 1
      ? args[1].split(',').map(int.parse).toList()
      : switch (target) {
          'fans' => [0, 1, 2, 3, 4],
          'case' => [9510],
          _ => [1, 2, 3, 4, 5, 6, 7, 8],
        };
  final outPath = args.length > 2 ? args[2] : 'build/period_tap_$target.json';
  final rgb = args.length > 3
      ? args[3].split(',').map(int.parse).toList()
      : const [255, 255, 255];

  stdin.transform(utf8.decoder).transform(const LineSplitter()).listen((l) {
    _lines.add((l.trim().toLowerCase(), _now()));
    _waiting?.complete();
    _waiting = null;
  });

  final hub = Alv2Hub.open();
  final ite = IteController.open();
  final fury = FuryController();
  await hub.sendLighting(alv2OffWrites());
  ite.allOff();
  fury.setSingleColor(0, 0, 0, 0);
  fury.setSingleColor(1, 0, 0, 0);

  // Software breathing of the case strip (target `case`).
  Timer? caseTimer;
  // [rgb] scaled by [k] (0–1) on [n] LEDs.
  List<int> shade(int n, double k) => [
    for (var i = 0; i < n; i++)
      for (final c in rgb) (c * k).round(),
  ];
  void caseOff() {
    caseTimer?.cancel();
    caseTimer = null;
    ite.streamCase(shade(47, 0));
  }

  Future<bool> send(int level) async {
    if (target == 'case') {
      caseTimer?.cancel();
      ite.init();
      final start = _now();
      caseTimer = Timer.periodic(const Duration(milliseconds: 20), (_) {
        final u = (_now() - start) * 1000 / level;
        ite.streamCase(shade(47, 0.5 - 0.5 * math.cos(2 * math.pi * u)));
      });
      return true;
    }
    if (target == 'fans') {
      final effect = Alv2Effect(
        Alv2LightMode.breathing,
        colors: [for (var i = 0; i < 6; i++) ...rgb],
        speedLevel: level,
      );
      return hub.sendLighting(
        alv2ServiceOrder([
          for (final g in [1, 2, 3]) ...alv2WholeWrites(g, effect),
        ]),
      );
    }
    return ite.setZoneEffects({
      0: IteHardwareEffect(
        IteHardwareMode.pulse,
        color: (rgb[0], rgb[1], rgb[2]),
        speed: level,
        brightness: 9,
      ),
    });
  }

  final what = switch (target) {
    'fans' => 'as fans (use sempre a mesma, a traseira é a mais fácil)',
    'case' => 'a fita do gabinete',
    _ => 'a tampa do I/O da placa (IO Shield)',
  };
  stdout.writeln(
    '\nOlhe para $what. Em cada nível, aperte Enter no PICO de brilho de cada '
    'ciclo ($peaksPerLevel picos). n + Enter = pular o nível, q + Enter = sair.\n',
  );

  final results = <Map<String, Object?>>[];
  levelLoop:
  for (final level in levels) {
    // Start from dark, so a bright start shows as a peak right after the send.
    switch (target) {
      case 'fans':
        await hub.sendLighting(alv2OffWrites());
      case 'case':
        caseOff();
      default:
        ite.allOff();
    }
    await Future<void>.delayed(const Duration(seconds: 2));
    _lines.clear();
    final sentAt = _now();
    final sent = await send(level);
    stdout.writeln(
      '── Nível $level ${sent ? 'enviado' : 'FALHOU ao enviar'}. '
      'Marque $peaksPerLevel picos.',
    );
    final peaks = <double>[];
    while (peaks.length < peaksPerLevel) {
      final (line, at) = await nextLine();
      if (line == 'q') break levelLoop;
      if (line == 'n') continue levelLoop;
      peaks.add(at);
      stdout.writeln(
        '  pico ${peaks.length} (${(at - sentAt).toStringAsFixed(2)} s)',
      );
    }
    final period = periodOf(peaks)!;
    stdout.writeln('  período ≈ ${period.toStringAsFixed(2)} s');

    // Restart test: resend a quarter period after the last peak.
    final resendAt = peaks.last + period / 4;
    final wait = resendAt - _now();
    if (wait > 0) {
      await Future<void>.delayed(Duration(microseconds: (wait * 1e6).round()));
    }
    _lines.clear();
    final resentAt = _now();
    await send(level);
    stdout.writeln('  modo REENVIADO: aperte Enter no próximo pico.');
    final (line, at) = await nextLine();
    if (line == 'q') break;
    final result = <String, Object?>{
      'target': target,
      'level': level,
      'periodS': double.parse(period.toStringAsFixed(3)),
      'firstPeakAfterSendS': double.parse(
        (peaks.first - sentAt).toStringAsFixed(3),
      ),
      'peaksAfterSendS': [
        for (final p in peaks) double.parse((p - sentAt).toStringAsFixed(3)),
      ],
    };
    if (line != 'n') {
      final since = at - resentAt;
      result['peakAfterResendS'] = double.parse(since.toStringAsFixed(3));
      result['resend'] = verdict(since, period);
      stdout.writeln(
        '  pico ${since.toStringAsFixed(2)} s depois do reenvio: '
        '${result['resend']}',
      );
    }
    results.add(result);
  }

  caseTimer?.cancel();
  await hub.sendLighting(alv2OffWrites());
  ite.allOff();
  hub.dispose();
  ite.dispose();
  fury.close();

  File(outPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(results));
  stdout.writeln('\nResultado salvo em $outPath');
  exit(0);
}
