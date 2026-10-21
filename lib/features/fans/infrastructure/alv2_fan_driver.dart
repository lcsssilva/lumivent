import '../../devices/devices.dart' show Alv2HubProxy;
import '../domain/fan_group.dart';

/// Fan output through the AL V2 hub (worker isolate). The protocol belongs to
/// the devices module.
class Alv2FanDriver implements FanDriver {
  Alv2FanDriver(this._hub);
  final Alv2HubProxy _hub;

  @override
  Future<bool> setDuty(int group, int duty) => _hub.setDuty(group, duty);

  @override
  Future<bool> disableMotherboardSync() =>
      _hub.setMotherboardSync(List.filled(fanGroupCount, false));
}
