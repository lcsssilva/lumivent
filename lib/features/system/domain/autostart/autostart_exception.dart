import 'autostart_error.dart';

/// A failed autostart operation. The UI translates [code] and shows the raw
/// command/stderr as technical detail.
class AutostartException implements Exception {
  AutostartException(this.code, {this.command = '', this.stderr = ''});
  final AutostartError code;
  final String command;
  final String stderr;
  @override
  String toString() => 'AutostartException(${code.name}: $command $stderr)';
}
