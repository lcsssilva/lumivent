// Architecture rules, checked through imports:
//
//  1. core/ does not know app/ or features/.
//  2. features/ do not know app/.
//  3. A module uses another only through its public API: features/<m>/<m>.dart.
//  4. domain/ is pure Dart: no Flutter, Riverpod, IO, FFI, isolates, or
//     dependencies on application/infrastructure/presentation or core/.
//  5. application/ does not depend on infrastructure/ or presentation/.
//  6. presentation/ does not depend on infrastructure/.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _directive = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// Resolves imports from [file] to paths relative to `lib/` (external packages
/// and `dart:` imports are left unchanged).
List<String> _imports(File file, String libRoot) {
  final out = <String>[];
  for (final m in _directive.allMatches(file.readAsStringSync())) {
    final uri = m.group(1)!;
    if (uri.startsWith('package:lumivent/')) {
      out.add(uri.substring('package:lumivent/'.length));
    } else if (uri.startsWith('package:') || uri.startsWith('dart:')) {
      out.add(uri);
    } else {
      final abs = File(file.parent.uri.resolve(uri).toFilePath()).absolute.path;
      out.add(abs.substring(libRoot.length + 1));
    }
  }
  return out;
}

String? _feature(String path) {
  final parts = path.split('/');
  return parts.length > 1 && parts[0] == 'features' ? parts[1] : null;
}

String? _layer(String path) {
  final parts = path.split('/');
  return parts.length > 2 && parts[0] == 'features' ? parts[2] : null;
}

void main() {
  final libRoot = Directory('lib').absolute.path;
  final files = Directory(libRoot)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();
  final violations = <String>[];

  for (final file in files) {
    final self = file.path.substring(libRoot.length + 1);
    final selfFeature = _feature(self);
    final selfLayer = _layer(self);
    for (final imp in _imports(file, libRoot)) {
      void fail(String rule) => violations.add('$self → $imp ($rule)');
      final isLocal = !imp.startsWith('package:') && !imp.startsWith('dart:');

      if (self.startsWith('core/') &&
          isLocal &&
          (imp.startsWith('app/') || imp.startsWith('features/'))) {
        fail('1: core must not depend on app/features');
      }
      if (selfFeature != null && imp.startsWith('app/')) {
        fail('2: feature must not depend on app');
      }

      final impFeature = isLocal ? _feature(imp) : null;
      if (selfFeature != null &&
          impFeature != null &&
          impFeature != selfFeature) {
        if (imp != 'features/$impFeature/$impFeature.dart') {
          fail('3: use only the public API');
        }
      }
      if (selfFeature == null || impFeature != selfFeature && isLocal) {
        if (selfLayer == 'domain' && isLocal) {
          fail('4: domain must not depend outside its module');
        }
        continue;
      }

      final impLayer = isLocal ? _layer(imp) : null;
      if (selfLayer == 'domain') {
        const forbidden = [
          'package:flutter',
          'package:flutter_riverpod',
          'dart:io',
          'dart:ffi',
          'dart:ui',
          'dart:isolate',
        ];
        if (forbidden.any(imp.startsWith)) fail('4: domain must be pure Dart');
        if (isLocal && impLayer != 'domain') {
          fail('4: domain may depend only on domain');
        }
      }
      if (selfLayer == 'application' &&
          (impLayer == 'infrastructure' || impLayer == 'presentation')) {
        fail('5: application must not depend on $impLayer');
      }
      if (selfLayer == 'presentation' && impLayer == 'infrastructure') {
        fail('6: presentation must not depend on infrastructure');
      }
    }
  }

  test('imports follow the modular architecture', () {
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('every module has the public API features/<m>/<m>.dart', () {
    final modules = Directory('$libRoot/features')
        .listSync()
        .whereType<Directory>();
    for (final m in modules) {
      final name = m.uri.pathSegments.where((s) => s.isNotEmpty).last;
      expect(File('${m.path}/$name.dart').existsSync(), isTrue, reason: name);
    }
  });

  test('app and presentation have no Portuguese UI literals', () {
    // Words that only make sense in Portuguese UI text. The language selector
    // uses the endonym "Português", which is intentionally not translated.
    const forbidden = [
      'Configurações',
      'Iluminação',
      'Preferências',
      'Monitoramento',
      'Gabinete',
      'Memória',
      'Curva',
      'Velocidade',
      'Idioma',
      'Licenças',
      'Erro',
      'Falha',
      'Não',
      'não',
      'efeito',
      'arquivo',
      'pasta',
      'placa',
      'ventoinha',
      'grupo',
      'tela',
      'sistema',
      'iniciar',
      'salvar',
      'remover',
      'cancelar',
    ];
    const allowed = {'Português'};
    final leaks = <String>[];

    final targets = <Directory>[
      Directory('$libRoot/app'),
      ...Directory('$libRoot/features')
          .listSync()
          .whereType<Directory>()
          .map((m) => Directory('${m.path}/presentation'))
          .where((d) => d.existsSync()),
    ];

    for (final dir in targets) {
      for (final file
          in dir
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.startsWith('//')) continue;
          for (final word in forbidden) {
            final boundary = RegExp(
              '(^|[^A-Za-zÀ-ÿ])${RegExp.escape(word)}([^A-Za-zÀ-ÿ]|\$)',
              caseSensitive: false,
            );
            if (boundary.hasMatch(line) && !allowed.any(line.contains)) {
              final path = file.path.substring(libRoot.length + 1);
              leaks.add('$path:${i + 1}: $word');
            }
          }
        }
      }
    }

    expect(leaks, isEmpty, reason: leaks.join('\n'));
  });
}
