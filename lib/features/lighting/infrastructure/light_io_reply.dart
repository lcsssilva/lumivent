class LightIoReply {
  const LightIoReply(
    this.id,
    this.ok,
    this.micros, {
    this.dropped = false,
    this.ramReasons,
    this.gpuReason,
  });

  /// Reply for a command that could not reach the worker.
  const LightIoReply.failed(this.id)
    : ok = false,
      micros = 0,
      dropped = false,
      ramReasons = null,
      gpuReason = null;

  final int id;
  final bool ok;

  /// Time the worker spent running the command.
  final int micros;

  /// Discarded before running because a priority command overtook it.
  final bool dropped;

  /// Why each Fury slot is disabled (`null` = usable), set on RAM replies.
  final List<String?>? ramReasons;

  /// Why the GPU is disabled (`null` = usable), set on GPU replies.
  final String? gpuReason;
}
