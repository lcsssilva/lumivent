import 'ite_color_order.dart';
import 'ite_calibration.dart';

/// Part of the `CC 60` response (`IT8297_Info`, ITE §1.2).
class IteInfo {
  const IteInfo({
    required this.firmware,
    required this.description,
    this.calibration,
  });

  /// `4.0.23.0`: bytes 4..7.
  final String firmware;

  /// `IT5701-GIGABYTE V4.0.23.0`: ASCII of bytes 12..39.
  final String description;

  /// `null` if the response came back too short.
  final IteCalibration? calibration;

  /// D_LED1 color order (CalStrip0); GRB without calibration.
  IteColorOrder get stripOrder => calibration == null
      ? IteColorOrder.grb
      : IteColorOrder.fromCalStrip(calibration!.strip0, IteColorOrder.grb);

  /// Board zone color order (CalStrip3); BGR without calibration.
  IteColorOrder get zoneOrder => calibration == null
      ? IteColorOrder.bgr
      : IteColorOrder.fromCalStrip(calibration!.strip3, IteColorOrder.bgr);
}
