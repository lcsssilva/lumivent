import 'effect_library.dart';

/// One import failure: [path] is the original user path or ZIP entry, [detail]
/// the technical error (never shown untranslated).
class ImportIssue {
  const ImportIssue(this.kind, {this.path, this.detail});

  final ImportIssueKind kind;
  final String? path;
  final String? detail;

  @override
  String toString() =>
      'ImportIssue(${kind.name}${path == null ? '' : ': $path'})';
}
