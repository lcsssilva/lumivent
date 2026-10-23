/// Frames one family sent in the last second and their mean send time.
class LoopStats {
  const LoopStats({required this.fps, required this.sendMs});
  final double fps;

  /// `null` when no frame went out (nothing changed, or the family is off).
  final double? sendMs;

  @override
  bool operator ==(Object other) =>
      other is LoopStats && other.fps == fps && other.sendMs == sendMs;

  @override
  int get hashCode => Object.hash(fps, sendMs);

  @override
  String toString() => 'LoopStats($fps fps, $sendMs ms)';
}
