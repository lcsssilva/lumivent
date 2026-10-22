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
import '../../../core/ui/widgets.dart';
import '../../lighting/lighting.dart';
import '../application/effect_filter.dart';

String _formatIssue(ExploreStrings e, ImportIssue issue) =>
    e.importIssue(issue.kind.name, issue.path ?? '', error: issue.detail);

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
                _formatIssue(strings.explore, issues.first),
              ),
        error: issues.isNotEmpty,
      );
    } on Object catch (e) {
      _tell(strings.explore.importFailed('$e'), error: true);
    }
  });

  Future<void> _importFiles() async {
    final strings = context.strings.explore;
    final files = await FilePicker.pickFiles(
      dialogTitle: strings.importEffectsDialogTitle,
      type: FileType.custom,
      allowedExtensions: ['html', 'htm', 'zip'],
    );
    if (files.isEmpty) return;
    final paths = [
      for (final f in files)
        if (f.path != null) f.path!,
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
        .update((c) => c.copyWith(effectId: effect.effectId));
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
          .update((c) => c.copyWith(effectId: defaultEffectId));
    }
    try {
      await ref.read(installedEffectsProvider.notifier).remove(effect.id);
      _thumbs.remove(effect.id);
      _tell(strings.explore.effectRemoved(effect.title));
    } on Object catch (e) {
      _tell(strings.explore.removeFailed('$e'), error: true);
    }
  }

  Future<Uint8List?> _thumbnail(InstalledEffect effect) => _thumbs.putIfAbsent(
    effect.id,
    () => ref.read(installedEffectsProvider.notifier).thumbnail(effect.id),
  );

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final e = strings.explore;
    final installed = ref.watch(installedEffectsProvider);
    final cfg = ref.watch(lightingProvider);
    final all = installed.value ?? const <InstalledEffect>[];
    final filter = EffectFilter(
      query: _query.text,
      support: _support,
      tag: _tag,
      publisher: _publisher,
    );
    final visible = filterEffects(all, filter);

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
            e.subtitle,
            style: const TextStyle(color: WeColors.muted, fontSize: 12.5),
          ),
          const SizedBox(height: WeSizes.unit * 2),
          Expanded(child: _installedTab(installed, all, visible, cfg)),
        ],
      ),
    );
  }

  Widget _installedTab(
    AsyncValue<List<InstalledEffect>> installed,
    List<InstalledEffect> all,
    List<InstalledEffect> visible,
    LightingConfig cfg,
  ) {
    final strings = context.strings;
    final e = strings.explore;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
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
                    icon: const Icon(
                      Icons.insert_drive_file_outlined,
                      size: 18,
                    ),
                    label: Text(e.importEffect),
                  ),
                  OutlinedButton.icon(
                    key: const Key('import-folder'),
                    onPressed: isRunning ? null : _importFolder,
                    icon: const Icon(Icons.folder_open_outlined, size: 18),
                    label: Text(e.folder),
                  ),
                  FilledButton.tonalIcon(
                    key: const Key('import-windows-cache'),
                    onPressed: isRunning ? null : _importWindowsCache,
                    icon: const Icon(Icons.desktop_windows_outlined, size: 18),
                    label: Text(e.importFromWindows),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: WeSizes.unit * 2),
        _Filters(
          controller: _query,
          support: _support,
          tag: _tag,
          publisher: _publisher,
          tags: availableTags(all),
          publishers: availablePublishers(all),
          onQuery: () => setState(() {}),
          onSupport: (v) => setState(() => _support = v),
          onTag: (v) => setState(() => _tag = v),
          onPublisher: (v) => setState(() => _publisher = v),
        ),
        const SizedBox(height: WeSizes.unit * 2),
        Expanded(
          child: installed.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: WeCard(
                title: e.libraryReadFailed,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${strings.common.technicalDetails}: $err',
                      style: const TextStyle(color: WeColors.muted),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(installedEffectsProvider),
                      child: Text(strings.common.retry),
                    ),
                  ],
                ),
              ),
            ),
            data: (_) {
              if (all.isEmpty) return const _EmptyState();
              if (visible.isEmpty) {
                return Center(
                  child: Text(
                    e.noMatch,
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
                itemCount: visible.length,
                itemBuilder: (context, i) {
                  final effect = visible[i];
                  return _EffectCard(
                    key: ValueKey('effect-card-${effect.id}'),
                    effect: effect,
                    applied: cfg.effectId == effect.effectId,
                    thumbnail: effect.hasThumbnail ? _thumbnail(effect) : null,
                    onApply: effect.canRun ? () => _apply(effect) : null,
                    onRemove: () => _remove(effect),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.controller,
    required this.support,
    required this.tag,
    required this.publisher,
    required this.tags,
    required this.publishers,
    required this.onQuery,
    required this.onSupport,
    required this.onTag,
    required this.onPublisher,
  });

  final TextEditingController controller;
  final SupportFilter support;
  final String? tag, publisher;
  final List<String> tags, publishers;
  final VoidCallback onQuery;
  final ValueChanged<SupportFilter> onSupport;
  final ValueChanged<String?> onTag;
  final ValueChanged<String?> onPublisher;

  @override
  Widget build(BuildContext context) {
    final e = context.strings.explore;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 250,
          child: TextField(
            key: const Key('explore-search'),
            controller: controller,
            onChanged: (_) => onQuery(),
            decoration: InputDecoration(
              isDense: true,
              hintText: e.searchHint,
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        controller.clear();
                        onQuery();
                      },
                    ),
            ),
          ),
        ),
        for (final option in [
          (SupportFilter.all, e.filterAll),
          (SupportFilter.compatible, e.filterCompatible),
          (SupportFilter.partial, e.filterPartial),
          (SupportFilter.unsupported, e.filterUnsupported),
        ])
          ChoiceChip(
            key: ValueKey('filter-${option.$1.name}'),
            label: Text(option.$2),
            selected: support == option.$1,
            onSelected: (_) => onSupport(option.$1),
          ),
        if (tags.isNotEmpty)
          _Dropdown(
            key: const Key('filter-tag'),
            value: tag,
            hint: e.allCategories,
            values: tags,
            onChanged: onTag,
          ),
        if (publishers.isNotEmpty)
          _Dropdown(
            key: const Key('filter-publisher'),
            value: publisher,
            hint: e.allPublishers,
            values: publishers,
            onChanged: onPublisher,
          ),
      ],
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    super.key,
    required this.value,
    required this.hint,
    required this.values,
    required this.onChanged,
  });

  final String? value;
  final String hint;
  final List<String> values;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: WeColors.surface2,
      borderRadius: BorderRadius.circular(WeSizes.radius),
      border: Border.all(color: WeColors.border),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value != null && values.contains(value) ? value! : '',
        isDense: true,
        dropdownColor: WeColors.surface2,
        style: const TextStyle(color: WeColors.text, fontSize: 13),
        items: [
          DropdownMenuItem(value: '', child: Text(hint)),
          for (final v in values) DropdownMenuItem(value: v, child: Text(v)),
        ],
        onChanged: (v) => onChanged(v == null || v.isEmpty ? null : v),
      ),
    ),
  );
}

