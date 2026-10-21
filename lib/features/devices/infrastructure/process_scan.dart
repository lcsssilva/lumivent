// Detects programs that also access the same HID/SMBus devices.
// Two owners at once mix packets and leave the hardware in an
// unpredictable state, so the app only warns (it never kills anything).
import 'dart:io';

/// Display name → process names (`comm` or argv) that identify it.
const conflictingPrograms = <String, List<String>>{
  'OpenRGB': ['openrgb'],
  'liquidctl': ['liquidctl'],
  'CoolerControl': ['coolercontrold'],
  'ckb-next': ['ckb-next-daemon'],
};

/// Programs from [conflictingPrograms] running now, read from `/proc`.
List<String> findConflictingPrograms({
  String procRoot = '/proc',
  int? selfPid,
}) {
  selfPid ??= pid;
  final found = <String>{};
  final dir = Directory(procRoot);
  if (!dir.existsSync()) return const [];
  for (final e in dir.listSync()) {
    final name = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
    final p = int.tryParse(name);
    if (p == null || p == selfPid) continue;
    final names = _processNames(e.path);
    for (final MapEntry(key: label, value: ids)
        in conflictingPrograms.entries) {
      if (ids.any(names.contains)) found.add(label);
    }
  }
  return found.toList()..sort();
}

/// `comm` and the base name of the first two arguments (covers Python scripts
/// such as `python3 /usr/bin/liquidctl`).
Set<String> _processNames(String procDir) {
  final out = <String>{};
  try {
    out.add(File('$procDir/comm').readAsStringSync().trim().toLowerCase());
    final argv = File('$procDir/cmdline').readAsStringSync().split('\x00');
    for (final a in argv.take(2)) {
      if (a.isNotEmpty) out.add(a.split('/').last.toLowerCase());
    }
  } on FileSystemException {
    // process exited in the middle of the read
  }
  return out;
}
