// Spikes da fase 0 (b) e (c):
//  (b) efeito HTML no QuickJS + shim Canvas2D desenhado em dart:ui;
//  (c) o render offscreen continua com a janela oculta.
//
//   flutter build linux --release -t lib/main_spike.dart
//   build/linux/x64/release/bundle/lumivent --effects=spike_effects [--auto] [--dump=dir]
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'features/lighting/infrastructure/html_effects/isolated_html_effect_runtime.dart';
import 'spike/spike_app.dart';

part 'spike/spike_stats.dart';
part 'spike/spike_page.dart';
part 'spike/spike_page_state.dart';

const _fps = 30;

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  String? opt(String name) => args
      .where((a) => a.startsWith('--$name='))
      .map((a) => a.split('=').last)
      .firstOrNull;
  final dir = Directory(opt('effects') ?? 'spike_effects');
  final files =
      dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.html'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  runApp(
    SpikeApp(
      files: files,
      auto: args.contains('--auto'),
      only: opt('effect'),
      dump: opt('dump'),
    ),
  );
}

/// CPU time of the current process (utime + stime), in 10 ms ticks.
int _cpuTicks() {
  final f = File('/proc/self/stat').readAsStringSync();
  final rest = f.substring(f.lastIndexOf(')') + 2).split(' ');
  return int.parse(rest[11]) + int.parse(rest[12]);
}
