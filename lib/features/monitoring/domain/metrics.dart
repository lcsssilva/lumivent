import 'dart:async';

// Monitoring module domain: what sensors measure.
//
// Each reading is a `metric ID → value` map for transport between isolates
// and for other phases to reuse (fans temperature source in phase 3,
// `getSensorValue` in phase 5 effects). Values are already in [MetricUnit].

enum MetricUnit { celsius, percent, megahertz, rpm, watts, bytes }

class MetricDef {
  const MetricDef(this.id, this.label, this.unit);
  final String id;
  final String label;
  final MetricUnit unit;
}

/// Metric IDs.
abstract final class Metrics {
  // CPU (k10temp, cpufreq, /proc/stat)
  static const cpuTctl = 'cpu.tctl';
  static const cpuTccd1 = 'cpu.tccd1';
  static const cpuClock = 'cpu.clock';
  static const cpuUsage = 'cpu.usage';

  // GPU (hwmon amdgpu + device sysfs)
  static const gpuEdge = 'gpu.edge';
  static const gpuJunction = 'gpu.junction';
  static const gpuMem = 'gpu.mem';
  static const gpuUsage = 'gpu.usage';
  static const gpuClock = 'gpu.clock';
  static const gpuFan = 'gpu.fan';
  static const gpuPower = 'gpu.power';
  static const gpuVramUsed = 'gpu.vram.used';
  static const gpuVramTotal = 'gpu.vram.total';

  // Memory (/proc/meminfo; per-module temperature through spd5118)
  static const memUsed = 'mem.used';
  static const memTotal = 'mem.total';
  static String dimmTemp(int slot) => 'mem.dimm$slot';

  /// RPM of an AL V2 hub group (0–3).
  static String alv2Rpm(int group) => 'alv2.g$group';

  /// Composite temperature of an SSD (`nvme0`, `nvme1`…).
  static String ssdTemp(String controller) => 'ssd.$controller';

  // Board temperature IDs, named so consumers do not depend on the position
  // in [boardTemps].
  static const boardSystem1 = 'board.system1';
  static const boardPch = 'board.pch';
  static const boardCpuSocket = 'board.cpu';
  static const boardPciex16 = 'board.pciex16';
  static const boardVrm = 'board.vrm';
  static const boardPciex4 = 'board.pciex4';
  static const boardSystem2 = 'board.system2';

  /// Board temperatures, in the order of the protocol notes
  /// (§2.5): 0–5 on IT8689E, 6–8 on IT8792E.
  static const boardTemps = [
    MetricDef(boardSystem1, 'System 1', MetricUnit.celsius),
    MetricDef(boardPch, 'PCH', MetricUnit.celsius),
    MetricDef(boardCpuSocket, 'CPU (socket)', MetricUnit.celsius),
    MetricDef(boardPciex16, 'PCIEX16', MetricUnit.celsius),
    MetricDef(boardVrm, 'VRM MOS', MetricUnit.celsius),
    MetricDef('board.ec1', 'EC_TEMP1', MetricUnit.celsius),
    MetricDef(boardPciex4, 'PCIEX4', MetricUnit.celsius),
    MetricDef('board.ec2', 'EC_TEMP2', MetricUnit.celsius),
    MetricDef(boardSystem2, 'System 2', MetricUnit.celsius),
  ];

  /// Read-only motherboard fan connectors, in protocol notes §2.5 order: 0–4 on IT8689E,
  /// 5–7 on IT8792E. The AIO pump is on CPU_FAN.
  static const boardFans = [
    MetricDef('board.fan.cpu', 'Pump (CPU_FAN)', MetricUnit.rpm),
    MetricDef('board.fan.sys1', 'System 1', MetricUnit.rpm),
    MetricDef('board.fan.sys2', 'System 2', MetricUnit.rpm),
    MetricDef('board.fan.sys3', 'System 3', MetricUnit.rpm),
    MetricDef('board.fan.cpuopt', 'CPU OPT', MetricUnit.rpm),
    MetricDef('board.fan.sys5pump', 'System 5 Pump', MetricUnit.rpm),
    MetricDef('board.fan.sys6pump', 'System 6 Pump', MetricUnit.rpm),
    MetricDef('board.fan.sys4', 'System 4', MetricUnit.rpm),
  ];
}

/// A reading of all sensors. Missing metric = no reading now.
class SensorSample {
  const SensorSample(this.at, this.values);
  final DateTime at;
  final Map<String, double> values;

  double? operator [](String id) => values[id];
}

/// Immutable circular history: [added] returns a new history with at most
/// [capacity] readings (5 minutes at 1 second by default).
class SensorHistory {
  const SensorHistory({
    this.capacity = defaultCapacity,
    this.samples = const [],
  });

  /// The last [capacity] readings from [samples] (oldest to newest).
  factory SensorHistory.from(
    List<SensorSample> samples, {
    int capacity = defaultCapacity,
  }) => SensorHistory(
    capacity: capacity,
    samples: List.unmodifiable(
      samples.length > capacity
          ? samples.sublist(samples.length - capacity)
          : samples,
    ),
  );

  static const defaultCapacity = 300;

  final int capacity;

  /// Oldest to newest.
  final List<SensorSample> samples;

  SensorSample? get latest => samples.lastOrNull;

  SensorHistory added(SensorSample sample) {
    final keep = samples.length >= capacity
        ? samples.sublist(samples.length - capacity + 1)
        : samples;
    return SensorHistory(
      capacity: capacity,
      samples: List.unmodifiable([...keep, sample]),
    );
  }

  /// Values for [id] in order, with `null` where there was no reading.
  List<double?> series(String id) => [for (final s in samples) s[id]];

  /// Has the metric ever been read in history?
  bool seen(String id) => samples.any((s) => s.values.containsKey(id));

  /// Is any reading of [id] above zero (fan connected)?
  bool everPositive(String id) => samples.any((s) => (s[id] ?? 0) > 0);
}

/// Port: a sensor source (sysfs, AL V2 hub…). Runs in the engine.
abstract interface class SensorSource {
  /// Current reading. May return fewer metrics if something disappears.
  Map<String, double> read();

  /// Releases the source. May be asynchronous (a source backed by a worker
  /// isolate); the engine waits for it before it reports it has stopped.
  FutureOr<void> dispose();
}
