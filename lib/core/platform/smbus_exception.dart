import 'dev_access.dart';

class SmbusException implements Exception {
  SmbusException(this.message, this.errno);
  final String message;
  final int errno;
  bool get permissionDenied => isPermissionDeniedErrno(errno);
  @override
  String toString() => 'SmbusException: $message (errno $errno)';
}
