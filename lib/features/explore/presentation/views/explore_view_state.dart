part of 'explore_view.dart';

class _ExploreViewState extends ConsumerState<ExploreView>
    with AsyncActionMixin<ExploreView> {
  final _query = TextEditingController();

  ExploreViewModel get _viewModel =>
      ref.read(exploreViewModelProvider.notifier);

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _tell(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? WeColors.danger : null,
          duration: Duration(seconds: error ? 6 : 4),
        ),
      );
  }

  Future<void> _run(Future<ImportReport> Function() action) => run(() async {
    final strings = context.strings;
    try {
      final report = await action();
      final issues = report.issues;
      final summary = strings.explore.importSummary(
        imported: report.imported,
        replaced: report.replaced,
        skipped: report.skipped,
        paidSkipped: report.paidSkipped,
        errors: issues.length,
      );
      _tell(
        issues.isEmpty
            ? strings.explore.importDone(summary)
            : strings.explore.importDoneWithError(
                summary,
                formatImportIssue(strings.explore, issues.first),
              ),
        error: issues.isNotEmpty,
      );
    } on Object catch (error) {
      _tell(strings.explore.importFailed('$error'), error: true);
    }
  });

  Future<void> _importFiles() async {
    final explore = context.strings.explore;
    final files = await FilePicker.pickFiles(
      dialogTitle: explore.importEffectsDialogTitle,
      type: FileType.custom,
      allowedExtensions: ['html', 'htm', 'zip'],
    );
    if (files.isEmpty) return;
    final paths = [
      for (final file in files)
        if (file.path != null) file.path!,
    ];
    if (paths.isEmpty) return;
    await _run(() => _viewModel.importPaths(paths));
  }

  Future<void> _importFolder() async {
    final dir = await FilePicker.getDirectoryPath(
      dialogTitle: context.strings.explore.importFolderDialogTitle,
    );
    if (dir == null || dir.isEmpty) return;
    await _run(() => _viewModel.importPaths([dir]));
  }

  Future<void> _importWindowsCache() async {
    final dir = await FilePicker.getDirectoryPath(
      dialogTitle: context.strings.explore.importWindowsDialogTitle,
    );
    if (dir == null || dir.isEmpty) return;
    await _run(() => _viewModel.importWindowsCache(dir));
  }

  void _apply(InstalledEffect effect) {
    _viewModel.applyEffect(effect);
    _tell(context.strings.explore.effectApplied(effect.title));
  }

  Future<void> _remove(InstalledEffect effect) async {
    final strings = context.strings;
    final applied = ref.read(exploreViewModelProvider).isApplied(effect);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.explore.removeTitle(effect.title)),
        content: Text(
          applied
              ? strings.explore.removeAppliedBody
              : strings.explore.removeBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(strings.common.remove),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _viewModel.removeEffect(effect);
      _tell(strings.explore.effectRemoved(effect.title));
    } on Object catch (error) {
      _tell(strings.explore.removeFailed('$error'), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final ui = ref.watch(exploreViewModelProvider);

    return Padding(
      padding: const EdgeInsets.all(WeSizes.unit * 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.shell.explore,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            strings.explore.subtitle,
            style: const TextStyle(color: WeColors.muted, fontSize: 12.5),
          ),
          const SizedBox(height: WeSizes.unit * 2),
          _buildToolbar(strings.explore),
          const SizedBox(height: WeSizes.unit * 2),
          _buildFilters(ui),
          const SizedBox(height: WeSizes.unit * 2),
          Expanded(child: _buildContent(ui)),
        ],
      ),
    );
  }

  Widget _buildToolbar(ExploreStrings explore) {
    return Row(
      children: [
        if (isRunning)
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const Key('import-files'),
                onPressed: isRunning ? null : _importFiles,
                icon: const Icon(Icons.insert_drive_file_outlined, size: 18),
                label: Text(explore.importEffect),
              ),
              OutlinedButton.icon(
                key: const Key('import-folder'),
                onPressed: isRunning ? null : _importFolder,
                icon: const Icon(Icons.folder_open_outlined, size: 18),
                label: Text(explore.folder),
              ),
              FilledButton.tonalIcon(
                key: const Key('import-windows-cache'),
                onPressed: isRunning ? null : _importWindowsCache,
                icon: const Icon(Icons.desktop_windows_outlined, size: 18),
                label: Text(explore.importFromWindows),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(ExploreUiState ui) {
    return ExploreFilters(
      controller: _query,
      support: ui.filter.support,
      tag: ui.filter.tag,
      publisher: ui.filter.publisher,
      tags: ui.tags,
      publishers: ui.publishers,
      onQuery: () => _viewModel.setQuery(_query.text),
      onSupport: _viewModel.setSupport,
      onTag: _viewModel.setTag,
      onPublisher: _viewModel.setPublisher,
    );
  }

  Widget _buildContent(ExploreUiState ui) {
    final explore = context.strings.explore;
    return ui.installed.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildLibraryError(explore, error),
      data: (_) => _buildGrid(ui, explore),
    );
  }

  Widget _buildLibraryError(ExploreStrings explore, Object error) {
    return Center(
      child: WeCard(
        title: explore.libraryReadFailed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${context.strings.common.technicalDetails}: $error',
              style: const TextStyle(color: WeColors.muted),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _viewModel.retryLibrary,
              child: Text(context.strings.common.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(ExploreUiState ui, ExploreStrings explore) {
    if (ui.allEffects.isEmpty) return const ExploreEmptyState();
    final visibleEffects = ui.visibleEffects;
    if (visibleEffects.isEmpty) {
      return Center(
        child: Text(
          explore.noMatch,
          style: const TextStyle(color: WeColors.muted),
        ),
      );
    }
    return GridView.builder(
      key: const Key('explore-grid'),
      padding: const EdgeInsets.only(bottom: 8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 268,
        mainAxisExtent: 312,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: visibleEffects.length,
      itemBuilder: (context, index) {
        final effect = visibleEffects[index];
        return EffectCard(
          key: ValueKey('effect-card-${effect.id}'),
          effect: effect,
          applied: ui.isApplied(effect),
          thumbnail: effect.hasThumbnail ? _viewModel.thumbnail(effect) : null,
          onApply: effect.canRun ? () => _apply(effect) : null,
          onRemove: () => _remove(effect),
        );
      },
    );
  }
}
