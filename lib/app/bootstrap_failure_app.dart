import 'dart:io';

import 'package:flutter/material.dart';

class BootstrapFailureApp extends StatefulWidget {
  const BootstrapFailureApp({
    required this.error,
    required this.configDir,
    super.key,
  });

  final Object error;
  final Directory configDir;

  @override
  State<BootstrapFailureApp> createState() => _BootstrapFailureAppState();
}

class _BootstrapFailureAppState extends State<BootstrapFailureApp> {
  String? _openError;

  Future<void> _openConfigFolder() async {
    try {
      await Process.start('xdg-open', [
        widget.configDir.path,
      ], mode: ProcessStartMode.detached);
      setState(() => _openError = null);
    } on Object catch (error) {
      setState(() => _openError = '$error');
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lumivent could not start',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                const Text(
                  'The error was written to the terminal. Check the '
                  'configuration or open its folder to fix the problem.',
                ),
                const SizedBox(height: 12),
                SelectableText('${widget.error}'),
                const SizedBox(height: 16),
                Text('Configuration: ${widget.configDir.path}'),
                if (_openError case final error?) ...[
                  const SizedBox(height: 8),
                  SelectableText('Could not open the folder: $error'),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _openConfigFolder,
                  child: const Text('Open configuration folder'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
