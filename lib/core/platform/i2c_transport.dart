import 'dart:typed_data';

/// One I²C device on an open adapter.
///
/// [write] and [read] are separate transfers (STOP between them), matching the
/// sequence the GPU controller expects. Implementations never retry: the
/// caller decides whether a failed transfer is worth repeating.
abstract interface class I2cTransport {
  /// Writes [data] to the device.
  void write(Uint8List data);

  /// Reads [length] bytes from the device.
  Uint8List read(int length);

  /// Runs [body] holding an exclusive advisory lock (`flock`) on the adapter.
  ///
  /// A command and the read that answers it are separate transfers: without
  /// the lock, another handle of the same bus (the device probe and the
  /// lighting worker each open one) could slip a command in between them.
  T exclusive<T>(T Function() body);

  void close();
}
