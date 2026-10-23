// Fans module domain (pure Dart): configuration for each AL V2 hub group
// and the module ports.

/// AL V2 hub groups (physical ports).
const fanGroupCount = 4;

/// Temperature followed by the curve: CPU/GPU, or a motherboard sensor
/// (IT8689E/IT8792E, names from protocol notes §2.5).
enum FanTempSource {
  cpuTctl,
  gpuJunction,
  gpuEdge,
  boardSystem1,
  boardSystem2,
  boardPch,
  boardCpuSocket,
  boardVrm,
  boardPciex16,
  boardPciex4;

  bool get isBoard => !const {cpuTctl, gpuJunction, gpuEdge}.contains(this);
}
