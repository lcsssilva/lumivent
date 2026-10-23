// Phase 4 hardware checklist, one step per run, using the real drivers.
// Each step sends a recognizable pattern; the user confirms what lit up.
//
//   dart run tool/hw_test_fase4.dart <step>
//
// Steps: case, board, zones, zonesonly, fans, groups, fan0, fanorder, merge, ram,
// ramorder, hwfans, hwboard, hwzone, hwall, streamthen, off, restore.
//
// Run with OpenRGB, liquidctl, and the app itself closed. "off" then "restore"
// reproduces the app's "Desligar/Religar ARGB". "merge" sends `E0 10 60 01 00`
// (group 0 with 0 fans) with the merge order, to see whether merge survives an
// empty group 0. Suspend (logind) has no step here: it needs the app running.
import 'dart:io';
import 'dart:math' as math;

import 'package:lumivent/features/devices/infrastructure/drivers/alv2/alv2_hub.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/alv2_port_writes.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/lighting.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/alv2_effect.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/alv2/alv2_port_write.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/ite5702/ite_controller.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/ite5702/ite_hardware_effect.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/kingston_fury/fury_controller.dart';

List<int> fill(int n, int r, int g, int b) => [
  for (var i = 0; i < n; i++) ...[r, g, b],
];

void set(List<int> rgb, int led, int r, int g, int b) =>
    rgb.setAll(led * 3, [r, g, b]);

(int, int, int) zone(String s) {
  final v = s.split(',').map(int.parse).toList();
  return (v[0], v[1], v[2]);
}

bool ok(String what, bool result) {
  stdout.writeln('${result ? 'OK  ' : 'FAIL'} $what');
  return result;
}

