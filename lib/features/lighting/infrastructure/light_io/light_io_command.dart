import 'dart:typed_data';

import '../../domain/hardware_mode/gpu_hardware_config.dart';
import '../../domain/config/board_zone_config.dart';

part 'droppable_io_command.dart';
part 'priority_io_command.dart';
part 'io_init_board.dart';
part 'io_chassis.dart';
part 'io_board_colors.dart';
part 'io_zone_effects.dart';
part 'io_board_off.dart';
part 'io_ram.dart';
part 'io_ram_off.dart';
part 'io_init_gpu.dart';
part 'io_gpu_static.dart';
part 'io_gpu_effect.dart';
part 'io_gpu_off.dart';
part 'io_invalidate.dart';
part 'io_close.dart';

/// Command for the worker. Every field is sendable between isolates.
sealed class LightIoCommand {
  const LightIoCommand();
}
