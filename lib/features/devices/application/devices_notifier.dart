import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/isolate_engine.dart';
import '../domain/device_snapshot.dart';
import 'rescan_devices.dart';
import 'devices_changed.dart';

/// Last scan received from the engine (`null` until the first scan).
class DevicesNotifier extends Notifier<DeviceSnapshot?> {
  @override
  DeviceSnapshot? build() {
    final engine = ref.watch(engineProvider);
    final sub = engine.events.listen((e) {
      if (e is DevicesChanged) state = e.snapshot;
    });
    ref.onDispose(sub.cancel);
    return engine.lastEvent<DevicesChanged>()?.snapshot;
  }

  void rescan() => ref.read(engineProvider).send(const RescanDevices());
}

final devicesProvider = NotifierProvider<DevicesNotifier, DeviceSnapshot?>(
  DevicesNotifier.new,
);
