part of 'file_effect_importer.dart';

/// A file read stopped at the import size [limit].
class _TooLarge implements Exception {
  const _TooLarge(this.limit);

  final int limit;

  @override
  String toString() => 'File exceeds the $limit-byte import limit';
}
