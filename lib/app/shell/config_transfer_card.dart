import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_strings_scope.dart';
import '../../core/persistence/config_store.dart';
import '../../core/ui/widgets.dart';
import '../../features/fans/fans.dart';
import '../../features/lighting/lighting.dart';
import '../../features/preferences/preferences.dart';
import '../config_transfer.dart';

/// Export/import of the whole configuration. An import applies at once: the
/// modules reload their section and resend it to the engine.
class ConfigTransferCard extends ConsumerStatefulWidget {
  const ConfigTransferCard({super.key});

  @override
  ConsumerState<ConfigTransferCard> createState() => _ConfigTransferCardState();
}

class _ConfigTransferCardState extends ConsumerState<ConfigTransferCard> {
  bool _busy = false;

  void _tell(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(Future<void> Function() job) async {
    final strings = context.strings;
    setState(() => _busy = true);
    try {
      await job();
    } on ConfigWriteFailure {
      // The shell already notifies every configuration write failure; this
      // card would only show the same problem a second time.
    } on Object catch (e) {
      _tell(e is FormatException ? e.message : strings.shell.failed('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() => _run(() async {
    final s = context.strings.shell;
    final text = exportConfig(ref.read(configStoreProvider));
    final saved = await FilePicker.saveFile(
      dialogTitle: s.exportDialogTitle,
      fileName: exportFileName,
      bytes: utf8.encode(text),
      mimeType: 'application/json',
    );
    if (saved != null) _tell(s.exportedTo(saved.path));
  });

  Future<void> _import() => _run(() async {
    final strings = context.strings;
    final s = strings.shell;
    final file = await FilePicker.pickFile(
      dialogTitle: s.importDialogTitle,
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return;
    final text = utf8.decode(await file.readAsBytes());
    final store = ref.read(configStoreProvider);
    final sections = await importConfig(store, text, strings: strings);
    if (sections.contains('preferences')) {
      ref.read(preferencesProvider.notifier).reload();
    }
    if (sections.contains('lighting')) {
      ref.read(lightingProvider.notifier).reload();
    }
    if (sections.contains('fans')) ref.read(fansProvider.notifier).reload();
    _tell(s.importedBackupAt('${store.file.path}.$importBackupSuffix'));
  });

  @override
  Widget build(BuildContext context) {
    final s = context.strings.shell;
    return WeCard(
      title: s.configuration,
      child: SettingRow(
        title: s.exportOrImport,
        subtitle: Text(s.exportOrImportDescription),
        control: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: _busy ? null : _export,
              child: Text(s.export),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _busy ? null : _import,
              child: Text(s.import),
            ),
          ],
        ),
      ),
    );
  }
}
