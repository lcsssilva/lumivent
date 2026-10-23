import 'dev_access.dart';

class RawI2cException implements Exception {
  RawI2cException(this.message, this.errno);
  final String message;
  final int errno;
  bool get permissionDenied => isPermissionDeniedErrno(errno);
  @override
  String toString() => 'RawI2cException: $message (errno $errno)';
}
