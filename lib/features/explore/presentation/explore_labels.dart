// User-facing messages for the explore screen. The catalogs own the text; this
// file only maps import results to the matching catalog entry.
import '../../../core/i18n/catalogs/explore_strings.dart';
import '../../lighting/lighting.dart';

/// Message for one file that could not be imported.
String formatImportIssue(ExploreStrings e, ImportIssue issue) {
  final path = issue.path ?? '';
  final error = issue.detail ?? '';
  return switch (issue.kind) {
    ImportIssueKind.notHtmlOrZip => e.importNotHtmlOrZip(path),
    ImportIssueKind.notFound => e.importNotFound(path),
    ImportIssueKind.folderNotFound => e.importFolderNotFound(path),
    ImportIssueKind.chooseWindowsCache => e.importChooseWindowsCache,
    ImportIssueKind.catalogMissing => e.importCatalogMissing,
    ImportIssueKind.noEffectHtml => e.importNoEffectHtml(path),
    ImportIssueKind.invalidZip => e.importInvalidZip(path, error),
    ImportIssueKind.noHtmlInZip => e.importNoHtmlInZip,
    ImportIssueKind.tooLarge => e.importTooLarge(path),
    ImportIssueKind.unsupportedZipEntry => e.importUnsupportedZipEntry(path),
    ImportIssueKind.unknown => e.importUnknown(path, error),
  };
}
