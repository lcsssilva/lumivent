part of 'light_io_command.dart';

/// Fixed-color mode of the GPU: Static with the global brightness byte.
class IoGpuStatic extends DroppableIoCommand {
  const IoGpuStatic(this.r, this.g, this.b, this.brightness);
  final int r, g, b, brightness;
}
