import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/lighting/application/frames/lighting_latency_model.dart';
import 'package:lumivent/features/lighting/application/status/light_output_state.dart';

void main() {
  test('latency estimates are clamped and converted to composition lead', () {
    final model = LightingLatencyModel();

    expect(
      model.latencyOf(OutputFamily.fans),
      const Duration(milliseconds: 45),
    );
    expect(
      model.leadSeconds(OutputFamily.fans, const Duration(milliseconds: 120)),
      0.195,
    );
    expect(
      model.leadSeconds(OutputFamily.gpu, const Duration(milliseconds: 120)),
      0.005,
    );

    model.observe(OutputFamily.fans, const Duration(seconds: 1));
    expect(
      model.latencyOf(OutputFamily.fans),
      const Duration(milliseconds: 150),
    );
    expect(
      model.leadSeconds(OutputFamily.fans, const Duration(milliseconds: 120)),
      0.3,
    );
  });
}
