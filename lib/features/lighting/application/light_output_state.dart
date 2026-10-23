import 'light_output_status.dart';

enum LightOutputState {
  /// Last write accepted by the device.
  ok,

  /// Device absent, no permission, or blocked by a guard.
  unavailable,

  /// No driver yet (kept for the UI; all current devices have one).
  unsupported,
}

/// Why a device has no output. The presentation maps the index to the catalog
/// (`LightingStrings.outputIssue`); [LightOutputStatus.args] carries details.
enum LightOutputIssue {
  /// No driver for this device yet.
  unsupported,

  /// AL V2 hub absent or without permission.
  hub,

  /// Motherboard ITE controller absent or without permission.
  ite,

  /// GPU RGB controller absent or without permission.
  gpu,

  /// Kingston Fury memory absent or without SMBus permission.
  ram,

  /// A safety guard blocked the write; the reason is in the args.
  blocked,
}

/// Output families with their own send latency and frame lane (see
/// `LightingEngineModule.latencyOf`).
enum OutputFamily {
  /// AL V2 hub: asynchronous canvas frame, ports arrive over the whole send.
  fans,

  /// ITE controller (case strip and motherboard zones): HID in the I/O worker.
  ite,

  /// Kingston Fury sticks: SMBus in the I/O worker.
  ram,

  /// Gigabyte GPU: I²C in the I/O worker, one effect every 120 ms at most.
  gpu,
}
