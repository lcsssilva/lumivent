part of 'smbus.dart';

class SmbusException implements Exception {
  SmbusException(this.message, this.errno);
  final String message;
  final int errno;
  bool get permissionDenied => errno == _eacces || errno == _eperm;
  @override
  String toString() => 'SmbusException: $message (errno $errno)';
}
