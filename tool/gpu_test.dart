// Phase 7 hardware checklist for the GPU RGB (Gigabyte RX 9060 XT), one step
// per run, through the app's own `GpuController` (bus found by name, SSID
// 0x2429 read before any 0x12, save/sync commands blocked, 120 ms pause).
//
//   dart run tool/gpu_test.dart <step>
//
// Steps:
//   id                               firmware and SSID only (no 0x12)
//   static <r,g,b> [bright]          Static color (bright 0–10, default 10)
//   effect <name> [speed] [bright] [r,g,b]
//                                    any firmware effect by name (staticColor,
//                                    pulse, flash, doubleFlash, cycle, wave,
//                                    gradient, colorShift, rainbow, tricolor,
//                                    claws, dazzle); speed/bright 0–10
//   off                              effect 0x00 (what "Desligar ARGB" sends)
//
// Run with the app and any other RGB software closed. Nothing is saved to the
// controller (0x13 is blocked): a power cycle restores the factory effect.
import 'dart:io';

import 'package:lumivent/features/devices/infrastructure/drivers/gpu_gigabyte/controller.dart';
import 'package:lumivent/features/devices/infrastructure/drivers/gpu_gigabyte/protocol.dart';

GpuRgb rgb(String s) {
  final v = s.split(',').map(int.parse).toList();
  return GpuRgb(v[0], v[1], v[2]);
}

const _palette = [
  GpuRgb(255, 0, 0),
  GpuRgb(255, 128, 0),
  GpuRgb(255, 255, 0),
  GpuRgb(0, 255, 0),
  GpuRgb(0, 255, 255),
  GpuRgb(0, 0, 255),
  GpuRgb(160, 0, 255),
  GpuRgb(255, 255, 255),
];

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('uso: dart run tool/gpu_test.dart <id|static|effect|off> …');
    exit(64);
  }
  final GpuController gpu;
  try {
    gpu = GpuController.open();
  } on GpuException catch (e) {
    stderr.writeln('FAIL abrir: $e');
    exit(1);
  }
  try {
    stdout.writeln('barramento: ${gpu.busPath}');
    if (!gpu.init()) {
      stderr.writeln('FAIL identificação: ${gpu.disabledReason}');
      exit(1);
    }
    stdout.writeln(
      'OK   fw ${gpu.firmware} · SSID 0x'
      '${gpu.ssid!.toRadixString(16).toUpperCase()}',
    );

    bool send(GpuEffectCode effect, int speed, int bright, GpuRgb color) {
      final ok = gpu.sendEffect(
        effect: effect,
        speed: speed,
        brightness: bright,
        color: color,
        colors: _palette,
      );
      stdout.writeln(
        ok
            ? 'OK   ${effect.styleName} (0x${effect.code.toRadixString(16)}) '
                  'speed $speed bright $bright cor ${color.r},${color.g},${color.b}'
            : 'FAIL ${effect.styleName}: ${gpu.disabledReason}',
      );
      return ok;
    }

    final ok = switch (args[0]) {
      'id' => true,
      'static' => send(
        GpuEffectCode.staticColor,
        0,
        args.length > 2 ? int.parse(args[2]) : 10,
        rgb(args.length > 1 ? args[1] : '255,0,0'),
      ),
      'effect' => () {
        final effect = GpuEffectCode.byName(args.length > 1 ? args[1] : '');
        if (effect == null) {
          stderr.writeln('efeito desconhecido; use um nome de GpuEffectCode');
          return false;
        }
        return send(
          effect,
          args.length > 2 ? int.parse(args[2]) : 5,
          args.length > 3 ? int.parse(args[3]) : 10,
          rgb(args.length > 4 ? args[4] : '255,0,0'),
        );
      }(),
      'off' => () {
        final ok = gpu.turnOff();
        stdout.writeln(ok ? 'OK   Off' : 'FAIL Off: ${gpu.disabledReason}');
        return ok;
      }(),
      _ => () {
        stderr.writeln('passo desconhecido: ${args[0]}');
        return false;
      }(),
    };
    if (!ok) exit(1);
  } finally {
    gpu.close();
  }
}
