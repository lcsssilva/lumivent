// Single configuration file (`~/.config/lumivent/config.json`) divided into
// one section per module:
//
//   { "version": 1, "preferences": {...}, "lighting": {...} }
//
// Each module reads and writes only its own section (through its repository),
// like module tables in a modular monolith. Writes are atomic (temporary file
// plus rename) and are serialized.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `$XDG_CONFIG_HOME/lumivent`, or `~/.config/lumivent`.
Directory defaultConfigDir([Map<String, String>? env]) {
  env ??= Platform.environment;
  final xdg = env['XDG_CONFIG_HOME'];
  final base = (xdg != null && xdg.isNotEmpty) ? xdg : '${env['HOME']}/.config';
  return Directory('$base/lumivent');
}

typedef JsonMap = Map<String, Object?>;

class ConfigStore {
  ConfigStore._(this.dir, this._data);

  static const schemaVersion = 1;

  final Directory dir;
  final JsonMap _data;
  Future<void> _queue = Future.value();

  File get file => File('${dir.path}/config.json');

  /// Reads the file. A missing file returns empty configuration; a corrupt file
  /// is renamed to `config.json.bad` (so it is not silently overwritten) and
  /// also returns empty configuration.
  static Future<ConfigStore> open(Directory dir) async {
    final f = File('${dir.path}/config.json');
    var data = <String, Object?>{};
    if (await f.exists()) {
      try {
        final json = jsonDecode(await f.readAsString());
        if (json is JsonMap) {
          data = json;
        } else {
          await f.rename('${f.path}.bad');
        }
      } on FormatException {
        await f.rename('${f.path}.bad');
      }
    }
    return ConfigStore._(dir, data);
  }

  /// Module section [name]; empty if missing or not an object.
  JsonMap section(String name) {
    final s = _data[name];
    return s is JsonMap ? Map.of(s) : <String, Object?>{};
  }

  /// Replaces section [name] and writes the entire file.
  Future<void> saveSection(String name, JsonMap value) {
    _data[name] = Map.of(value);
    final snapshot = {..._data, 'version': schemaVersion};
    final next = _queue.then((_) => _write(snapshot));
    _queue = next.catchError((_) {});
    return next;
  }

  /// The whole configuration as it goes to disk (export). A deep copy.
  JsonMap snapshot() =>
      jsonDecode(jsonEncode({..._data, 'version': schemaVersion})) as JsonMap;

  /// Replaces every section in [sections] in a single write (import). With
  /// [backupSuffix], the current file is first copied to
  /// `config.json.<backupSuffix>`.
  Future<void> replaceSections(JsonMap sections, {String? backupSuffix}) {
    for (final MapEntry(:key, :value) in sections.entries) {
      _data[key] = value;
    }
    final snapshot = {..._data, 'version': schemaVersion};
    final next = _queue.then((_) async {
      if (backupSuffix != null && await file.exists()) {
        await file.copy('${file.path}.$backupSuffix');
      }
      await _write(snapshot);
    });
    _queue = next.catchError((_) {});
    return next;
  }

  /// Waits for pending writes (used during shutdown).
  Future<void> flush() => _queue;

  Future<void> _write(JsonMap data) async {
    await dir.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
      flush: true,
    );
    await tmp.rename(file.path);
  }
}

final configStoreProvider = Provider<ConfigStore>(
  (ref) => throw UnimplementedError('configStoreProvider'),
);