class _EffectCard extends StatelessWidget {
  const _EffectCard({
    super.key,
    required this.effect,
    required this.applied,
    required this.thumbnail,
    required this.onApply,
    required this.onRemove,
  });

  final InstalledEffect effect;
  final bool applied;
  final Future<Uint8List?>? thumbnail;
  final VoidCallback? onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final e = strings.explore;
    final badgeColor = switch (effect.compatibility.support) {
      EffectSupport.compatible => WeColors.ok,
      EffectSupport.partial => WeColors.warn,
      EffectSupport.unsupported => WeColors.danger,
    };
    return Container(
      decoration: BoxDecoration(
        color: WeColors.surface,
        borderRadius: BorderRadius.circular(WeSizes.radius),
        border: Border.all(
          color: applied ? WeColors.accent : WeColors.border,
          width: applied ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _Thumb(effect: effect, bytes: thumbnail),
                Positioned(
                  left: 8,
                  top: 8,
                  child: StatusPill(
                    label: switch (effect.compatibility.support) {
                      EffectSupport.compatible => e.compatible,
                      EffectSupport.partial => e.partial,
                      EffectSupport.unsupported => e.unsupported,
                    },
                    color: badgeColor,
                    background: WeColors.bg.withValues(alpha: .82),
                  ),
                ),
                if (applied)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: StatusPill(
                      label: e.appliedBadge,
                      color: WeColors.accent,
                      background: WeColors.bg.withValues(alpha: .82),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    effect.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    effect.publisher ??
                        switch (effect.origin) {
                          EffectOrigin.file => e.originFile,
                          EffectOrigin.folder => e.originFolder,
                          EffectOrigin.zip => e.originZip,
                          EffectOrigin.windowsCache => e.originWindowsCache,
                        },
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: WeColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 22,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final t in effect.tags.take(4))
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: _Tag(text: t),
                          ),
                      ],
                    ),
                  ),
                  if (!effect.canRun) ...[
                    const SizedBox(height: 4),
                    Text(
                      e.requires(
                        [
                          for (final i in effect.compatibility.issues)
                            strings.lighting.compatibilityIssue(i.index),
                        ].join(', '),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: WeColors.danger,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: applied
                            ? OutlinedButton.icon(
                                onPressed: null,
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                ),
                                label: Text(e.applied),
                              )
                            : FilledButton.tonalIcon(
                                onPressed: onApply,
                                icon: const Icon(Icons.play_arrow, size: 18),
                                label: Text(e.apply),
                              ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        key: ValueKey('remove-${effect.id}'),
                        onPressed: onRemove,
                        tooltip: e.removeFromLibrary,
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: WeColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.effect, required this.bytes});
  final InstalledEffect effect;
  final Future<Uint8List?>? bytes;

  @override
  Widget build(BuildContext context) {
    final future = bytes;
    if (future != null) {
      return FutureBuilder<Uint8List?>(
        future: future,
        builder: (context, snap) {
          final data = snap.data;
          if (data != null) {
            return Image.memory(
              data,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              // A frame is 320×200: keep it crisp.
              filterQuality: FilterQuality.medium,
            );
          }
          return _placeholder();
        },
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    final hash = effect.id.hashCode.abs();
    final hue = (hash % 360).toDouble();
    final a = HSVColor.fromAHSV(1, hue, .55, .38).toColor();
    final b = HSVColor.fromAHSV(1, (hue + 55) % 360, .65, .18).toColor();
    final initial = effect.title.trim().isEmpty
        ? '?'
        : effect.title.trim().characters.first.toUpperCase();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [b, a],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: .82),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: WeColors.surface2,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: WeColors.border),
    ),
    child: Text(
      text,
      style: const TextStyle(color: WeColors.muted, fontSize: 10.5),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final e = context.strings.explore;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome_outlined,
            size: 42,
            color: WeColors.muted,
          ),
          const SizedBox(height: 12),
          Text(
            e.noEffectsTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 430,
            child: Text(
              e.noEffectsBody,
              textAlign: TextAlign.center,
              style: const TextStyle(color: WeColors.muted, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}
