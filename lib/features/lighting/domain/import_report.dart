import 'import_issue.dart';

/// What an import did, for the message shown to the user.
class ImportReport {
  ImportReport({
    this.imported = 0,
    this.replaced = 0,
    this.skipped = 0,
    this.paidSkipped = 0,
    List<ImportIssue>? issues,
    this.catalogFound = false,
  }) : issues = issues ?? [];

  int imported;
  int replaced;
  int skipped;

  /// Windows cache import: paid effects left out (subscription or purchase).
  int paidSkipped;
  final List<ImportIssue> issues;

  /// Windows cache import: `catalog_en.json` was found (names and tags).
  bool catalogFound;

  int get total => imported + replaced;

  bool get isEmpty => total == 0 && paidSkipped == 0 && issues.isEmpty;

  void add(ImportReport other) {
    imported += other.imported;
    replaced += other.replaced;
    skipped += other.skipped;
    paidSkipped += other.paidSkipped;
    issues.addAll(other.issues);
    catalogFound = catalogFound || other.catalogFound;
  }

  @override
  String toString() =>
      'ImportReport(imported: $imported, replaced: $replaced, '
      'skipped: $skipped, paidSkipped: $paidSkipped, '
      'issues: ${issues.length})';
}
