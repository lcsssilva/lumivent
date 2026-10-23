/// `CC 60` calibration (ITE §1.3): CalStrip3, 0, 1, 2, ChipId, CalStrip4.
class IteCalibration {
  const IteCalibration({
    required this.strip3,
    required this.strip0,
    required this.strip1,
    required this.strip2,
    required this.chipId,
    required this.strip4,
  });

  final int strip3, strip0, strip1, strip2, chipId, strip4;
}
