import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/application/lighting_frame_deduplicator.dart';
import 'package:lumivent/features/lighting/application/lighting_hardware_state.dart';
import 'package:lumivent/features/lighting/domain/light_device.dart';
import 'package:lumivent/features/lighting/domain/lighting_config.dart';
import 'package:lumivent/features/lighting/domain/rgb.dart';

LightingFrameDeduplicator dedup = LightingFrameDeduplicator(
  const Duration(seconds: 5),
);

void main() {
  setUp(() {
    dedup = LightingFrameDeduplicator(const Duration(seconds: 5));
  });

  test('quantity has group 0 pinned to zero', () {
    final c = LightingConfig(fanQuantity: [1, 2, 3, 4]);
    expect(LightingHardwareState.quantityOf(c), [0, 2, 3, 4]);
  });

  test('changed applies per key and signature', () {
    final state = LightingHardwareState(dedup);
    expect(state.changed(LightDeviceId.gpu, 'mode'), isTrue);
    state.apply(LightDeviceId.gpu, 'mode');
    expect(state.changed(LightDeviceId.gpu, 'mode'), isFalse);
    expect(state.changed(LightDeviceId.gpu, 'off'), isTrue);
    state.apply(LightDeviceId.gpu, 'off');
    expect(state.changed(LightDeviceId.gpu, 'off'), isFalse);
  });

  test('forgetGpu drops the mode and the single-color frame', () {
    final state = LightingHardwareState(dedup);
    state.apply(LightDeviceId.gpu, 'mode');
    final at = DateTime(2026);
    dedup.recordGpu(const Rgb(1, 2, 3), 5, at);
    expect(dedup.shouldSendGpu(const Rgb(1, 2, 3), 5, at), isFalse);

    state.forgetGpu();
    expect(state.changed(LightDeviceId.gpu, 'mode'), isTrue);
    // The color would go out again after the mode write.
    expect(dedup.shouldSendGpu(const Rgb(1, 2, 3), 5, at), isTrue);
  });

  test('forgetBoard drops both ITE devices', () {
    final state = LightingHardwareState(dedup);
    final at = DateTime(2026);
    final boardId = LightDeviceId.motherboard;
    state.apply(boardId, 'mode');
    dedup.recordColors(boardId, [const Rgb(1, 2, 3)], at);
    dedup.forget(boardId);
    expect(state.changed(boardId, 'mode'), isFalse);
    expect(dedup.shouldSendColors(boardId, [const Rgb(1, 2, 3)], at), isTrue);

    state.forgetBoard();
    // The mode signature for the zone keys is per board zone id.
    expect(state.changed(0x20, 'mode'), isTrue);
    expect(
      dedup.shouldSendColors(LightDeviceId.chassis, [const Rgb(1, 2, 3)], at),
      isTrue,
    );
    expect(
      dedup.shouldSendColors(LightDeviceId.motherboard, [
        const Rgb(1, 2, 3),
      ], at),
      isTrue,
    );
  });

  test('forgetFans resets the merge state with the group signatures', () {
    final state = LightingHardwareState(dedup);
    state
      ..apply(LightDeviceId.alv2Group1, ('mode', null))
      ..apply(LightingHardwareState.mergeKey, ('merge', 'm', null))
      ..apply(LightingHardwareState.group0Key, 'merge')
      ..fanMerged = true
      ..appliedQuantity = [0, 1, 1, 0];

    state.forgetFans();
    expect(state.changed(LightDeviceId.alv2Group1, ('mode', null)), isTrue);
    expect(state.changed(LightingHardwareState.mergeKey, null), isTrue);
    expect(state.changed(LightingHardwareState.group0Key, null), isTrue);
    expect(state.fanMerged, isFalse);
    // Quantity is kept: the quantity write is separate from modes.
    expect(state.appliedQuantity, [0, 1, 1, 0]);
  });

  test('forgetHardwareModes keeps quantity and canvas colors', () {
    final state = LightingHardwareState(dedup);
    final at = DateTime(2026);
    state
      ..apply(LightDeviceId.alv2Group1, ('mode', null))
      ..apply(0x22, ('mode', null))
      ..apply(LightDeviceId.gpu, 'mode')
      ..appliedQuantity = [0, 2, 0, 0];
    dedup.recordColors(LightDeviceId.alv2Group1, [const Rgb(9, 9, 9)], at);

    state.forgetHardwareModes();
    expect(state.changed(LightDeviceId.alv2Group1, ('mode', null)), isTrue);
    expect(state.changed(0x22, ('mode', null)), isTrue);
    expect(state.changed(LightDeviceId.gpu, 'mode'), isTrue);
    expect(state.appliedQuantity, [0, 2, 0, 0]);
    // The canvas colors survive: unchanged frames are not resent (a hardware
    // send does not overwrite them).
    expect(
      dedup.shouldSendColors(LightDeviceId.alv2Group1, [
        const Rgb(9, 9, 9),
      ], at),
      isFalse,
    );
  });

  test('matching only the fan signatures, not the board ones', () {
    final state = LightingHardwareState(dedup);
    state.apply(0x20, ('mode', null));
    // A fan-group id and a board-zone id are distinct keys.
    expect(state.changed(LightDeviceId.motherboard, ('mode', null)), isTrue);
  });
}
