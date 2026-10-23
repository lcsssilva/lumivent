import 'dart:io';

import 'package:flutter/material.dart';

import '../main_spike.dart';

class SpikeApp extends StatelessWidget {
  const SpikeApp({
    super.key,
    required this.files,
    required this.auto,
    this.only,
    this.dump,
  });
  final List<File> files;
  final bool auto;
  final String? only, dump;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData.dark(),
    home: SpikePage(files: files, auto: auto, only: only, dump: dump),
  );
}
