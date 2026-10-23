// Unprivileged sensors: hwmon, cpufreq, /proc/stat, and /proc/meminfo
// (protocol notes §2.5 and §5). Runs
// in the engine isolate every 1 second; only small files are read.
import 'dart:io';

import '../domain/metrics.dart';
import '../domain/sensor_source.dart';
import 'hwmon.dart';

class SysfsSensorSource implements SensorSource {
  SysfsSensorSource({
    this.sysfsRoot = '/sys',
    this.procRoot = '/proc',
    this.rescanEvery = 10,
  });

  final String sysfsRoot;
  final String procRoot;

  /// Rebuilds the hwmon chip list every N readings (modules can be
  /// loaded while the app is open).
  final int rescanEvery;

  List<Hwmon> _hwmons = const [];
  int _reads = 0;
  ({int idle, int total})? _lastCpu;

  @override
  Map<String, double> read() {
    if (_reads++ % rescanEvery == 0) _hwmons = _scanHwmon();
    final out = <String, double>{};
    final dimms = <Hwmon>[];
    Hwmon? gpu;
    for (final hw in _hwmons) {
      switch (hw.name) {
        case 'k10temp':
          _readCpuTemps(hw, out);
        case 'amdgpu':
          // With an active iGPU there are two amdgpu devices: keep the one with more VRAM (the discrete GPU).
          if (gpu == null || _vramTotal(hw) > _vramTotal(gpu)) gpu = hw;
        case 'it8689':
          _readBoard(hw, out, tempOffset: 0, temps: 6, fanOffset: 0, fans: 5);
        case 'it8792':
          _readBoard(hw, out, tempOffset: 6, temps: 3, fanOffset: 5, fans: 3);
        case 'spd5118':
          dimms.add(hw);
        case 'nvme':
          final ctrl = RegExp(r'/nvme/(nvme\d+)$')
              .firstMatch(hw.device)
              ?.group(1);
          final t = _num('${hw.path}/temp1_input');
          if (ctrl != null && t != null) out[Metrics.ssdTemp(ctrl)] = t / 1000;
      }
    }
    if (gpu != null) _readGpu(gpu, out);
    // Each module's SPD hub (0x51, 0x53…): address order determines the slot.
    dimms.sort((a, b) => a.device.compareTo(b.device));
    for (final (i, hw) in dimms.indexed) {
      final t = _num('${hw.path}/temp1_input');
      if (t != null) out[Metrics.dimmTemp(i + 1)] = t / 1000;
    }
    _readCpuClock(out);
    _readCpuUsage(out);
    _readMemory(out);
    return out;
  }

  @override
  void dispose() {}

  List<Hwmon> _scanHwmon() {
    final dir = Directory('$sysfsRoot/class/hwmon');
    if (!dir.existsSync()) return const [];
    final out = <Hwmon>[];
    for (final e in dir.listSync()) {
      final name = _str('${e.path}/name');
      if (name == null) continue;
      String device;
      try {
        device = Directory('${e.path}/device').resolveSymbolicLinksSync();
      } on FileSystemException {
        device = '';
      }
      out.add(Hwmon(name, e.path, device));
    }
    out.sort((a, b) => a.path.compareTo(b.path));
    return out;
  }

  void _readCpuTemps(Hwmon hw, Map<String, double> out) {
    for (final (label, t) in _labeledTemps(hw)) {
      switch (label) {
        case 'Tctl':
          out[Metrics.cpuTctl] = t;
        case 'Tccd1':
          out[Metrics.cpuTccd1] = t;
      }
    }
  }

  double _vramTotal(Hwmon hw) =>
      _num('${hw.path}/device/mem_info_vram_total') ?? 0;

