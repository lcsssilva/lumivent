import 'fan_curve.dart';
import 'fan_group.dart';
import 'fan_group_config.dart';

/// Configuration for the 4 hub groups.
class FansConfig {
  FansConfig(List<FanGroupConfig> groups) : groups = List.unmodifiable(groups) {
    assert(groups.length == fanGroupCount);
    assert(groups.indexed.every((e) => e.$2.group == e.$1));
  }

  /// Factory default: Standard based on CPU. On this PC group 1 has 140 mm fans
  /// (AL-V2 §8); the others have 120 mm.
  factory FansConfig.defaults() => FansConfig([
    for (var g = 0; g < fanGroupCount; g++)
      FanGroupConfig(
        group: g,
        name: '',
        size: g == 1 ? FanSize.mm140 : FanSize.mm120,
      ),
  ]);

  final List<FanGroupConfig> groups;

  FanGroupConfig operator [](int group) => groups[group];

  FansConfig replaced(FanGroupConfig g) =>
      FansConfig([...groups]..[g.group] = g);

  /// "Apply to all groups": copies the curve from [group] to the others.
  FansConfig curveAppliedToAll(int group) {
    final src = groups[group];
    return FansConfig([
      for (final g in groups) g.group == group ? g : g.withCurveOf(src),
    ]);
  }
}
