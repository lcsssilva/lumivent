part of 'light_io_command.dart';

/// D_LED1 case strip: [rgb] are 47 x 3 bytes.
class IoChassis extends DroppableIoCommand {
  const IoChassis(this.rgb);
  final Uint8List rgb;
}
