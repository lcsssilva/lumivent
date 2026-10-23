import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../lighting/lighting.dart';
import '../../application/effect_filter.dart';
import 'explore_ui_state.dart';

/// Presentation state of the explore view: filters, thumbnails, and the
/// import/apply/remove actions on the installed effects.
class ExploreViewModel extends Notifier<ExploreUiState> {
  /// Kept across rebuilds of [build] (new effects, another applied effect).
  EffectFilter _filter = const EffectFilter();
  final _thumbnails = <String, Future<Uint8List?>>{};

  @override
  ExploreUiState build() => ExploreUiState(
    installed: ref.watch(installedEffectsProvider),
    appliedEffectId: ref.watch(lightingProvider.select((c) => c.effectId)),
    filter: _filter,
  );

  InstalledEffectsNotifier get _effects =>
      ref.read(installedEffectsProvider.notifier);

  void setQuery(String query) => _setFilter(
    EffectFilter(
      query: query,
      support: _filter.support,
      tag: _filter.tag,
      publisher: _filter.publisher,
    ),
  );

  void setSupport(SupportFilter support) => _setFilter(
    EffectFilter(
      query: _filter.query,
      support: support,
      tag: _filter.tag,
      publisher: _filter.publisher,
    ),
  );

  void setTag(String? tag) => _setFilter(
    EffectFilter(
      query: _filter.query,
      support: _filter.support,
      tag: tag,
      publisher: _filter.publisher,
    ),
  );

  void setPublisher(String? publisher) => _setFilter(
    EffectFilter(
      query: _filter.query,
      support: _filter.support,
      tag: _filter.tag,
      publisher: publisher,
    ),
  );

  void _setFilter(EffectFilter filter) {
    _filter = filter;
    state = state.withFilter(filter);
  }

  /// Imports HTML files, folders, or ZIP archives. Errors reach the caller.
  Future<ImportReport> importPaths(List<String> paths) =>
      _afterImport(_effects.importPaths(paths));

  /// Imports the effects cache of a Windows installation (read-only).
  Future<ImportReport> importWindowsCache(String folder) =>
      _afterImport(_effects.importWindowsCache(folder));

  Future<ImportReport> _afterImport(Future<ImportReport> import) async {
    final report = await import;
    // Replaced effects may have new thumbnails.
    _thumbnails.clear();
    return report;
  }

  void applyEffect(InstalledEffect effect) => ref
      .read(lightingProvider.notifier)
      .update((current) => current.copyWith(effectId: effect.effectId));

  /// Removes [effect]. When it is applied, the default effect is applied
  /// first so the lighting never points at a missing effect. Errors reach
  /// the caller.
  Future<void> removeEffect(InstalledEffect effect) async {
    if (state.isApplied(effect)) {
      ref
          .read(lightingProvider.notifier)
          .update((current) => current.copyWith(effectId: defaultEffectId));
    }
    await _effects.remove(effect.id);
    _thumbnails.remove(effect.id);
  }

  /// Thumbnail of [effect], read once per effect.
  Future<Uint8List?> thumbnail(InstalledEffect effect) =>
      _thumbnails.putIfAbsent(effect.id, () => _effects.thumbnail(effect.id));

  /// Reads the effect library again after a failure.
  void retryLibrary() => ref.invalidate(installedEffectsProvider);
}

final exploreViewModelProvider =
    NotifierProvider.autoDispose<ExploreViewModel, ExploreUiState>(
      ExploreViewModel.new,
    );
