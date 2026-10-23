part of 'config_transfer_card.dart';

class _ConfigTransferCardState extends State<ConfigTransferCard>
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
    final text = widget.exportConfiguration();
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
    final backup = await widget.importConfiguration(
      file.readAsByteStream(),
      strings: strings,
    );
    _tell(s.importedBackupAt(backup));
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
