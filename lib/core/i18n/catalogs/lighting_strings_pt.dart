import 'lighting_strings.dart';

class LightingStringsPt extends LightingStrings {
  const LightingStringsPt();

  @override
  String get devices => 'Dispositivos';
  @override
  String get previousDevices => 'Dispositivos anteriores';
  @override
  String get nextDevices => 'Próximos dispositivos';
  @override
  String fansGroup(String name) => 'Fans · $name';
  @override
  String get chassis => 'Gabinete';
  @override
  String get motherboard => 'Placa-mãe';
  @override
  String get memory1 => 'Memória 1';
  @override
  String get memory2 => 'Memória 2';
  @override
  String get graphicsCard => 'Placa de vídeo';
  @override
  String get modeCanvas => 'Canvas';
  @override
  String get modeHardware => 'Hardware';
  @override
  String get modeFixed => 'Cor fixa';
  @override
  String effectLabel(String id, String fallback) => switch (id) {
    'solid' => 'Cor sólida',
    'spectrum' => 'Ciclo de cores',
    'rainbowWave' => 'Onda arco-íris',
    'breathing' => 'Respiração',
    'colorWave' => 'Onda de duas cores',
    'scanner' => 'Varredura',
    _ => fallback,
  };
  @override
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
  @override
  String optionLabel(String value) => switch (value) {
    'Left' => 'Esquerda',
    'Right' => 'Direita',
    'Up' => 'Cima',
    'Down' => 'Baixo',
    _ => value,
  };
  @override
  String get unsupported => 'Não suportado';
  @override
  String get waitingStatus => 'Aguardando status do dispositivo';
  @override
  String get working => 'Funcionando';
  @override
  String get unavailable => 'Indisponível';
  @override
  String get autoHardware => 'Hardware (auto)';
  @override
  String get allArgbOff => 'Todos os ARGB estão desligados';
  @override
  String get turnOn => 'Ligar';
  @override
  String get brightness => 'Brilho';
  @override
  String get offOnSleep => 'Apagar ao suspender ou desligar';
  @override
  String get useHardwareEffects =>
      'Usar os efeitos do próprio hardware quando possível';
  @override
  String get hardwareEffectsHint =>
      'Fans e placa-mãe animam o efeito no próprio firmware, com movimento '
      'mais suave. A fase entre os dispositivos pode não ficar idêntica. Nos '
      'efeitos sem equivalente, e sem esta opção, as fans recebem 2 quadros '
      'por segundo: mais rápido, a velocidade delas oscila.';
  @override
  String get effectLibrary => 'Biblioteca de efeitos';
  @override
  String get importEffectsHint => 'Importe efeitos HTML na aba Explore.';
  @override
  String canvasSize(int width, int height) => 'Canvas $width×$height';
  @override
  String get effect => 'Efeito';
  @override
  String get noControls => 'Este efeito não tem controles disponíveis.';
  @override
  String effectTitle(String name) => 'Efeito: $name';
  @override
  String get loadingEffects => 'Carregando efeitos instalados…';
  @override
  String libraryError(String error) =>
      'Não foi possível ler a biblioteca.\nDetalhes técnicos: $error';
  @override
  String get effectNotInstalled =>
      'Este efeito não está instalado. Importe-o na aba Explore.';
  @override
  String get fixedSpeedNotice => 'Velocidade fixa nas fans (modo do firmware).';
  @override
  String htmlStats(String fps, String ms) => '$fps fps · $ms ms/quadro';
  @override
  String fixedColorTitle(String device) => 'Cor fixa · $device';
  @override
  String effectLoadFailed(String error) =>
      'Falha ao carregar o efeito.\nDetalhes técnicos: $error';
  @override
  String effectPaused(int ms) => 'Efeito pausado: quadro demorou $ms ms.';
  @override
  String effectUnsupported(String issues) => 'Efeito não suportado: $issues.';
  @override
  String get compatible => 'Compatível';
  @override
  String get partial => 'Parcial';
  @override
  String get unsupportedEffect => 'Não suportado';
  @override
  String get compatCapture => 'captura de tela';
  @override
  String get compatPixels => 'leitura de pixels';
  @override
  String get compatAudio => 'áudio (silêncio)';
  @override
  String get compatImages => 'imagens';
  @override
  String get compatApi => 'API não suportada';
  @override
  String get requiresIssues => 'Requer';
  @override
  String get argb => 'ARGB';
  @override
  String get argbOff => 'ARGB desligado';
  @override
  String get turnOnAllArgb => 'Religar todos os ARGB';
  @override
  String get turnOffAllArgb => 'Desligar todos os ARGB';
  @override
  String hardwareTitle(String device) => 'Hardware · $device';
  @override
  String get identify => 'Identificar';
  @override
  String get wholeFan => 'Ventoinha inteira';
  @override
  String get innerOuter => 'Interno + externo';
  @override
  String get mode => 'Modo';
  @override
  String get mergeActive =>
      'Merge ativo: o modo de grupo é substituído pelo modo merge.';
  @override
  String get fansInGroup => 'Ventoinhas no grupo';
  @override
  String get mergeBetweenGroups => 'Merge entre grupos';
  @override
  String get mergeMode => 'Modo merge';
  @override
  String get mergeOrder => 'Ordem do merge';
  @override
  String get mergeShared => 'Os ajustes do merge valem para todos os grupos.';
  @override
  String get speed => 'Velocidade';
  @override
  String get direction => 'Direção';
  @override
  String get right => 'Direita';
  @override
  String get left => 'Esquerda';
  @override
  String get colors => 'Cores';
  @override
  String colorsCount(int count) => 'Cores ($count)';
  @override
  String get color => 'Cor';
  @override
  String get gpuNote =>
      'O controlador aceita um efeito a cada 120 ms. O app só envia cores '
      'depois de ler o SSID da placa; se a leitura do OEM falhar, a GPU fica '
      'indisponível.';
  @override
  String get boardHardwareTitle => 'Hardware · Placa-mãe';
  @override
  String get boardModeStatic => 'Estático';
  @override
  String get boardModePulse => 'Pulsar';
  @override
  String get boardModeFlash => 'Piscar';
  @override
  String get boardModeDoubleFlash => 'Piscar duplo';
  @override
  String get boardModeColorCycle => 'Ciclo de cores';
  @override
  String get boardModeWave => 'Onda';
  @override
  String boardZone(int zone) => switch (zone) {
    0x20 => 'IO Shield 1',
    0x22 => 'LED da CPU',
    0x23 => 'IO Shield 2',
    _ => 'Zona $zone',
  };
  @override
  String get gpuEffectOff => 'Desligado';
  @override
  String get gpuEffectStatic => 'Estático';
  @override
  String get gpuEffectBreathing => 'Respiração';
  @override
  String get gpuEffectFlash => 'Flash';
  @override
  String get gpuEffectDoubleFlash => 'Flash duplo';
  @override
  String get gpuEffectColorCycle => 'Ciclo de cores';
  @override
  String get gpuEffectWave => 'Onda';
  @override
  String get gpuEffectGradient => 'Gradiente';
  @override
  String get gpuEffectColorShift => 'Troca de cores';
  @override
  String get gpuEffectRainbow => 'Arco-íris';
  @override
  String get gpuEffectThreeColors => 'Três cores';
  @override
  String get gpuEffectClaws => 'Garras';
  @override
  String get gpuEffectDazzle => 'Ofuscante';
  @override
  String get chooseColor => 'Escolher cor';
  @override
  String get hexadecimal => 'Hexadecimal';
  @override
  String get outputUnsupported => 'Placa de vídeo ainda sem suporte.';
  @override
  String get outputHub =>
      'Hub AL V2 não encontrado ou sem permissão de acesso.';
  @override
  String get outputIte =>
      'Controlador ITE da placa-mãe não encontrado ou sem permissão de acesso.';
  @override
  String outputGpu(List<String> args) => args.isEmpty
      ? 'Controlador RGB da GPU não encontrado ou sem permissão de acesso.'
      : 'Controlador RGB da GPU não encontrado ou sem permissão de acesso: '
            '${args.join(', ')}';
  @override
  String get outputRam =>
      'Memória Kingston Fury não encontrada ou sem permissão de acesso ao '
      'barramento SMBus.';
  @override
  String outputBlocked(List<String> args) =>
      'Bloqueado por segurança: ${args.join(', ')}';
}
