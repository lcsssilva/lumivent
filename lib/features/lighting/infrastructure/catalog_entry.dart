part of 'file_effect_importer.dart';

class _CatalogEntry {
  const _CatalogEntry({
    this.title,
    this.publisher,
    this.description,
    this.tags = const [],
    this.paid = false,
  });
  final String? title, publisher, description;
  final List<String> tags;

  /// Requires a subscription or a purchase in the original app.
  final bool paid;
}
