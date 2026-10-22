import '../domain/light_device.dart';
import '../domain/lighting_config.dart';
import 'lighting_frame_deduplicator.dart';

/// Compares two integer lists by value (config lists are new instances after
/// every config change).
bool sameInts(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// What the hardware currently holds: the resolved signatures per device and
/// per pseudo-slot, plus the fan quantity/merge state.
///
/// Every write path compares the requested signature with [changed] first and
/// records it with [apply] after a successful write; the `forget*` methods
/// drop the signatures the hardware may have lost (with the frame colors, so
/// the next frame is complete).
class LightingHardwareState {
  LightingHardwareState(this._deduplicator);

  final LightingFrameDeduplicator _deduplicator;

  /// Key of the merge pseudo-slot (the hub's unused group-0 config).
  static const mergeKey = 'merge';

  /// Key of the group-0-off pseudo-slot.
  static const group0Key = 'group0';

  final _applied = <Object, Object?>{};

  // Fan housekeeping the writers update alongside the signatures.

  /// Quantity the hardware holds; changed quantities resend every port
  /// (AL-V2 §4).
  List<int>? appliedQuantity;

  /// Merge order the hub holds; `initFans` resets it to
  /// [LightingConfig.defaultMergeOrder].
  List<int>? appliedMergeOrder;

  /// Whether the hub merges the fan groups (canvas frames are suppressed
  /// while it does).
  bool fanMerged = false;

  /// Ports per hub group the hardware must hold: group 0 stays 0.
  static List<int> quantityOf(LightingConfig c) => [
    0,
    ...c.fanQuantity.skip(1),
  ];

  /// Whether [key] is not applied at all or applied with another [signature].
  bool changed(Object key, Object? signature) =>
      !_applied.containsKey(key) || _applied[key] != signature;

  /// Records [signature] as what the hardware holds for [key].
  void apply(Object key, Object? signature) => _applied[key] = signature;

  /// Drops one signature (the write that follows is complete again).
  void forget(Object key) => _applied.remove(key);

  /// Drops the last sent colors of [id], so the next frame goes out even when
  /// equal (needed after a mode write overwrites the colors, or when a frame
  /// reply may not describe the hardware anymore).
  void forgetFrameColors(LightDeviceId id) => _deduplicator.forget(id);

  /// Drops the GPU single-color state (the hardware holds a mode, not the
  /// last frame color).
  void forgetGpuFrameColors() => _deduplicator.forgetGpu();

  /// Fades the fan groups (and the merge state with them).
  void forgetFans() {
    for (final id in LightDeviceId.values.where((d) => d.isFan)) {
      _applied.remove(id);
      _deduplicator.forget(id);
    }
    _applied
      ..remove(mergeKey)
      ..remove(group0Key);
    fanMerged = false;
  }

  /// Fades the ITE zones and case strip.
  void forgetBoard() {
    for (final z in boardZoneIds) {
      _applied.remove(z);
    }
    _deduplicator
      ..forget(LightDeviceId.motherboard)
      ..forget(LightDeviceId.chassis);
  }

  /// Fades the GPU mode (and its single-color frame).
  void forgetGpu() {
    _applied.remove(LightDeviceId.gpu);
    _deduplicator
      ..forget(LightDeviceId.gpu)
      ..forgetGpu();
  }

  /// Drops only the hardware-mode signatures, keeping quantities and canvas
  /// frames: the next reconcile writes the modes again (safety resend).
  void forgetHardwareModes() {
    for (final id in LightDeviceId.values.where((d) => d.isFan)) {
      _applied.remove(id);
    }
    _applied.remove(mergeKey);
    for (final z in boardZoneIds) {
      _applied.remove(z);
    }
    _applied.remove(LightDeviceId.gpu);
  }
}
