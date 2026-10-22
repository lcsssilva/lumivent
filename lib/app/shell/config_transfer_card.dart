import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_strings_scope.dart';
import '../../core/persistence/config_store.dart';
import '../../core/ui/async_action.dart';
import '../../core/ui/we_card.dart';
import '../../core/ui/setting_row.dart';
import '../config_transfer.dart';

/// Export/import of the whole configuration. An import applies at once: the
/// modules reload their section and resend it to the engine.
class ConfigTransferCard extends ConsumerStatefulWidget {
  const ConfigTransferCard({super.key});

  @override
  ConsumerState<ConfigTransferCard> createState() => _ConfigTransferCardState();
}

class _ConfigTransferCardState extends ConsumerState<ConfigTransferCard>
    with AsyncActionMixin<ConfigTransferCard> {
  void _tell(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(Future<void> Function() job) => run(() async {
    final strings = context.strings;
    try {
      await job();
    } on ConfigWriteFailure {
      // The shell notifies every configuration write failure; this card would
      // only show the same problem a second time.
    } on Object catch (e) {
      _tell(e is FormatException ? e.message : strings.shell.failed('$e'));
    }
  });

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
    final text = await readImportText(
      file.readAsByteStream(),
      strings: strings,
    );
    final transfer = ref.read(configTransferProvider);
    await transfer.importText(text, strings: strings);
    _tell(s.importedBackupAt(transfer.backupPath));
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
              onPressed: isRunning ? null : _export,
              child: Text(s.export),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: isRunning ? null : _import,
              child: Text(s.import),
            ),
          ],
        ),
      ),
    );
  }
}
