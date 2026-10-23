/// An HTML file extracted from an effect ZIP, already inside the limits.
class ZipHtmlEntry {
  const ZipHtmlEntry({
    required this.name,
    required this.html,
    required this.fallbackName,
  });

  /// Path of the entry inside the archive, with `/` separators.
  final String name;

  final String html;

  /// Name for the effect id: the folder for `effect.html`, else the file.
  final String fallbackName;
}
