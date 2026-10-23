/// A file read stopped at the import size [limit].
class ImportTooLarge implements Exception {
  const ImportTooLarge(this.limit);

  final int limit;

  @override
  String toString() => 'File exceeds the $limit-byte import limit';
}
