// Single configuration file (`~/.config/lumivent/config.json`) divided into
// one section per module:
//
//   { "version": 1, "preferences": {...}, "lighting": {...} }
//
// Each module reads and writes only its own section (through its repository),
// like module tables in a modular monolith. Writes are atomic (temporary file
// plus rename) and are serialized.
import 'dart:async';
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

/// A failure to persist the configuration file.
class ConfigWriteFailure implements Exception {
  const ConfigWriteFailure({
    required this.section,
    required this.cause,
    required this.stackTrace,
  });

  /// JSON section name that was being written; whole-file writes (import) are
  /// recorded as `configuration`.
  final String section;

  /// The original write error.
  final Object cause;
  final StackTrace stackTrace;

  @override
  String toString() => 'Failed to save $section: $cause';
}

class ConfigStore {
  ConfigStore._(this.dir, this._data);

  static const schemaVersion = 1;

  final Directory dir;
  final JsonMap _data;
  Future<void> _queue = Future.value();

  // One piece of write-failure state: set by a failed write, cleared only by
  // a later successful write (recovery) or by reporting it once at flush.
  ConfigWriteFailure? _writeFailure;

  /// Emits a failure each time a write fails (a consecutive failure is a new
  /// event, it is not kept silently). Successful writes emit nothing; the
  /// failure is already visible through [flush] when rogue state would be
  /// lost at shutdown.
  // Synchronous delivery: a failure is announced in the order the writes
  // finish, including while a test awaits the failed write itself.
  late final _writeFailures = StreamController<ConfigWriteFailure>.broadcast(
    sync: true,
  );

  Stream<ConfigWriteFailure> get writeFailures => _writeFailures.stream;

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
    return _enqueue(name, () => _write(snapshot));
  }

  /// The whole configuration as it goes to disk (export). A deep copy.
  JsonMap snapshot() =>
      jsonDecode(jsonEncode({..._data, 'version': schemaVersion})) as JsonMap;

  /// Replaces every section in [sections] in a single write (import). With
  /// [backupSuffix], the current file is first copied to
  /// `config.json.<backupSuffix>`.
  ///
  /// Unlike [saveSection], a failed write restores the previous sections in
  /// memory: no module applied the import, so keeping it would let the next
  /// section save write it to disk unannounced.
  Future<void> replaceSections(JsonMap sections, {String? backupSuffix}) {
    final previous = {
      for (final key in sections.keys)
        if (_data.containsKey(key)) key: _data[key],
    };
    for (final MapEntry(:key, :value) in sections.entries) {
      _data[key] = value;
    }
    final snapshot = {..._data, 'version': schemaVersion};
    return _enqueue('configuration', () async {
      try {
        if (backupSuffix != null && await file.exists()) {
          await file.copy('${file.path}.$backupSuffix');
        }
        await _write(snapshot);
      } on Object {
        _restoreSections(sections, previous);
        rethrow;
      }
    });
  }

  /// Puts back [previous] for each of [sections] that no later save replaced.
  void _restoreSections(JsonMap sections, JsonMap previous) {
    for (final MapEntry(:key, :value) in sections.entries) {
      if (!identical(_data[key], value)) continue;
      if (previous.containsKey(key)) {
        _data[key] = previous[key];
      } else {
        _data.remove(key);
      }
    }
  }

  /// Waits for pending writes (used during shutdown) and reports a failure
  /// that still was not recovered by a later successful write, exactly once.
  Future<void> flush() async {
    await _queue;
    final failure = _writeFailure;
    _writeFailure = null;
    if (failure != null) {
      Error.throwWithStackTrace(failure, failure.stackTrace);
    }
  }

  Future<void> _enqueue(String section, Future<void> Function() write) {
    final next = _queue.then((_) async {
      try {
        await write();
        _writeFailure = null;
      } on Object catch (error, stackTrace) {
        final failure = ConfigWriteFailure(
          section: section,
          cause: error,
          stackTrace: stackTrace,
        );
        _writeFailure = failure;
        _writeFailures.add(failure);
        // The caller keeps seeing the write error type it caused, wrapped to
        // carry the section name and the original stack trace.
        Error.throwWithStackTrace(failure, stackTrace);
      }
    });
    _queue = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

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

/// Emits one failure event per failed write, for user-visible notifications.
final configWriteFailuresProvider = StreamProvider<ConfigWriteFailure>((ref) {
  return ref.watch(configStoreProvider).writeFailures;
});

final configStoreProvider = Provider<ConfigStore>(
  (ref) => throw UnimplementedError('configStoreProvider'),
);
