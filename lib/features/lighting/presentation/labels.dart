// User-facing (pt-BR) names for the lighting screen. The domain keeps its own
// labels, but they are not guaranteed to be Portuguese, so the page owns these.

import '../domain/light_device.dart';
import '../domain/lighting_config.dart';

/// [fanNames]: names of the hub groups 0–3 (`fanGroupNamesProvider`).
String deviceLabel(LightDeviceId id, [List<String> fanNames = const []]) =>
    switch (id) {
      _ when id.isFan => 'Fans · ${fanGroupName(id.hubGroup!, fanNames)}',
      LightDeviceId.chassis => 'Gabinete',
      LightDeviceId.motherboard => 'Placa-mãe',
      LightDeviceId.ram1 => 'Memória 1',
      LightDeviceId.ram2 => 'Memória 2',
      LightDeviceId.gpu => 'Placa de vídeo',
      _ => id.label,
    };

/// Name of hub group [group] (0–3), "Grupo N" when unnamed.
String fanGroupName(int group, List<String> fanNames) {
  final name = group < fanNames.length ? fanNames[group].trim() : '';
  return name.isEmpty ? 'Grupo $group' : name;
}

String modeLabel(LightMode m) => switch (m) {
  LightMode.canvas => 'Canvas',
  LightMode.hardware => 'Hardware',
  LightMode.fixed => 'Cor fixa',
};

String effectLabel(String id, String fallback) => switch (id) {
  'solid' => 'Cor sólida',
  'spectrum' => 'Ciclo de cores',
  'rainbowWave' => 'Onda arco-íris',
  'breathing' => 'Respiração',
  'colorWave' => 'Onda de duas cores',
  'scanner' => 'Varredura',
  _ => fallback,
};

String paramLabel(String id, String fallback) => switch (id) {
  'speed' => 'Velocidade',
  'size' => 'Tamanho da onda',
  'direction' => 'Direção',
  'color' => 'Cor',
  'color2' => 'Cor 2',
  'background' => 'Fundo',
  'width' => 'Largura',
  _ => fallback,
};

String boardModeLabel(BoardEffectMode m) => switch (m) {
  BoardEffectMode.static => 'Estático',
  BoardEffectMode.pulse => 'Pulsar',
  BoardEffectMode.flash => 'Piscar',
  BoardEffectMode.doubleFlash => 'Piscar duplo',
  BoardEffectMode.colorCycle => 'Ciclo de cores',
  BoardEffectMode.wave => 'Onda',
};

String boardZoneLabel(int zone) => switch (zone) {
  0x20 => 'IO Shield 1',
  0x22 => 'LED da CPU',
  0x23 => 'IO Shield 2',
  _ => 'Zona $zone',
};

String gpuEffectLabel(GpuEffect effect) => switch (effect) {
  GpuEffect.off => 'Desligado',
  GpuEffect.staticColor => 'Estático',
  GpuEffect.pulse => 'Respiração',
  GpuEffect.flash => 'Flash',
  GpuEffect.doubleFlash => 'Flash duplo',
  GpuEffect.cycle => 'Ciclo de cores',
  GpuEffect.wave => 'Onda',
  GpuEffect.gradient => 'Gradiente',
  GpuEffect.colorShift => 'Troca de cores',
  GpuEffect.rainbow => 'Arco-íris',
  GpuEffect.tricolor => 'Três cores',
  GpuEffect.claws => 'Garras',
  GpuEffect.dazzle => 'Ofuscante',
};

/// Readable firmware mode name: `RainbowMorph_Inner` -> `Rainbow Morph`.
String firmwareModeLabel(String name) {
  final base = name.split('_').first;
  return base
      .replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (_) => ' ')
      .trim();
}
