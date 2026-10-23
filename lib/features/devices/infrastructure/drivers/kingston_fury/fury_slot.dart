enum FurySlotMode { none, direct, single }

class FurySlot {
  FurySlotMode mode = FurySlotMode.none;
  bool ready = false; // guard + identity completed during this opening
  String? disabledReason; // permanent for this session
  List<int>? cache; // last 36 bytes sent
  List<int>? single; // last single color
}