Future<void> main(List<String> args) async {
  final step = args.firstOrNull;
  switch (step) {
    case 'case':
      // LED 0 green, LEDs 10/20/30/40 blue, LED 46 red, the rest dim white.
      final ite = IteController.open();
      final rgb = fill(47, 20, 20, 20);
      set(rgb, 0, 0, 255, 0);
      for (final i in [10, 20, 30, 40]) {
        set(rgb, i, 0, 0, 255);
      }
      set(rgb, 46, 255, 0, 0);
      final ready = ite.init();
      ok('ITE init (${ite.info?.description})', ready);
      ok('D_LED1 stream (47 LEDs)', ite.streamCase(rgb));
      ite.dispose();
    case 'board':
      final ite = IteController.open();
      ok(
        'zones 0x20 red, 0x22 green, 0x23 blue',
        ite.setZoneColors({
          0x20: (255, 0, 0),
          0x22: (0, 255, 0),
          0x23: (0, 0, 255),
        }),
      );
      // The zone commit may take D_LED1 out of direct mode: resend the case.
      ok(
        'D_LED1 still streaming (all purple)',
        ite.streamCase(fill(47, 120, 0, 255)),
      );
      ite.dispose();
    case 'zones':
      // zones <0x20 r,g,b> <0x22 r,g,b> <0x23 r,g,b>, e.g. zones 255,0,0 0,0,0 0,0,0
      final ite = IteController.open();
      ok(
        'zones ${args.skip(1).join(' ')}',
        ite.setZoneColors({
          0x20: zone(args[1]),
          0x22: zone(args[2]),
          0x23: zone(args[3]),
        }),
      );
      ite.dispose();
    case 'zonesonly':
      // Same arguments as `zones`, but never resends the case: `CC 28 FF` is
      // the only packet after the zone colors. Run `case` first, remember the
      // strip pattern, then run this. If the strip keeps the pattern, the zone
      // commit did NOT take D_LED1 out of direct mode; if it falls back to a
      // default effect, it did.
      final ite = IteController.open();
      ok(
        'zones only ${args.skip(1).join(' ')}',
        ite.setZoneColors({
          0x20: zone(args[1]),
          0x22: zone(args[2]),
          0x23: zone(args[3]),
        }),
      );
      ite.dispose();
    case 'fans':
      // Canvas mode: group 1 red, group 2 green, group 3 blue (3 fans each).
      final hub = Alv2Hub.open();
      ok(
        'leave merge (all ports off)',
        await hub.sendLighting(alv2OffWrites()),
      );
      ok('ARGB sync off', hub.disableArgbSync());
      for (final g in [1, 2, 3]) {
        ok('quantity group $g = 3', hub.setQuantity(g, 3));
      }
      const colors = {1: (255, 0, 0), 2: (0, 255, 0), 3: (0, 0, 255)};
      final writes = [
        for (final MapEntry(key: g, value: (r, gr, b)) in colors.entries)
          ...alv2CanvasWrites(g, 3, fill(60, r, gr, b)),
      ];
      ok('canvas frame', await hub.sendLighting(alv2ServiceOrder(writes)));
      hub.dispose();
    case 'groups':
      // Which fans hang on which hub group, after re-plugging: the RPM of
      // the 4 groups, then group 0 white, 1 red, 2 green, 3 blue, with 6
      // fans each so an extra fan in a chain lights up too.
      final hub = Alv2Hub.open();
      stdout.writeln('RPM groups 0–3: ${hub.readRpm()}');
      ok(
        'leave merge (all ports off)',
        await hub.sendLighting(alv2OffWrites()),
      );
      ok('ARGB sync off', hub.disableArgbSync());
      for (final g in [0, 1, 2, 3]) {
        ok('quantity group $g = 6', hub.setQuantity(g, 6));
      }
      const colors = {
        0: (255, 255, 255),
        1: (255, 0, 0),
        2: (0, 255, 0),
        3: (0, 0, 255),
      };
      final writes = [
        for (final MapEntry(key: g, value: (r, gr, b)) in colors.entries)
          ...alv2CanvasWrites(g, 6, fill(120, r, gr, b)),
      ];
      ok('canvas frame', await hub.sendLighting(alv2ServiceOrder(writes)));
      hub.dispose();
    case 'fan0':
      // Only LED 0 of each ring, white; everything else off. Tells where the
      // first LED lands and whether the outer ring's LED 0 is visible.
      final hub = Alv2Hub.open();
      final rgb = fill(60, 0, 0, 0);
      set(rgb, 0, 255, 255, 255);
      set(rgb, 8, 255, 255, 255);
      ok(
        'leave merge (all ports off)',
        await hub.sendLighting(alv2OffWrites()),
      );
      ok(
        'fan 1 ring starts (LED 0 white)',
        await hub.sendLighting(alv2CanvasWrites(1, 3, rgb)),
      );
      hub.dispose();
    case 'fanorder':
      // Fan 1: inner LEDs 0..3 white, red, green, blue; outer LEDs 0..3 the
      // same sequence; everything else off. Fan 2 all yellow, fan 3 off.
      final hub = Alv2Hub.open();
      final rgb = fill(60, 0, 0, 0);
      const seq = [(255, 255, 255), (255, 0, 0), (0, 255, 0), (0, 0, 255)];
      ok(
        'leave merge (all ports off)',
        await hub.sendLighting(alv2OffWrites()),
      );
      for (var i = 0; i < seq.length; i++) {
        final (r, g, b) = seq[i];
        set(rgb, i, r, g, b);
        set(rgb, 8 + i, r, g, b);
      }
      for (var i = 20; i < 40; i++) {
        set(rgb, i, 255, 200, 0);
      }
      ok(
        'group 1 order pattern',
        await hub.sendLighting(alv2CanvasWrites(1, 3, rgb)),
      );
      hub.dispose();
    case 'merge':
      // Group 0 with 0 fans, groups 1–3 with 3 fans, merge order [0,1,2,3],
      // then a Mixing merge across all groups. Watch whether the four groups
      // animate as one and whether the empty group 0 breaks it.
      final hub = Alv2Hub.open();
      ok('ARGB sync off', hub.disableArgbSync());
      for (final g in [0, 1, 2, 3]) {
        ok(
          "quantity group $g = ${const [0, 3, 1, 3][g]}",
          hub.setQuantity(g, const [0, 3, 1, 3][g]),
        );
      }
      ok('merge order 0,1,2,3', hub.setMergeOrder([0, 1, 2, 3]));
      const effect = Alv2Effect(
        Alv2LightMode.mixingMerge,
        colors: [255, 0, 0, 0, 0, 255],
      );
      ok('merge wave frame', await hub.sendLighting(alv2MergeWrites(effect)));
      hub.dispose();
    case 'ram':
      final fury = FuryController();
      ok('RAM 1 (0x61) red', fury.setColors(0, fill(12, 255, 0, 0)));
      ok('RAM 2 (0x63) blue', fury.setColors(1, fill(12, 0, 0, 255)));
      for (final s in [0, 1]) {
        final why = fury.disabledReason(s);
        if (why != null) stdout.writeln('slot $s disabled: $why');
      }
      fury.close();
    case 'ramorder':
      // LED 0 white, LED 11 red, the rest dim green (both sticks).
      final fury = FuryController();
      final rgb = fill(12, 0, 30, 0);
      set(rgb, 0, 255, 255, 255);
      set(rgb, 11, 255, 0, 0);
      ok('RAM 1 order pattern', fury.setColors(0, rgb));
      ok('RAM 2 order pattern', fury.setColors(1, rgb));
      fury.close();
    case 'hwfans':
      // Hardware (firmware) modes: group 1 Rainbow, group 2 Breathing red,
      // group 3 ColorCycle with four colors. Exits any merge first (a merge on
      // port 0 makes the firmware ignore the per-group effects).
      final hub = Alv2Hub.open();
      ok(
        'leave merge (all ports off)',
        await hub.sendLighting(alv2OffWrites()),
      );
      final writes = [
        ...alv2WholeWrites(1, const Alv2Effect(Alv2LightMode.rainbow)),
        ...alv2WholeWrites(
          2,
          const Alv2Effect(
            Alv2LightMode.breathing,
            colors: [255, 0, 0, 255, 0, 0, 255, 0, 0],
          ),
        ),
        ...alv2WholeWrites(
          3,
          const Alv2Effect(
            Alv2LightMode.colorCycle,
            colors: [255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 0],
          ),
        ),
      ];
      ok('hardware modes', await hub.sendLighting(alv2ServiceOrder(writes)));
      hub.dispose();
    case 'sync':
      // sync <delayMs> — every second all devices flip red/blue. The fans are
      // streamed first (awaited); the case, board and RAM follow [delayMs]
      // after the fan frame completes. With 0 the others are sent right after
      // the fans: if the fans still look late, the hub firmware adds display
      // latency on top of the USB send. Raise delayMs until they look aligned.
      final delayMs = int.parse(args[1]);
      final hub = Alv2Hub.open();
      final ite = IteController.open();
      final fury = FuryController();
      const fansOf = {1: 3, 2: 1, 3: 3};
      for (var i = 0; i < 12; i++) {
        final (r, g, b) = i.isEven ? (255, 0, 0) : (0, 0, 255);
        final t0 = DateTime.now();
        await hub.streamCanvas([
          for (final MapEntry(key: grp, value: n) in fansOf.entries)
            ...alv2CanvasWrites(grp, n, fill(n * 20, r, g, b)),
        ]);
        final fanMs = DateTime.now().difference(t0).inMilliseconds;
        if (delayMs > 0) {
          await Future<void>.delayed(Duration(milliseconds: delayMs));
        }
        ite.streamCase(fill(47, r, g, b));
        ite.setZoneColors({0x20: (r, g, b)});
        fury.setColors(0, fill(12, r, g, b));
        fury.setColors(1, fill(12, r, g, b));
        stdout.writeln('flip $i: fans sent in $fanMs ms');
        await Future<void>.delayed(const Duration(milliseconds: 1000));
      }
      hub.dispose();
      ite.dispose();
      fury.close();
    case 'breath':
      // breath <leadMs> [seconds] — continuous red breathing (1 cycle / 2 s).
      // The case and board show the present; the fans get the colors of
      // `now + leadMs`. Find the lead at which both breathe in phase while
      // streaming continuously (the `sync` step measures a single flip).
      final leadMs = int.parse(args[1]);
      final seconds = args.length > 2 ? int.parse(args[2]) : 15;
      final hub = Alv2Hub.open();
      final ite = IteController.open();
      const fansOf = {1: 3, 2: 1, 3: 3};
      int level(double t) => (127.5 - 127.5 * math.cos(math.pi * t)).round();
      final sw = Stopwatch()..start();
      var frames = 0;
      while (sw.elapsed.inSeconds < seconds) {
        final t = sw.elapsedMicroseconds / 1e6;
        final f = level(t + leadMs / 1000);
        await hub.streamCanvas([
          for (final MapEntry(key: grp, value: n) in fansOf.entries)
            ...alv2CanvasWrites(grp, n, fill(n * 20, f, 0, 0)),
        ]);
        final c = level(sw.elapsedMicroseconds / 1e6);
        ite.streamCase(fill(47, c, 0, 0));
        ite.setZoneColors({0x20: (c, 0, 0)});
        frames++;
      }
      stdout.writeln(
        'lead $leadMs ms: ${(frames / seconds).toStringAsFixed(1)} fps',
      );
      hub.dispose();
      ite.dispose();
    case 'fanload':
      // fanload [seconds] — the app's hub traffic in one owner: continuous
      // canvas streaming plus, every second, duty 60 % on groups 1–3 and an
      // RPM read. With duty following the curve, RPM must stay near 60 % of
      // Max (~975 / ~1200 / ~1200) and the fans must not audibly slow down.
      // fanload [seconds] [once] — with `once` the duty is set only before the
      // stream starts (tells PWM disturbance by the stream from bad duties).
      final seconds = args.length > 1 ? int.parse(args[1]) : 20;
      final once = args.contains('once');
      final hub = Alv2Hub.open();
      const fansOf = {1: 3, 2: 1, 3: 3};
      if (once) {
        for (final g in [1, 2, 3]) {
          hub.setDuty(g, 60);
        }
      }
      final sw = Stopwatch()..start();
      var nextControl = 0;
      while (sw.elapsed.inSeconds < seconds) {
        final t = sw.elapsedMicroseconds / 1e6;
        final c = (127.5 - 127.5 * math.cos(math.pi * t)).round();
        await hub.streamCanvas([
          for (final MapEntry(key: grp, value: n) in fansOf.entries)
            ...alv2CanvasWrites(grp, n, fill(n * 20, c, 0, 255 - c)),
        ]);
        if (sw.elapsed.inSeconds >= nextControl) {
          nextControl++;
          if (!once) {
            for (final g in [1, 2, 3]) {
              hub.setDuty(g, 60);
            }
          }
          stdout.writeln('t=${sw.elapsed.inSeconds}s rpm ${hub.readRpm()}');
        }
      }
      hub.dispose();
    case 'hwmode':
      // hwmode <group> <mode name> [speed 0-4] [brightness 0-4] [r,g,b ...]
      // e.g. hwmode 2 Breathing 3 4 255,0,0 255,0,0 255,0,0
      final group = int.parse(args[1]);
      final mode = Alv2LightMode.byName(args[2])!;
      final colors = [
        for (final c in args.skip(5)) ...c.split(',').map(int.parse),
      ];
      final effect = Alv2Effect(
        mode,
        colors: colors,
        speedLevel: args.length > 3 ? int.parse(args[3]) : 3,
        brightnessLevel: args.length > 4 ? int.parse(args[4]) : 4,
      );
      final hub = Alv2Hub.open();
      ok(
        'group $group ${mode.firmwareName}',
        await hub.sendLighting(
          alv2ServiceOrder(alv2WholeWrites(group, effect)),
        ),
      );
      hub.dispose();
    case 'hwboard':
      // IO Shield 1 pulsing red, IO Shield 2 wave, LED_CPU static green.
      final ite = IteController.open();
      ok(
        'zone effects',
        await ite.setZoneEffects({
          0: const IteHardwareEffect(
            IteHardwareMode.pulse,
            color: (255, 0, 0),
            speed: 5,
            brightness: 9,
          ),
          2: const IteHardwareEffect(
            IteHardwareMode.staticColor,
            color: (0, 255, 0),
            speed: 0,
            brightness: 8,
          ),
          3: const IteHardwareEffect(
            IteHardwareMode.wave,
            color: (0, 0, 255),
            speed: 5,
            brightness: 9,
          ),
        }),
      );
      ite.dispose();
    case 'hwzone':
      // hwzone <z|z,z,...> <mode> <r,g,b> [speed] [brightness], e.g.
      // hwzone 3 wave 0,0,255 5 9 — one (or more) zone effect at a time, to
      // tell a non-working mode from a clash when several zones share the
      // same LEDs. Comma-separated zones go in one apply mask.
      final zs = args[1].split(',').map(int.parse);
      final mode = IteHardwareMode.values.singleWhere(
        (m) => m.name.toLowerCase() == args[2].toLowerCase(),
      );
      final ite = IteController.open();
      ok(
        'zones ${args[1]} ${mode.name} ${args[3]}',
        await ite.setZoneEffects({
          for (final z in zs)
            z: IteHardwareEffect(
              mode,
              color: zone(args[3]),
              speed: args.length > 4 ? int.parse(args[4]) : 5,
              brightness: args.length > 5 ? int.parse(args[5]) : 9,
            ),
        }),
      );
      ite.dispose();
    case 'breathcal':
      // breathcal <speed 0-4> count [seconds] — groups 1–3 in firmware
      // Breathing (red); count the bright peaks to estimate the period.
      // breathcal <speed 0-4> <periodMs> <offsetMs> [seconds] [traffic] — the
      // same, and the case and RAM breathe in software with [periodMs], phase 0
      // (dark) [offsetMs] after the fan mode was sent. Tune until both stay in
      // step: a steady gap means the offset is wrong, a growing gap the period.
      // traffic = none (default) | app: duty 60 % on groups 1–3 and an RPM
      // read every second, as the running app does.
      final speed = int.parse(args[1]);
      final count = args[2] == 'count';
      final periodMs = count ? 0 : int.parse(args[2]);
      final offsetMs = count ? 0 : int.parse(args[3]);
      final seconds = int.parse(args.elementAtOrNull(count ? 3 : 4) ?? '30');
      final appTraffic = !count && args.elementAtOrNull(5) == 'app';
      final hub = Alv2Hub.open();
      final ite = IteController.open();
      final fury = FuryController();
      if (!count) {
        ite.init();
        ite.streamCase(fill(47, 0, 0, 0));
        fury.setColors(0, fill(12, 0, 0, 0));
        fury.setColors(1, fill(12, 0, 0, 0));
      }
      final effect = Alv2Effect(
        Alv2LightMode.breathing,
        colors: [
          for (var i = 0; i < 6; i++) ...[255, 0, 0],
        ],
        speedLevel: speed,
      );
      ok(
        'leave merge (all ports off)',
        await hub.sendLighting(alv2OffWrites()),
      );
      ok(
        'fans Breathing speed $speed',
        await hub.sendLighting(
          alv2ServiceOrder([
            for (final g in [1, 2, 3]) ...alv2WholeWrites(g, effect),
          ]),
        ),
      );
      final sw = Stopwatch()..start();
      if (count) {
        stdout.writeln('count the bright peaks for $seconds s...');
        await Future<void>.delayed(Duration(seconds: seconds));
      } else {
        var nextTraffic = 1000;
        while (sw.elapsed.inSeconds < seconds) {
          if (appTraffic && sw.elapsedMilliseconds >= nextTraffic) {
            nextTraffic += 1000;
            for (final g in [1, 2, 3]) {
              hub.setDuty(g, 60);
            }
            hub.readRpm();
          }
          final t = (sw.elapsedMicroseconds / 1000 - offsetMs) / periodMs;
          final c = (127.5 - 127.5 * math.cos(2 * math.pi * t)).round();
          ite.streamCase(fill(47, c, 0, 0));
          fury.setColors(0, fill(12, c, 0, 0));
          fury.setColors(1, fill(12, c, 0, 0));
          await Future<void>.delayed(const Duration(milliseconds: 15));
        }
      }
      stdout.writeln('done after ${sw.elapsed.inSeconds} s');
      hub.dispose();
      ite.dispose();
      fury.close();
    case 'breathduty':
      // breathduty <speed 0-4> <none|duty|rpm> [seconds] — groups 1–3 in
      // firmware Breathing (red) while the app's 1 s control traffic runs:
      // `duty` = duty 60 % on groups 1–3 every second (fans module), `rpm` =
      // one RPM read every second (monitoring). Tells whether that traffic
      // restarts the firmware animation (fans blinking about once a second).
      final speed = int.parse(args[1]);
      final traffic = args[2];
      final seconds = int.parse(args.elementAtOrNull(3) ?? '30');
      final hub = Alv2Hub.open();
      final effect = Alv2Effect(
        Alv2LightMode.breathing,
        colors: [
          for (var i = 0; i < 6; i++) ...[255, 0, 0],
        ],
        speedLevel: speed,
      );
      ok(
        'leave merge (all ports off)',
        await hub.sendLighting(alv2OffWrites()),
      );
      ok(
        'fans Breathing speed $speed',
        await hub.sendLighting(
          alv2ServiceOrder([
            for (final g in [1, 2, 3]) ...alv2WholeWrites(g, effect),
          ]),
        ),
      );
      stdout.writeln('$traffic every 1 s for $seconds s...');
      for (var t = 0; t < seconds; t++) {
        await Future<void>.delayed(const Duration(seconds: 1));
        switch (traffic) {
          case 'duty':
            for (final g in [1, 2, 3]) {
              hub.setDuty(g, 60);
            }
          case 'rpm':
            hub.readRpm();
        }
      }
      hub.dispose();
    case 'hwall':
      // hwall <mode name> [speed 0-4] [r,g,b ...] [dir<g>=<0|1> ...] —
      // the same firmware mode on groups 1–3 (previews candidates for
      // Scanner / Color wave). `dir3=1` sends direction 1 to group 3 only, to
      // see whether a mode without direction in the UI honors the byte.
      final mode = Alv2LightMode.byName(args[1])!;
      final dirs = <int, int>{
        for (final a in args.skip(3).where((a) => a.startsWith('dir')))
          int.parse(a.substring(3, a.indexOf('='))): int.parse(
            a.substring(a.indexOf('=') + 1),
          ),
      };
      final colors = [
        for (final c in args.skip(3).where((a) => !a.startsWith('dir')))
          ...c.split(',').map(int.parse),
      ];
      Alv2Effect effectFor(int group) => Alv2Effect(
        mode,
        colors: colors.isEmpty ? mode.meta.defaultColors : colors,
        speedLevel: args.length > 2 ? int.parse(args[2]) : 3,
        direction: dirs[group] ?? 0,
      );
      final hub = Alv2Hub.open();
      ok(
        'leave merge (all ports off)',
        await hub.sendLighting(alv2OffWrites()),
      );
      ok(
        'groups 1–3 ${mode.firmwareName}${dirs.isEmpty ? '' : ' $dirs'}',
        await hub.sendLighting(
          alv2ServiceOrder([
            for (final g in [1, 2, 3]) ...alv2WholeWrites(g, effectFor(g)),
          ]),
        ),
      );
      hub.dispose();
    case 'streamthen':
      // streamthen <mode name> <plain|idle|off> [<n>s] [r,g,b ...] — the
      // app's path from canvas back to a firmware mode: n s (default 3) of white
      // canvas frames at
      // 2 fps on groups 1–3, then the mode, resent 1 s later. `plain` sends
      // only the mode (what the app does); `idle` first parks the outer port
      // 2g+1 (Rainbow, brightness 08); `off` parks both ports, as `hwall`.
      final mode = Alv2LightMode.byName(args[1])!;
      final variant = args.length > 2 ? args[2] : 'plain';
      final secs =
          [
            for (final a in args.skip(3))
              if (a.endsWith('s')) int.parse(a.substring(0, a.length - 1)),
          ].firstOrNull ??
          3;
      final colors = [
        for (final c in args.skip(3).where((a) => !a.endsWith('s')))
          ...c.split(',').map(int.parse),
      ];
      final effect = Alv2Effect(
        mode,
        colors: colors.isEmpty ? mode.meta.defaultColors : colors,
        speedLevel: 3,
      );
      // Fans per group as in the app config (0, 3, 3, 1): frames sized for
      // the real quantity, like the engine sends them.
      const fans = [0, 3, 3, 1];
      final hub = Alv2Hub.open();
      // Same init as the engine (initFans).
      ok('ARGB sync off', hub.disableArgbSync());
      ok('merge order 0,1,2,3', hub.setMergeOrder(const [0, 1, 2, 3]));
      for (var g = 0; g < 4; g++) {
        ok('quantity group $g = ${fans[g]}', hub.setQuantity(g, fans[g]));
      }
      var sentFrames = 0;
      for (var i = 0; i < secs * 2; i++) {
        if (await hub.streamCanvas(
          alv2ServiceOrder([
            for (final g in [1, 2, 3])
              ...alv2CanvasWrites(
                g,
                fans[g],
                fill(fans[g] * 20, 255, 255, 255),
              ),
          ]),
        )) {
          sentFrames++;
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      ok(
        '$secs s of white canvas frames ($sentFrames/${secs * 2} sent)',
        sentFrames == secs * 2,
      );
      Alv2PortWrite park(int port) => Alv2PortWrite(
        port: port,
        mode: Alv2LightMode.rainbow.byte,
        brightness: 0x08,
      );
      for (final pass in ['send', 'resend']) {
        ok(
          '$pass ${mode.firmwareName} ($variant)',
          await hub.sendLighting(
            alv2ServiceOrder([
              for (final g in [1, 2, 3]) ...[
                if (variant != 'plain') park(2 * g + 1),
                if (variant == 'off') park(2 * g),
                ...alv2WholeWrites(g, effect),
              ],
            ]),
          ),
        );
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      hub.dispose();
    case 'off':
      final hub = Alv2Hub.open();
      ok('fans off', await hub.sendLighting(alv2OffWrites()));
      hub.dispose();
      final ite = IteController.open();
      ok('board + case off', ite.allOff());
      ite.dispose();
      final fury = FuryController();
      ok('RAM 1 off', fury.setSingleColor(0, 0, 0, 0));
      ok('RAM 2 off', fury.setSingleColor(1, 0, 0, 0));
      fury.close();
    case 'restore':
      // "Religar ARGB": after `off`, everything comes back to a known pattern
      // (fans green, case purple, board zones white, RAM white). Confirms the
      // off state did not need a re-plug and that direct mode is re-entered.
      final hub = Alv2Hub.open();
      ok('ARGB sync off', hub.disableArgbSync());
      for (final g in [1, 2, 3]) {
        ok('quantity group $g = 3', hub.setQuantity(g, 3));
      }
      final writes = [
        for (final g in [1, 2, 3])
          ...alv2CanvasWrites(g, 3, fill(60, 0, 255, 0)),
      ];
      ok(
        'fans restored (green)',
        await hub.sendLighting(alv2ServiceOrder(writes)),
      );
      hub.dispose();
      final ite = IteController.open();
      ok('case restored (purple)', ite.streamCase(fill(47, 120, 0, 255)));
      ok(
        'board restored (white)',
        ite.setZoneColors({
          0x20: (255, 255, 255),
          0x22: (255, 255, 255),
          0x23: (255, 255, 255),
        }),
      );
      ite.dispose();
      final fury = FuryController();
      ok('RAM 1 restored (white)', fury.setColors(0, fill(12, 255, 255, 255)));
      ok('RAM 2 restored (white)', fury.setColors(1, fill(12, 255, 255, 255)));
      fury.close();
    default:
      stderr.writeln(
        'usage: dart run tool/hw_test_fase4.dart '
        '<case|board|zones|zonesonly|fans|fan0|fanorder|merge|ram|ramorder|hwfans|hwboard|hwzone|off|restore>',
      );
      exitCode = 64;
  }
}