  void _readGpu(Hwmon hw, Map<String, double> out) {
    for (final (label, t) in _labeledTemps(hw)) {
      final id = switch (label) {
        'edge' => Metrics.gpuEdge,
        'junction' => Metrics.gpuJunction,
        'mem' => Metrics.gpuMem,
        _ => null,
      };
      if (id != null) out[id] = t;
    }
    final fan = _num('${hw.path}/fan1_input');
    if (fan != null) out[Metrics.gpuFan] = fan;
    // RDNA3+ exposes power1_average; some versions only expose power1_input (µW).
    final power =
        _num('${hw.path}/power1_average') ?? _num('${hw.path}/power1_input');
    if (power != null) out[Metrics.gpuPower] = power / 1e6;
    final sclk = _num('${hw.path}/freq1_input');
    if (sclk != null) out[Metrics.gpuClock] = sclk / 1e6;
    final busy = _num('${hw.path}/device/gpu_busy_percent');
    if (busy != null) out[Metrics.gpuUsage] = busy;
    final used = _num('${hw.path}/device/mem_info_vram_used');
    final total = _num('${hw.path}/device/mem_info_vram_total');
    if (used != null && total != null && total > 0) {
      out[Metrics.gpuVramUsed] = used;
      out[Metrics.gpuVramTotal] = total;
    }
  }

  /// Super I/O: fixed indexes (it87 provides no labels). −55 °C or 127 °C =
  /// input without a sensor.
  void _readBoard(
    Hwmon hw,
    Map<String, double> out, {
    required int tempOffset,
    required int temps,
    required int fanOffset,
    required int fans,
  }) {
    for (var i = 0; i < temps; i++) {
      final t = _num('${hw.path}/temp${i + 1}_input');
      if (t != null && t > -40000 && t < 127000) {
        out[Metrics.boardTemps[tempOffset + i].id] = t / 1000;
      }
    }
    for (var i = 0; i < fans; i++) {
      final rpm = _num('${hw.path}/fan${i + 1}_input');
      if (rpm != null) out[Metrics.boardFans[fanOffset + i].id] = rpm;
    }
  }

  /// `(label, °C)` for each `tempN_input` with `tempN_label`.
  Iterable<(String, double)> _labeledTemps(Hwmon hw) sync* {
    for (var i = 1; i <= 8; i++) {
      final label = _str('${hw.path}/temp${i}_label');
      if (label == null) continue;
      final t = _num('${hw.path}/temp${i}_input');
      if (t != null) yield (label, t / 1000);
    }
  }

  /// Average clock of all cores (cpufreq, kHz).
  void _readCpuClock(Map<String, double> out) {
    final dir = Directory('$sysfsRoot/devices/system/cpu');
    if (!dir.existsSync()) return;
    var sum = 0.0, n = 0;
    for (final e in dir.listSync()) {
      if (!RegExp(r'/cpu\d+$').hasMatch(e.path)) continue;
      final khz = _num('${e.path}/cpufreq/scaling_cur_freq');
      if (khz == null) continue;
      sum += khz;
      n++;
    }
    if (n > 0) out[Metrics.cpuClock] = sum / n / 1000;
  }

  /// Total usage since the previous reading (linha `cpu` do /proc/stat).
  void _readCpuUsage(Map<String, double> out) {
    final line = _str('$procRoot/stat')?.split('\n').first;
    if (line == null || !line.startsWith('cpu ')) return;
    final f = line
        .split(RegExp(r'\s+'))
        .skip(1)
        .map(int.tryParse)
        .whereType<int>()
        .toList();
    if (f.length < 8) return;
    // user nice system idle iowait irq softirq steal (guest is already in user).
    final idle = f[3] + f[4];
    final total = f.take(8).reduce((a, b) => a + b);
    final last = _lastCpu;
    _lastCpu = (idle: idle, total: total);
    if (last == null || total <= last.total) return;
    final busy = 1 - (idle - last.idle) / (total - last.total);
    out[Metrics.cpuUsage] = (busy * 100).clamp(0, 100).toDouble();
  }

  void _readMemory(Map<String, double> out) {
    final text = _str('$procRoot/meminfo');
    if (text == null) return;
    int? kb(String key) => int.tryParse(
      RegExp(
            '^$key:\\s+(\\d+) kB',
            multiLine: true,
          ).firstMatch(text)?.group(1) ??
          '',
    );
    final total = kb('MemTotal');
    final available = kb('MemAvailable');
    if (total == null || available == null) return;
    out[Metrics.memTotal] = total * 1024.0;
    out[Metrics.memUsed] = (total - available) * 1024.0;
  }

  static String? _str(String path) {
    try {
      return File(path).readAsStringSync().trim();
    } on FileSystemException {
      return null;
    }
  }

  static double? _num(String path) {
    final s = _str(path);
    return s == null ? null : double.tryParse(s);
  }
}
