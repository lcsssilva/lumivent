import 'protocol.dart';

class IteForbiddenCommand implements Exception {
  IteForbiddenCommand(this.command, [String? reason])
    : reason = reason ?? iteForbiddenCommands[command] ?? 'forbidden';
  final int command;
  final String reason;
  @override
  String toString() =>
      'CC ${command.toRadixString(16).padLeft(2, '0').toUpperCase()} packet blocked: $reason';
}
