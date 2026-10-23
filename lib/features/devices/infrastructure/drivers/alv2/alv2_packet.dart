/// Ready packet: [output] says whether it goes via output report (colors) or
/// feature. With [pad] false an output report is written with its real size
/// instead of the full 353 bytes (canvas streaming only).
class Alv2Packet {
  const Alv2Packet(this.bytes, {this.output = false, this.pad = true});
  final List<int> bytes;
  final bool output;
  final bool pad;
}
