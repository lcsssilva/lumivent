// Explore: installed HTML/Canvas effects (plan §5.6). Grid with thumbnails,
// search and filters, local import (HTML, folder, ZIP) and the read-only import
// from an effects cache on a mounted Windows partition.

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings_scope.dart';
import '../../../core/i18n/catalogs/explore_strings.dart';
import '../../../core/ui/async_action.dart';
import '../../../core/ui/theme.dart';
import '../../../core/ui/we_card.dart';
import '../../lighting/lighting.dart';
import '../application/effect_filter.dart';
import 'effect_card.dart';
import 'explore_empty_state.dart';
import 'explore_filters.dart';

String formatImportIssue(ExploreStrings e, ImportIssue issue) {
  final path = issue.path ?? '';
  final error = issue.detail ?? '';
  return switch (issue.kind) {
    ImportIssueKind.notHtmlOrZip => e.importNotHtmlOrZip(path),
    ImportIssueKind.notFound => e.importNotFound(path),
    ImportIssueKind.folderNotFound => e.importFolderNotFound(path),
    ImportIssueKind.chooseWindowsCache => e.importChooseWindowsCache,
    ImportIssueKind.catalogMissing => e.importCatalogMissing,
    ImportIssueKind.noEffectHtml => e.importNoEffectHtml(path),
    ImportIssueKind.invalidZip => e.importInvalidZip(path, error),
    ImportIssueKind.noHtmlInZip => e.importNoHtmlInZip,
    ImportIssueKind.tooLarge => e.importTooLarge(path),
    ImportIssueKind.unsupportedZipEntry => e.importUnsupportedZipEntry(path),
    ImportIssueKind.unknown => e.importUnknown(path, error),
  };
}

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage>
    with AsyncActionMixin<ExplorePage> {
  final _query = TextEditingController();
  final _thumbs = <String, Future<Uint8List?>>{};
  SupportFilter _support = SupportFilter.all;
  String? _tag;
  String? _publisher;

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
      _thumbs.clear();
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
    await _run(
      () => ref.read(installedEffectsProvider.notifier).importPaths(paths),
    );
  }

  Future<void> _importFolder() async {
    final dir = await FilePicker.getDirectoryPath(
      dialogTitle: context.strings.explore.importFolderDialogTitle,
    );
    if (dir == null || dir.isEmpty) return;
    await _run(
      () => ref.read(installedEffectsProvider.notifier).importPaths([dir]),
    );
  }

  Future<void> _importWindowsCache() async {
    final dir = await FilePicker.getDirectoryPath(
      dialogTitle: context.strings.explore.importWindowsDialogTitle,
    );
    if (dir == null || dir.isEmpty) return;
    await _run(
      () => ref.read(installedEffectsProvider.notifier).importWindowsCache(dir),
    );
  }

  void _apply(InstalledEffect effect) {
    ref
        .read(lightingProvider.notifier)
        .update((current) => current.copyWith(effectId: effect.effectId));
    _tell(context.strings.explore.effectApplied(effect.title));
  }

  Future<void> _remove(InstalledEffect effect) async {
    final strings = context.strings;
    final applied = ref.read(lightingProvider).effectId == effect.effectId;
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
    if (applied) {
      ref
          .read(lightingProvider.notifier)
          .update((current) => current.copyWith(effectId: defaultEffectId));
    }
    try {
      await ref.read(installedEffectsProvider.notifier).remove(effect.id);
      _thumbs.remove(effect.id);
      _tell(strings.explore.effectRemoved(effect.title));
    } on Object catch (error) {
      _tell(strings.explore.removeFailed('$error'), error: true);
    }
  }

  Future<Uint8List?> _thumbnail(InstalledEffect effect) => _thumbs.putIfAbsent(
    effect.id,
    () => ref.read(installedEffectsProvider.notifier).thumbnail(effect.id),
  );

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final explore = strings.explore;
    final installed = ref.watch(installedEffectsProvider);
    final lightingConfig = ref.watch(lightingProvider);
    final allEffects = installed.value ?? const <InstalledEffect>[];
    final effectFilter = EffectFilter(
      query: _query.text,
      support: _support,
      tag: _tag,
      publisher: _publisher,
    );
    final visibleEffects = filterEffects(allEffects, effectFilter);

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
            explore.subtitle,
            style: const TextStyle(color: WeColors.muted, fontSize: 12.5),
          ),
          const SizedBox(height: WeSizes.unit * 2),
          Expanded(
            child: _installedTab(
              installed,
              allEffects,
              visibleEffects,
              lightingConfig,
            ),
          ),
        ],
      ),
    );
  }

  Widget _installedTab(
    AsyncValue<List<InstalledEffect>> installed,
    List<InstalledEffect> allEffects,
    List<InstalledEffect> visibleEffects,
    LightingConfig lightingConfig,
  ) {
    final strings = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(strings.explore),
        const SizedBox(height: WeSizes.unit * 2),
        _buildFilters(
          availableTags(allEffects),
          availablePublishers(allEffects),
        ),
        const SizedBox(height: WeSizes.unit * 2),
        Expanded(
          child: _buildContent(
            installed,
            allEffects,
            visibleEffects,
            lightingConfig,
          ),
        ),
      ],
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

  Widget _buildFilters(List<String> tags, List<String> publishers) {
    return ExploreFilters(
      controller: _query,
      support: _support,
      tag: _tag,
      publisher: _publisher,
      tags: tags,
      publishers: publishers,
      onQuery: () => setState(() {}),
      onSupport: (value) => setState(() => _support = value),
      onTag: (value) => setState(() => _tag = value),
      onPublisher: (value) => setState(() => _publisher = value),
    );
  }

  Widget _buildContent(
    AsyncValue<List<InstalledEffect>> installed,
    List<InstalledEffect> allEffects,
    List<InstalledEffect> visibleEffects,
    LightingConfig lightingConfig,
  ) {
    final explore = context.strings.explore;
    return installed.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildLibraryError(explore, error),
      data: (_) =>
          _buildGrid(allEffects, visibleEffects, lightingConfig, explore),
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
              onPressed: () => ref.invalidate(installedEffectsProvider),
              child: Text(context.strings.common.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(
    List<InstalledEffect> allEffects,
    List<InstalledEffect> visibleEffects,
    LightingConfig lightingConfig,
    ExploreStrings explore,
  ) {
    if (allEffects.isEmpty) return const ExploreEmptyState();
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
          applied: lightingConfig.effectId == effect.effectId,
          thumbnail: effect.hasThumbnail ? _thumbnail(effect) : null,
          onApply: effect.canRun ? () => _apply(effect) : null,
          onRemove: () => _remove(effect),
        );
      },
    );
  }
}
