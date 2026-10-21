// Monitoring module domain: state of the GPU fan, read-only (plan §7b).
//
// The RX 9060 XT runs a factory curve with zero-fan: the fan stops at idle and
// starts at ~51–52 °C under load (`docs/hardware.md`). 0 RPM is normal
// then and must not look like a fault. The amdgpu driver here does not expose
// `gpu_od/fan_ctrl`, so the zero-fan state is inferred from RPM + junction.

enum GpuFanState {
  /// No fan reading.
  unknown,

  /// Fan turning.
  spinning,

  /// 0 RPM with the GPU cool: zero-fan at work.
  zeroFan,

  /// 0 RPM with the junction at [gpuFanStoppedHotC] or more: the factory curve
  /// would have started the fan long before, so something is wrong.
  stoppedHot,
}

/// Junction temperature above which a stopped fan is reported as a fault. The
/// fan was seen starting with the edge at 45–52 °C (junction a few degrees
/// higher), far below this.
const gpuFanStoppedHotC = 80.0;

GpuFanState gpuFanState({required double? rpm, required double? junction}) {
  if (rpm == null) return GpuFanState.unknown;
  if (rpm > 0) return GpuFanState.spinning;
  if (junction != null && junction >= gpuFanStoppedHotC) {
    return GpuFanState.stoppedHot;
  }
  return GpuFanState.zeroFan;
}
