// Architecture rules, checked through imports:
//
//  1. core/ does not know app/ or features/.
//  2. features/ do not know app/.
//  3. A module uses another only through its public API: features/<m>/<m>.dart.
//  4. domain/ is pure Dart: no Flutter, Riverpod, IO, FFI, isolates, or
//     dependencies on application/infrastructure/presentation or core/.
//  5. application/ does not depend on infrastructure/ or presentation/.
//  6. presentation/ does not depend on infrastructure/.
//
// File organization rules (docs/rules/flutter-architecture.md):
//
//  7. A Dart file declares at most one class (generated files excepted).
//  8. A file with a class is named after it; a *_test.dart file declares none.
//  9. Presentation code is split into views/, view_models/, and widgets/:
//     `*View` classes live in views/, `*ViewModel`/`*UiState` in
//     view_models/, and the presentation/ root holds no classes.
// 10. `Controller` names only hardware controllers (infrastructure/drivers/).
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

final _classDeclaration = RegExp(
  r'^\s*(?:(?:abstract|sealed|final|base|interface|mixin)\s+)*class\s+(\w+)',
  multiLine: true,
);

/// Names of the classes declared in [file].
List<String> _classes(File file) => [
  for (final m in _classDeclaration.allMatches(file.readAsStringSync()))
    m.group(1)!,
];

/// Compares a file name with a class name: `quickjs_effect` matches
/// `QuickJsEffect`, and a private `_FooState` matches `foo_state`.
String _normalized(String name) => name.replaceAll('_', '').toLowerCase();

bool _isGenerated(String path) =>
    path.endsWith('.freezed.dart') || path.endsWith('.g.dart');

/// Hand-written Dart files under [dirs], with paths relative to the root.
List<(String, File)> _sources(List<String> dirs) => [
  for (final dir in dirs)
    if (Directory(dir).existsSync())
      for (final f in Directory(
        dir,
      ).listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart') && !_isGenerated(f.path))
          (f.path.replaceAll(r'\', '/'), f),
];

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

  test('code outside the catalogs has no Portuguese UI literals', () {
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
    // Values that older versions wrote to config.json, recognized only to
    // migrate them; they are data, not UI text.
    const legacyData = {
      'features/fans/infrastructure/json_fans_repository.dart': {
        "'Grupo \$group'",
      },
    };
    final leaks = <String>[];

    for (final file
        in Directory(libRoot)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      final path = file.path.substring(libRoot.length + 1);
      if (path.startsWith('core/i18n/catalogs/') ||
          path == 'main_spike.dart' ||
          path.startsWith('spike/') ||
          path.endsWith('.g.dart') ||
          path.endsWith('.freezed.dart')) {
        continue;
      }
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('//')) continue;
        final code = {
          ...allowed,
          ...?legacyData[path],
        }.fold(line, (l, word) => l.replaceAll(word, ''));
        for (final word in forbidden) {
          final boundary = RegExp(
            '(^|[^A-Za-zÀ-ÿ])${RegExp.escape(word)}([^A-Za-zÀ-ÿ]|\$)',
            caseSensitive: false,
          );
          if (boundary.hasMatch(code)) {
            leaks.add('$path:${i + 1}: $word');
          }
        }
      }
    }

    expect(leaks, isEmpty, reason: leaks.join('\n'));
  });

  test('Portuguese text lives only in the catalogs', () {
    // Accented Portuguese letters in code outside the catalogs mean a UI text
    // or technical message that escaped translation (messages are English).
    final accented = RegExp('[áàâãéêíóôõúçÁÀÂÃÉÊÍÓÔÕÚÇ]');
    const allowed = {'Português'};
    final leaks = <String>[];
    for (final file
        in Directory(libRoot)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      final path = file.path.substring(libRoot.length + 1);
      if (path.startsWith('core/i18n/catalogs/') ||
          path == 'main_spike.dart' ||
          path.startsWith('spike/')) {
        continue;
      }
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('//')) continue;
        final code = allowed.fold(line, (l, word) => l.replaceAll(word, ''));
        if (accented.hasMatch(code)) leaks.add('$path:${i + 1}: $line');
      }
    }
    expect(leaks, isEmpty, reason: leaks.join('\n'));
  });

  group('file organization', () {
    final sources = _sources(['lib', 'test', 'tool']);

    test('each Dart file declares at most one class', () {
      final violations = [
        for (final (path, file) in sources)
          if (_classes(file) case final classes when classes.length > 1)
            '$path: ${classes.join(', ')}',
      ];
      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('a class file is named after its class', () {
      final violations = <String>[];
      for (final (path, file) in sources) {
        final classes = _classes(file);
        final name = path.split('/').last.replaceFirst(RegExp(r'\.dart$'), '');
        if (name.endsWith('_test')) {
          if (classes.isNotEmpty) {
            violations.add('$path: move ${classes.join(', ')} to own files');
          }
        } else if (classes.length == 1 &&
            _normalized(classes.single) != _normalized(name)) {
          violations.add('$path: ${classes.single}');
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('presentation keeps views, view models, and widgets apart', () {
      const layers = {'views', 'view_models', 'widgets'};
      final violations = <String>[];
      for (final (path, file) in _sources(['lib'])) {
        final parts = path.split('/');
        final dir = parts[parts.length - 2];
        if (parts.contains('pages') || parts.contains('screens')) {
          violations.add('$path: screens belong in views/');
        }
        final presentation = parts.indexOf('presentation');
        if (presentation >= 0 && presentation < parts.length - 2) {
          if (!layers.contains(parts[presentation + 1])) {
            violations.add('$path: use views/, view_models/, or widgets/');
          }
        }
        for (final name in _classes(file)) {
          final bare = name.replaceFirst(RegExp(r'^_+'), '');
          if (presentation == parts.length - 2) {
            violations.add(
              '$path: $name; the presentation/ root holds no classes',
            );
          }
          if (bare.endsWith('View') && dir != 'views') {
            violations.add('$path: $name belongs in views/');
          }
          if (bare.endsWith('ViewModel') && dir != 'view_models') {
            violations.add('$path: $name belongs in view_models/');
          }
          if (dir == 'views' &&
              !bare.endsWith('View') &&
              !bare.endsWith('ViewState')) {
            violations.add('$path: $name is not a view; move it to widgets/');
          }
          if (dir == 'view_models' &&
              !bare.endsWith('ViewModel') &&
              !bare.endsWith('UiState')) {
            violations.add('$path: $name is not a view model or its state');
          }
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('Controller names only hardware controllers', () {
      final violations = [
        for (final (path, file) in _sources(['lib']))
          for (final name in _classes(file))
            if (name.endsWith('Controller') &&
                !path.contains('/infrastructure/drivers/'))
              '$path: $name (use a ViewModel or a Notifier)',
      ];
      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  });
}
