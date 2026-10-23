import 'ssd.dart';

class SsdSmartError {
  const SsdSmartError(this.kind, {this.message, this.exitCode, this.stderr});
  final SsdErrorKind kind;
  final String? message;
  final int? exitCode;
  final String? stderr;
}
