import 'alv2_port_write.dart';

part 'hub_read_rpm.dart';
part 'hub_set_duty.dart';
part 'hub_set_motherboard_sync.dart';
part 'hub_set_quantity.dart';
part 'hub_set_merge_order.dart';
part 'hub_disable_argb_sync.dart';
part 'hub_send_lighting.dart';
part 'hub_stream_canvas.dart';
part 'hub_identify.dart';
part 'hub_dispose.dart';

/// Command for the worker. Every field is sendable between isolates.
sealed class Alv2HubCommand {
  const Alv2HubCommand();
}
