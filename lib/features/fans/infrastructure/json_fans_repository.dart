import '../../../core/persistence/config_store.dart';
import '../domain/fan_curve.dart';
import '../domain/fan_point.dart';
import '../domain/fan_presets.dart';
import '../domain/fan_group.dart';
import '../domain/fan_group_config.dart';
import '../domain/fans_config.dart';
import '../domain/fans_repository.dart';
import '../domain/fan_response.dart';

/// Stores fan configuration in the `fans` section of config.json. Reading is
/// tolerant: missing or invalid fields use [FansConfig.defaults]. Fields from
/// old versions that no longer exist (such as `mbSync`) are ignored.
class JsonFansRepository implements FansRepository {
  JsonFansRepository(this._store);

  static const section = 'fans';
  final ConfigStore _store;

  @override
  FansConfig load() {
    final defaults = FansConfig.defaults();
    final raw = _store.section(section)['groups'];
    final list = raw is List ? raw : const [];
    return FansConfig([
      for (var g = 0; g < fanGroupCount; g++)
        _group(defaults[g], g < list.length ? list[g] : null),
    ]);
  }

  @override
  Future<void> save(FansConfig config) => _store.saveSection(section, {
    'groups': [for (final g in config.groups) _toJson(g)],
  });

  static Map<String, Object?> _toJson(FanGroupConfig g) => {
    'name': g.name,
    'size': g.size.name,
    'preset': g.preset.name,
    'customPoints': _pointsToJson(g.customPoints),
    'userPoints': {
      for (final e in g.userPoints.entries) e.key.name: _pointsToJson(e.value),
    },
    'fixedPercent': g.fixedPercent,
    'startStop': g.startStop,
    'source': g.source.name,
    'response': g.response.name,
  };

  static List<List<double>> _pointsToJson(List<FanPoint> pts) => [
    for (final p in pts) [p.temp, p.percent],
  ];

  static FanGroupConfig _group(FanGroupConfig d, Object? raw) {
    if (raw is! Map) return d;
    final userPoints = <FanPreset, List<FanPoint>>{};
    final up = raw['userPoints'];
    if (up is Map) {
      for (final preset in FanPreset.values.where((p) => p.isUser)) {
        final pts = _points(up[preset.name]);
        if (pts != null) userPoints[preset] = pts;
      }
    }
    final name = raw['name'];
    final fixed = raw['fixedPercent'];
    final startStop = raw['startStop'];
    return d.copyWith(
      name: name is String && name.trim().isNotEmpty
          ? _normalizeName(name, d.group)
          : null,
      size: _enum(FanSize.values, raw['size']),
      preset: _enum(FanPreset.values, raw['preset']),
      customPoints: _points(raw['customPoints']),
      userPoints: userPoints,
      fixedPercent: fixed is num && fixed.isFinite
          ? fixed.toDouble().clamp(0, 100)
          : null,
      startStop: startStop is bool ? startStop : null,
      source: _enum(FanTempSource.values, raw['source']),
      response: _enum(FanResponse.values, raw['response']),
    );
  }

  static T? _enum<T extends Enum>(List<T> values, Object? name) =>
      name is String ? values.where((v) => v.name == name).firstOrNull : null;

  /// Older versions stored the default group names ("Grupo N"/"Group N") as if
  /// the user had chosen them. They become empty so the UI uses the catalog.
  static String _normalizeName(String name, int group) {
    final trimmed = name.trim();
    return trimmed == 'Grupo $group' || trimmed == 'Group $group'
        ? ''
        : trimmed;
  }

  /// `[[temp, percent], ...]`; `null` if the list or any point is invalid.
  static List<FanPoint>? _points(Object? raw) {
    if (raw is! List) return null;
    final out = <FanPoint>[];
    for (final p in raw) {
      if (p is! List || p.length != 2) return null;
      final t = p[0], v = p[1];
      if (t is! num || v is! num || !t.isFinite || !v.isFinite) return null;
      out.add(FanPoint(t.toDouble().clamp(0, 100), v.toDouble().clamp(0, 100)));
    }
    return out.take(FanPresets.maxPoints).toList();
  }
}
