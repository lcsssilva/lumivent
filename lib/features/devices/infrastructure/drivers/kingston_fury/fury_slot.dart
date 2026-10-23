part of 'fury_controller.dart';

class _FurySlot {
  _Mode mode = _Mode.none;
  bool ready = false; // guard + identity completed during this opening
  String? disabledReason; // permanent for this session
  List<int>? cache; // last 36 bytes sent
  List<int>? single; // last single color
}
