// AL V2 canvas streaming benchmark: a rainbow moving across groups 1–3 for a
// few seconds, with different packet sets and gaps. Prints the frame rate.
//
//   dart run tool/alv2_stream_bench.dart <full|colors|noframe|short|counter|html|slow5|slow2|idle> <gapMs> [seconds] [fpsCap]
//
// full   = per port: colors + static effect, then frame (what the app does).
// colors = static effect sent once; per frame only the colors + frame.
// noframe = colors + effect per port, no `E0 60` frame.
// short  = like full, but the output report is not padded to 353 bytes.
// counter = like full, but the frame number in `E0 60 hi lo` increments.
// html = the canvas sequence: colors + `E0 (10+p) 01 02`, no frame.
// slow5 / slow2 = the canvas sequence with the payload cut to the fans each
//   group has, capped at 5 / 2 fps (the phase-4.1 slow streaming test; add
//   +probe to read the RPM during the stream; +probe10 pauses every 10 s
//   instead of 3 s, so each burst is long enough at 2 fps).
// idle = no writes at all; with +probe it reads the RPM baseline with no
//   streaming (run it after the LEDs/duty have been set).
// +windows = quantity 6 on all groups and duty 60 % every second (vendor software);
// +q6 / +duty = only one of the two.
// Run with the app closed (single owner of the hidraw).
import 'dart:io';
import 'dart:math' as math;

import 'package:lumivent/core/platform/hidapi_ffi.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/protocol.dart';

List<int> hue(double h) {
  final c = [
    0.0,
    2.0,
    4.0,
  ].map((o) => (math.cos((h * 6 - o) * math.pi / 3) * .5 + .5).clamp(0, 1));
  return [for (final v in c) (v * 255).round()];
}

