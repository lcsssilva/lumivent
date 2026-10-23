// SSD tool domain: NVMe SMART/Health 02h log and the health rule.

/// Health level (threshold 10).
enum SsdHealth {
  good,
  caution,
  bad;

  /// 0 → Poor; ≤ 10% → Caution; above that → Good.
  static SsdHealth fromLife(int life) => life <= 0
      ? bad
      : life <= 10
      ? caution
      : good;
}

/// Why SMART data is unavailable. [message], [exitCode], and [stderr] are
/// technical data from the helper; the UI composes the sentence.
enum SsdErrorKind {
  helperMissing,
  helperFailed,
  helperExit,
  invalidResponse,
  device,
}
