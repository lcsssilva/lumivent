import 'dart:async';

import '../../../core/engine/engine_command.dart';
import '../../../core/engine/engine_event.dart';
import '../../../core/engine/engine_module.dart';
import '../domain/device_detector.dart';
import 'rescan_devices.dart';
import 'devices_changed.dart';

/// Devices module part that runs in the engine: initial scan, connection
/// polling every [poll], and on-demand scans.
class DevicesEngineModule implements EngineModule {
  DevicesEngineModule(this._open, {this.poll = const Duration(seconds: 5)});

  /// Opens the detector inside the engine isolate (FFI handles must not
  /// cross isolates).
  final DeviceDetector Function() _open;
  final Duration poll;

  late final DeviceDetector _detector;
  late void Function(EngineEvent) _emit;
  String? _presence;
  Timer? _timer;

  @override
  void start(void Function(EngineEvent) emit) {
    _emit = emit;
    _detector = _open();
    _scan();
    _timer = Timer.periodic(poll, (_) {
      if (_detector.presenceKey() != _presence) _scan();
    });
  }

  @override
  bool handle(EngineCommand command) {
    if (command is! RescanDevices) return false;
    _scan();
    return true;
  }

  void _scan() {
    _presence = _detector.presenceKey();
    _emit(DevicesChanged(_detector.scan()));
  }

  @override
  void stop() {
    _timer?.cancel();
    _detector.dispose();
  }
}
