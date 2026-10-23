import 'protocol.dart';
import 'alv2_packet.dart';

/// Full write of one port: colors (output, if any) and then the effect.
/// [colors] is already normalized (see `lighting.dart`), flat R,G,B.
class Alv2PortWrite {
  const Alv2PortWrite({
    required this.port,
    required this.mode,
    this.speed = 0x00,
    this.direction = 0x00,
    this.brightness = 0x00,
    this.colors,
  });

  final int port;
  final int mode, speed, direction, brightness;
  final List<int>? colors;

  /// Colors before the effect (service order, AL-V2 §4).
  List<Alv2Packet> get packets => [
    if (colors != null && colors!.isNotEmpty)
      Alv2Packet(alv2ColorPacket(port, colors!), output: true),
    Alv2Packet(alv2EffectPacket(port, mode, speed, direction, brightness)),
  ];
}
