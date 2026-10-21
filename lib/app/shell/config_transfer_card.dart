import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    setState(() => _busy = true);
    try {
      await job();
    } on Object catch (e) {
      _tell(e is FormatException ? e.message : 'Falhou: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() => _run(() async {
    final text = exportConfig(ref.read(configStoreProvider));
    final saved = await FilePicker.saveFile(
      dialogTitle: 'Exportar configuração',
      fileName: exportFileName,
      bytes: utf8.encode(text),
      mimeType: 'application/json',
    );
    if (saved != null) _tell('Configuração exportada para ${saved.path}.');
  });

  Future<void> _import() => _run(() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Importar configuração',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return;
    final text = utf8.decode(await file.readAsBytes());
    final store = ref.read(configStoreProvider);
    final sections = await importConfig(store, text);
    if (sections.contains('preferences')) {
      ref.read(preferencesProvider.notifier).reload();
    }
    if (sections.contains('lighting')) {
      ref.read(lightingProvider.notifier).reload();
    }
    if (sections.contains('fans')) ref.read(fansProvider.notifier).reload();
    _tell(
      'Configuração importada e aplicada. A anterior ficou em '
      '${store.file.path}.$importBackupSuffix.',
    );
  });

  @override
  Widget build(BuildContext context) => WeCard(
    title: 'Configuração',
    child: SettingRow(
      title: 'Exportar ou importar',
      subtitle: const Text(
        'Preferências, iluminação e fans num arquivo JSON. Importar aplica na '
        'hora e guarda uma cópia da configuração atual.',
      ),
      control: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            onPressed: _busy ? null : _export,
            child: const Text('Exportar…'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _busy ? null : _import,
            child: const Text('Importar…'),
          ),
        ],
      ),
    ),
  );
}
