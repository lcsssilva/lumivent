part of 'light_io_command.dart';

/// Board zone colors in `boardZoneIds` order, 3 bytes each.
class IoBoardColors extends DroppableIoCommand {
  const IoBoardColors(this.rgb);
  final Uint8List rgb;
}
