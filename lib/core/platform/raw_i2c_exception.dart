part of 'raw_i2c_bus.dart';

class RawI2cException implements Exception {
  RawI2cException(this.message, this.errno);
  final String message;
  final int errno;
  bool get permissionDenied => errno == _eacces || errno == _eperm;
  @override
  String toString() => 'RawI2cException: $message (errno $errno)';
}
