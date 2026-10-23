part of '../main_spike.dart';

class _SpikeStats {
  int frames = 0, ops = 0;
  Duration script = Duration.zero,
      raster = Duration.zero,
      readback = Duration.zero;

  void add(IsolatedHtmlEffectRuntime rt, Duration rb) {
    frames++;
    ops += rt.lastOpCount;
    script += rt.lastScriptTime;
    raster += rt.lastRasterTime;
    readback += rb;
  }

  String ms(Duration d) =>
      frames == 0 ? '-' : (d.inMicroseconds / frames / 1000).toStringAsFixed(2);

  @override
  String toString() =>
      '$frames quadros · ops/quadro ${frames == 0 ? 0 : ops ~/ frames} · '
      'js ${ms(script)} ms · raster ${ms(raster)} ms · leitura ${ms(readback)} ms';
}
