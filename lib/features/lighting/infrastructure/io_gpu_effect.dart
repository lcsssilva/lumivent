part of 'light_io_command.dart';

/// GPU firmware effect (hardware mode).
class IoGpuEffect extends LightIoCommand {
  const IoGpuEffect(this.config);
  final GpuHardwareConfig config;
}
