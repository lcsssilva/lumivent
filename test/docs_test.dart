// Documentation checks: keep the public Markdown in sync with the repository.
//
//  1. Every relative link in a published .md file points to a published file.
//  2. Every #anchor points to a heading of the target file (GitHub slugs).
//
// "Published" means what Git would ship (tracked or new, not ignored): docs/
// holds local notes only, so the public docs must not link to it.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _link = RegExp(r'\[[^\]]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)');
final _heading = RegExp(r'^#{1,6}\s+(.+?)\s*#*\s*$');
final _fence = RegExp(r'^\s*(```|~~~)');

List<String>? _trackedFiles() {
  try {
    final r = Process.runSync('git', [
      'ls-files',
      '--cached',
      '--others',
      '--exclude-standard',
    ]);
    if (r.exitCode != 0) return null;
    return (r.stdout as String).split('\n').where((l) => l.isNotEmpty).toList();
  } on ProcessException {
    return null;
  }
}

/// Lines outside fenced code blocks, with inline code removed.
Iterable<String> _proseLines(String markdown) sync* {
  var inFence = false;
  for (final line in markdown.split('\n')) {
    if (_fence.hasMatch(line)) {
      inFence = !inFence;
      continue;
    }
    if (!inFence) yield line;
  }
}

/// Heading anchors as GitHub generates them, including `-1`, `-2` suffixes.
Set<String> _anchors(String markdown) {
  final seen = <String, int>{};
  final out = <String>{};
  for (final line in _proseLines(markdown)) {
    final m = _heading.firstMatch(line);
    if (m == null) continue;
    final slug = m
        .group(1)!
        .toLowerCase()
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s_-]', unicode: true), '')
        .trim()
        .replaceAll(RegExp(r'\s'), '-');
    final n = seen.update(slug, (v) => v + 1, ifAbsent: () => 0);
    out.add(n == 0 ? slug : '$slug-$n');
  }
  return out;
}

String _decode(String s) {
  try {
    return Uri.decodeComponent(s);
  } on ArgumentError {
    return s;
  }
}

String _normalize(String path) {
  final parts = <String>[];
  for (final p in path.split('/')) {
    if (p.isEmpty || p == '.') continue;
    if (p == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else {
      parts.add(p);
    }
  }
  return parts.join('/');
}

void main() {
  final tracked = _trackedFiles();
  final skip = tracked == null ? 'git is not available' : null;
  final files = tracked ?? const <String>[];
  final trackedSet = files.toSet();
  final dirs = {
    for (final f in files)
      for (var i = f.indexOf('/'); i > 0; i = f.indexOf('/', i + 1))
        f.substring(0, i),
  };
  final markdown = files.where((f) => f.endsWith('.md')).toList();

  test('relative links and anchors in the docs resolve', () {
    final broken = <String>[];
    final anchorCache = <String, Set<String>>{};
    Set<String> anchorsOf(String path) => anchorCache.putIfAbsent(
      path,
      () => _anchors(File(path).readAsStringSync()),
    );

    for (final doc in markdown) {
      final base = doc.contains('/')
          ? doc.substring(0, doc.lastIndexOf('/'))
          : '';
      for (final line in _proseLines(File(doc).readAsStringSync())) {
        final prose = line.replaceAll(RegExp(r'`[^`]*`'), '');
        for (final m in _link.allMatches(prose)) {
          final target = m.group(1)!;
          if (RegExp(r'^[a-z][a-z0-9+.-]*:').hasMatch(target)) continue;
          final hash = target.indexOf('#');
          final pathPart = hash < 0 ? target : target.substring(0, hash);
          final anchor = hash < 0 ? null : target.substring(hash + 1);
          final resolved = pathPart.isEmpty
              ? doc
              : _normalize(base.isEmpty ? pathPart : '$base/$pathPart');

          if (!trackedSet.contains(resolved) && !dirs.contains(resolved)) {
            broken.add('$doc → $target (not tracked by Git)');
            continue;
          }
          if (anchor != null &&
              anchor.isNotEmpty &&
              resolved.endsWith('.md') &&
              !anchorsOf(resolved).contains(_decode(anchor))) {
            broken.add('$doc → $target (no such heading)');
          }
        }
      }
    }
    expect(broken, isEmpty, reason: broken.join('\n'));
  }, skip: skip);
}
