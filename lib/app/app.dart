import 'package:flutter/material.dart';

import '../core/ui/theme.dart';
import 'shell/shell.dart';

class WeApp extends StatelessWidget {
  const WeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Lumivent',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    home: const Shell(),
  );
}
