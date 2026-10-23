import 'dart:io';
import 'dart:typed_data';

import 'import_too_large.dart';

/// Reads [file] fully, throwing [ImportTooLarge] as soon as more than [limit]
/// bytes have been read.
Future<Uint8List> readBounded(File file, int limit) async {
  final bytes = BytesBuilder(copy: false);
  var length = 0;
  await for (final chunk in file.openRead()) {
    length += chunk.length;
    if (length > limit) {
      throw ImportTooLarge(limit);
    }
    bytes.add(chunk);
  }
  return bytes.takeBytes();
}
