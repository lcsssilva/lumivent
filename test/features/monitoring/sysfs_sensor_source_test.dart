import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/features/monitoring/infrastructure/sysfs_sensor_source.dart';
import 'package:lumivent/features/monitoring/monitoring.dart';

void main() {
  late Directory root;
  late String sys, proc;
  setUp(() {
    root = Directory.systemTemp.createTempSync('lumivent-sensors-');
    sys = '${root.path}/sys';
    proc = '${root.path}/proc';
  });
  tearDown(() => root.deleteSync(recursive: true));

  void write(String path, String content) => (File(
    '${root.path}/$path',
  )..createSync(recursive: true)).writeAsStringSync('$content\n');

  /// hwmon with `device` pointing to [device] (as in the real sysfs).
  void hwmon(int n, String name, String device, Map<String, Object> files) {
    write('sys/class/hwmon/hwmon$n/name', name);
    Directory('${root.path}/sys/$device').createSync(recursive: true);
    Link('$sys/class/hwmon/hwmon$n/device').createSync('$sys/$device');
    files.forEach((k, v) => write('sys/class/hwmon/hwmon$n/$k', '$v'));
  }

  void stat(List<int> f) =>
      write('proc/stat', 'cpu  ${f.join(' ')} 0 0\ncpu0 1 2 3');

  test('reads CPU, GPU, motherboard, modules, SSD, memory, and CPU usage', () {
    hwmon(5, 'k10temp', 'devices/pci0/0000:00:18.3', {
      'temp1_label': 'Tctl',
      'temp1_input': 54250,
      'temp3_label': 'Tccd1',
      'temp3_input': 44000,
    });
    hwmon(2, 'amdgpu', 'devices/pci0/0000:03:00.0', {
      'temp1_label': 'edge',
      'temp1_input': 46000,
      'temp2_label': 'junction',
      'temp2_input': 49000,
      'temp3_label': 'mem',
      'temp3_input': 66000,
      'fan1_input': 0,
      'power1_average': 19000000,
      'freq1_input': 2100000000,
    });
    write('sys/devices/pci0/0000:03:00.0/gpu_busy_percent', '12');
    write('sys/devices/pci0/0000:03:00.0/mem_info_vram_used', '846073856');
    write('sys/devices/pci0/0000:03:00.0/mem_info_vram_total', '17095983104');
    // iGPU with little VRAM: ignored.
    hwmon(11, 'amdgpu', 'devices/pci0/0000:12:00.0', {
      'temp1_label': 'edge',
      'temp1_input': 30000,
    });
    write('sys/devices/pci0/0000:12:00.0/mem_info_vram_total', '536870912');
    hwmon(3, 'it8689', 'devices/platform/it87.2624', {
      'temp1_input': 37000,
      'temp2_input': 46000,
      'temp3_input': 54000,
      'temp4_input': 44000,
      'temp5_input': 42000,
      'temp6_input': -55000,
      'fan1_input': 2051,
      'fan2_input': 0,
    });
    hwmon(4, 'it8792', 'devices/platform/it87.2656', {
      'temp1_input': 39000,
      'temp2_input': -55000,
      'temp3_input': 39000,
      'fan3_input': 900,
    });
    hwmon(7, 'spd5118', 'devices/pci0/0000:00:14.0/i2c-10/10-0053', {
      'temp1_input': 47750,
    });
    hwmon(6, 'spd5118', 'devices/pci0/0000:00:14.0/i2c-10/10-0051', {
      'temp1_input': 48250,
    });
    hwmon(1, 'nvme', 'devices/pci0/0000:04:00.0/nvme/nvme0', {
      'temp1_input': 40850,
    });
    hwmon(9, 'hidpp_battery_0', 'devices/usb/x', {'in0_input': 4142});
    for (final (i, khz) in [4800000, 4600000, 2991546].indexed) {
      write('sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq', '$khz');
    }
    write('sys/devices/system/cpu/cpufreq/policy0/scaling_cur_freq', '1');
    write(
      'proc/meminfo',
      'MemTotal:       32455064 kB\nMemFree: 1 kB\nMemAvailable:   22844148 kB',
    );
    stat([100, 0, 100, 700, 100, 0, 0, 0]);

    final source = SysfsSensorSource(sysfsRoot: sys, procRoot: proc);
    final v = source.read();
    expect(v[Metrics.cpuTctl], 54.25);
    expect(v[Metrics.cpuTccd1], 44);
    expect(
      v[Metrics.cpuClock],
      closeTo((4800000 + 4600000 + 2991546) / 3 / 1000, 1e-9),
    );
    expect(
      v.containsKey(Metrics.cpuUsage),
      isFalse,
      reason: 'precisa de duas leituras',
    );
    expect(v[Metrics.gpuEdge], 46);
    expect(v[Metrics.gpuJunction], 49);
    expect(v[Metrics.gpuMem], 66);
    expect(v[Metrics.gpuFan], 0);
    expect(v[Metrics.gpuPower], 19);
    expect(v[Metrics.gpuClock], 2100);
    expect(v[Metrics.gpuUsage], 12);
    expect(v[Metrics.gpuVramTotal], 17095983104);
    expect(v['board.system1'], 37);
    expect(v['board.cpu'], 54);
    expect(v['board.vrm'], 42);
    expect(v.containsKey('board.ec1'), isFalse, reason: '−55 °C = no sensor');
    expect(v['board.pciex4'], 39);
    expect(v.containsKey('board.ec2'), isFalse);
    expect(v['board.system2'], 39);
    expect(v['board.fan.cpu'], 2051);
    expect(v['board.fan.sys1'], 0);
    expect(v['board.fan.sys4'], 900);
    expect(v[Metrics.dimmTemp(1)], 48.25, reason: '0x51 is memory module 1');
    expect(v[Metrics.dimmTemp(2)], 47.75);
    expect(v[Metrics.ssdTemp('nvme0')], 40.85);
    expect(v[Metrics.memTotal], 32455064 * 1024);
    expect(v[Metrics.memUsed], (32455064 - 22844148) * 1024);

    // +100 ocioso e +100 ocupado → 50 %.
    stat([150, 0, 150, 780, 120, 0, 0, 0]);
    expect(source.read()[Metrics.cpuUsage], 50);
  });

  test('empty sysfs does not crash', () {
    expect(SysfsSensorSource(sysfsRoot: sys, procRoot: proc).read(), isEmpty);
  });
}
