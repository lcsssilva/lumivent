/// Metadata of one effect in the Windows effects-cache catalog.
class CatalogEntry {
  const CatalogEntry({
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