void main(List<String> args) {
  // Variants combine with '+', e.g. html+short.
  final opts = args[0].split('+').toSet();
  final variant = opts.first;
  // idle: only the RPM probe, no writes (baseline for the slow test).
  final idle = variant == 'idle';
  // slow5/slow2: the canvas sequence, payload cut to the real fans and the
  // frame rate capped (phase-4.1 test: is 5 fps / 2 fps safe for the RPM?).
  final slowFps = switch (variant) {
    'slow5' => 5,
    'slow2' => 2,
    _ => 0,
  };
  final htmlEffect = variant == 'html' || slowFps > 0;
  final short = opts.contains('short');
  // trim: payload only for the fans each group really has (3, 1, 3).
  final trim = opts.contains('trim') || slowFps > 0;
  const fansOf = {1: 3, 2: 1, 3: 3};
  final gap = Duration(milliseconds: int.parse(args[1]));
  final seconds = args.length > 2 ? int.parse(args[2]) : 8;
  // Optional frame-rate cap: idle time between frames.
  final cap = args.length > 3 ? int.parse(args[3]) : slowFps;
  final hid = HidApi.open();
  final info = hid
      .enumerate(vendorId: alv2VendorId, productId: alv2ProductId)
      .firstWhere((d) => d.interfaceNumber == alv2Interface);
  final dev = hid.openPath(info.path);

  void feature(List<int> p) {
    dev.sendFeature(p, alv2FeatureLength);
    if (gap > Duration.zero) sleep(gap);
  }

  void output(List<int> p) {
    dev.write(p, short ? p.length : alv2OutputLength);
    if (gap > Duration.zero) sleep(gap);
  }

  // windows = what ran on Windows: the RGB software sets quantity 6 on every group
  // (`E0 10 60 g 06`) and the fan software resends the duty every second.
  final windows = opts.contains('windows');
  final q6 = windows || opts.contains('q6');
  final dutyEvery = windows || opts.contains('duty');
  if (q6) {
    for (var g = 0; g < 4; g++) {
      dev.sendFeature(alv2QuantityPacket(g, 6), alv2FeatureLength);
      sleep(alv2PacketGap);
    }
  }
  var nextDuty = 0;
  // +probe = every 3 s (+probeN: every N s) pause the stream for ~1.8 s and
  // read the RPM twice (readings taken during the stream are disturbed; the
  // fan's inertia keeps its real speed through the short pause). Prints the
  // clean readings.
  final probeOpt = opts.where((o) => o.startsWith('probe')).firstOrNull;
  final probe = probeOpt != null;
  final probeEveryMs =
      (int.tryParse(probeOpt?.substring('probe'.length) ?? '') ?? 3) * 1000;
  var nextProbe = probeEveryMs == 3000 ? 1500 : probeEveryMs;
  final probes = <String>[];
  List<int>? rpm() {
    dev.sendFeature(alv2ReadRpm, alv2FeatureLength);
    sleep(alv2PacketGap);
    return parseAlv2Rpm(
      alv2InputPayload(dev.getInput(alv2ReportId, alv2InputLength)),
    );
  }

  const groups = [1, 2, 3];
  // The canvas commit is the static effect with speed 0x02 (AL-V2 §3.3.1).
  final commitSpeed = htmlEffect ? 0x02 : 0x00;
  if (variant == 'colors') {
    for (final g in groups) {
      feature(alv2EffectPacket(2 * g + 1, 0x01, 0, 0, 0));
      feature(alv2EffectPacket(2 * g, 0x01, 0, 0, 0));
    }
  }
  final sw = Stopwatch()..start();
  var frames = 0;
  var writeUs = 0, writes = 0;
  var lastPrint = 0;
  while (sw.elapsed.inSeconds < seconds) {
    if (sw.elapsed.inSeconds != lastPrint) {
      lastPrint = sw.elapsed.inSeconds;
      stdout.writeln('t=${lastPrint}s frames=$frames');
    }
    final frameStart = sw.elapsedMicroseconds;
    if (probe && sw.elapsedMilliseconds >= nextProbe) {
      nextProbe += probeEveryMs;
      sleep(const Duration(milliseconds: 1200));
      final a = rpm();
      sleep(const Duration(milliseconds: 600));
      final b = rpm();
      probes.add(
        '${(sw.elapsedMilliseconds / 1000).toStringAsFixed(1)}s $a $b',
      );
    }
    if (dutyEvery && sw.elapsed.inSeconds >= nextDuty) {
      nextDuty++;
      sleep(alv2PacketGap);
      for (final g in groups) {
        dev.sendFeature(alv2DutyPacket(g, 60), alv2FeatureLength);
        sleep(alv2PacketGap);
      }
    }
    if (idle) {
      sleep(const Duration(milliseconds: 500));
      continue;
    }
    final t = sw.elapsedMilliseconds / 1000;
    for (final g in groups.reversed) {
      // Same color around each ring, hue shifting per group over time.
      final c = hue((t * .5 + g / 3) % 1);
      final n = trim ? fansOf[g]! : alv2MaxFans;
      final outer = [for (var i = 0; i < n * 12; i++) ...c];
      final inner = [for (var i = 0; i < n * 8; i++) ...c];
      final w = Stopwatch()..start();
      output(alv2ColorPacket(2 * g + 1, outer));
      writeUs += w.elapsedMicroseconds;
      writes++;
      if (variant != 'colors') {
        feature(alv2EffectPacket(2 * g + 1, 0x01, commitSpeed, 0, 0));
      }
      output(alv2ColorPacket(2 * g, inner));
      if (variant != 'colors') {
        feature(alv2EffectPacket(2 * g, 0x01, commitSpeed, 0, 0));
      }
    }
    if (variant == 'counter') {
      final n = frames + 1;
      feature([alv2ReportId, 0x60, (n >> 8) & 0xFF, n & 0xFF]);
    } else if (variant != 'noframe' && !htmlEffect) {
      feature(alv2FramePacket);
    }
    frames++;
    if (cap > 0) {
      final left = 1000000 ~/ cap - (sw.elapsedMicroseconds - frameStart);
      if (left > 0) sleep(Duration(microseconds: left));
    }
  }
  stdout.writeln(
    '$variant gap=${gap.inMilliseconds}ms: '
    '${(frames / sw.elapsed.inMilliseconds * 1000).toStringAsFixed(1)} fps, '
    'hid_write ~${writes == 0 ? 0 : (writeUs / writes / 1000).toStringAsFixed(1)} ms (incl. gap)',
  );
  for (final p in probes) {
    stdout.writeln('probe $p');
  }
  dev.close();
  hid.dispose();
}
