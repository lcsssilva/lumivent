import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../lighting/lighting.dart';
import '../../application/effect_filter.dart';

/// Installed effects, the applied one, and the active filter of the explore
/// view.
class ExploreUiState {
  const ExploreUiState({
    required this.installed,
    required this.appliedEffectId,
    this.filter = const EffectFilter(),
  });

  final AsyncValue<List<InstalledEffect>> installed;

  /// `LightingConfig.effectId` currently applied.
  final String appliedEffectId;
  final EffectFilter filter;

  ExploreUiState withFilter(EffectFilter filter) => ExploreUiState(
    installed: installed,
    appliedEffectId: appliedEffectId,
    filter: filter,
  );

  /// Installed effects, empty while loading or after a failure.
  List<InstalledEffect> get allEffects =>
      installed.value ?? const <InstalledEffect>[];

  List<InstalledEffect> get visibleEffects => filterEffects(allEffects, filter);

  List<String> get tags => availableTags(allEffects);

  List<String> get publishers => availablePublishers(allEffects);

  bool isApplied(InstalledEffect effect) => appliedEffectId == effect.effectId;
}
