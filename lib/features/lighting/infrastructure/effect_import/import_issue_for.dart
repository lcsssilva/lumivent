import '../../domain/effect_import/import_issue.dart';
import '../../domain/effects/effect_library.dart';
import 'import_too_large.dart';

/// Issue for an error caught while importing [path]: the size limit has its
/// own translated message; anything else keeps the technical detail.
ImportIssue importIssueFor(String path, Object error) => error is ImportTooLarge
    ? ImportIssue(ImportIssueKind.tooLarge, path: path)
    : ImportIssue(ImportIssueKind.unknown, path: path, detail: '$error');
