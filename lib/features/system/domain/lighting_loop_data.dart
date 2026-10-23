import 'diagnostic_data.dart';
import 'loop_sample.dart';

class LightingLoopData extends DiagnosticData {
  const LightingLoopData(this.loops);
  final List<LoopSample> loops;
}
