part of 'light_io_command.dart';

/// 12 LEDs of a stick: [rgb] are 36 bytes.
class IoRam extends DroppableIoCommand {
  const IoRam(this.slot, this.rgb);
  final int slot;
  final Uint8List rgb;
}
