/// Lighting page: devices, modes, effects, panels, and effect compatibility.
abstract class LightingStrings {
  const LightingStrings();

  // Device strip.
  String get devices;
  String get previousDevices;
  String get nextDevices;
  String fansGroup(String name);
  String get chassis;
  String get motherboard;
  String get memory1;
  String get memory2;
  String get graphicsCard;

  // Modes.
  String get modeCanvas;
  String get modeHardware;
  String get modeFixed;

  // Native effects and parameters.
  String effectLabel(String id, String fallback);
  String paramLabel(String id, String fallback);

  /// Native combobox values (`Left`, `Right`, `Up`, `Down`); other values pass
  /// through unchanged (HTML effects own their option text).
  String optionLabel(String value);

  // Device status.
  String get unsupported;
  String get waitingStatus;
  String get working;
  String get unavailable;
  String get autoHardware;

  // Global banner and controls.
  String get allArgbOff;
  String get turnOn;
  String get brightness;
  String get offOnSleep;
  String get useHardwareEffects;
  String get hardwareEffectsHint;
  String get effectLibrary;
  String get importEffectsHint;
  String canvasSize(int width, int height);

  // Effect panel.
  String get effect;
  String get noControls;
  String effectTitle(String name);
  String get loadingEffects;
  String libraryError(String error);
  String get effectNotInstalled;
  String get fixedSpeedNotice;
  String htmlStats(String fps, String ms);
  String fixedColorTitle(String device);
  String effectLoadFailed(String error);
  String effectPaused(int ms);
  String effectUnsupported(String issues);

  // Compatibility.
  String get compatible;
  String get partial;
  String get unsupportedEffect;
  String compatibilityIssue(int issue);
  String get requiresIssues;

  // ARGB toggle.
  String get argb;
  String get argbOff;
  String get turnOnAllArgb;
  String get turnOffAllArgb;

  // Hardware panels.
  String hardwareTitle(String device);
  String get identify;
  String get wholeFan;
  String get innerOuter;
  String get mode;
  String get mergeActive;
  String get fansInGroup;
  String get mergeBetweenGroups;
  String get mergeMode;
  String get mergeOrder;
  String get mergeShared;
  String get speed;
  String get direction;
  String get right;
  String get left;
  String get colors;
  String colorsCount(int count);
  String get color;
  String get gpuNote;
  String get boardHardwareTitle;
  String boardMode(int mode);
  String boardZone(int zone);

  // GPU effects.
  String gpuEffect(int effect);

  // Color picker.
  String get chooseColor;
  String get hexadecimal;

  // Output status details.
  String outputIssue(int issue, List<String> args);
}

class LightingStringsEn extends LightingStrings {
  const LightingStringsEn();

  @override
  String get devices => 'Devices';
  @override
  String get previousDevices => 'Previous devices';
  @override
  String get nextDevices => 'Next devices';
  @override
  String fansGroup(String name) => 'Fans · $name';
  @override
  String get chassis => 'Case';
  @override
  String get motherboard => 'Motherboard';
  @override
  String get memory1 => 'Memory 1';
  @override
  String get memory2 => 'Memory 2';
  @override
  String get graphicsCard => 'Graphics card';
  @override
  String get modeCanvas => 'Canvas';
  @override
  String get modeHardware => 'Hardware';
  @override
  String get modeFixed => 'Solid color';
  @override
  String effectLabel(String id, String fallback) => switch (id) {
    'solid' => 'Solid color',
    'spectrum' => 'Color cycle',
    'rainbowWave' => 'Rainbow wave',
    'breathing' => 'Breathing',
    'colorWave' => 'Two-color wave',
    'scanner' => 'Scanner',
    _ => fallback,
  };
  @override
  String paramLabel(String id, String fallback) => switch (id) {
    'speed' => 'Speed',
    'size' => 'Wave size',
    'direction' => 'Direction',
    'color' => 'Color',
    'color2' => 'Color 2',
    'background' => 'Background',
    'width' => 'Width',
    _ => fallback,
  };
  @override
  String optionLabel(String value) => switch (value) {
    'Left' => 'Left',
    'Right' => 'Right',
    'Up' => 'Up',
    'Down' => 'Down',
    _ => value,
  };
  @override
  String get unsupported => 'Unsupported';
  @override
  String get waitingStatus => 'Waiting for device status';
  @override
  String get working => 'Working';
  @override
  String get unavailable => 'Unavailable';
  @override
  String get autoHardware => 'Hardware (auto)';
  @override
  String get allArgbOff => 'All ARGB is turned off';
  @override
  String get turnOn => 'Turn on';
  @override
  String get brightness => 'Brightness';
  @override
  String get offOnSleep => 'Turn off when suspending or shutting down';
  @override
  String get useHardwareEffects => 'Use the hardware effects when possible';
  @override
  String get hardwareEffectsHint =>
      'Fans and the motherboard animate the effect in their own firmware, with '
      'smoother motion. The phase between devices may not be identical. For '
      'effects without an equivalent, and without this option, the fans get 2 '
      'frames per second: any faster and their speed oscillates.';
  @override
  String get effectLibrary => 'Effect library';
  @override
  String get importEffectsHint => 'Import HTML effects in the Explore tab.';
  @override
  String canvasSize(int width, int height) => 'Canvas $width×$height';
  @override
  String get effect => 'Effect';
  @override
  String get noControls => 'This effect has no available controls.';
  @override
  String effectTitle(String name) => 'Effect: $name';
  @override
  String get loadingEffects => 'Loading installed effects…';
  @override
  String libraryError(String error) =>
      'Could not read the library.\nTechnical details: $error';
  @override
  String get effectNotInstalled =>
      'This effect is not installed. Import it in the Explore tab.';
  @override
  String get fixedSpeedNotice => 'Fixed speed on the fans (firmware mode).';
  @override
  String htmlStats(String fps, String ms) => '$fps fps · $ms ms/frame';
  @override
  String fixedColorTitle(String device) => 'Solid color · $device';
  @override
  String effectLoadFailed(String error) =>
      'Could not load the effect.\nTechnical details: $error';
  @override
  String effectPaused(int ms) => 'Effect paused: frame took $ms ms.';
  @override
  String effectUnsupported(String issues) => 'Effect not supported: $issues.';
  @override
  String get compatible => 'Compatible';
  @override
  String get partial => 'Partial';
  @override
  String get unsupportedEffect => 'Unsupported';
  @override
  String compatibilityIssue(int issue) => switch (issue) {
    0 => 'screen capture',
    1 => 'pixel reads',
    2 => 'audio (silence)',
    3 => 'images',
    _ => 'unsupported API',
  };
  @override
  String get requiresIssues => 'Requires';
  @override
  String get argb => 'ARGB';
  @override
  String get argbOff => 'ARGB off';
  @override
  String get turnOnAllArgb => 'Turn on all ARGB';
  @override
  String get turnOffAllArgb => 'Turn off all ARGB';
  @override
  String hardwareTitle(String device) => 'Hardware · $device';
  @override
  String get identify => 'Identify';
  @override
  String get wholeFan => 'Whole fan';
  @override
  String get innerOuter => 'Inner + outer';
  @override
  String get mode => 'Mode';
  @override
  String get mergeActive =>
      'Merge active: the group mode is replaced by the merge mode.';
  @override
  String get fansInGroup => 'Fans in the group';
  @override
  String get mergeBetweenGroups => 'Merge between groups';
  @override
  String get mergeMode => 'Merge mode';
  @override
  String get mergeOrder => 'Merge order';
  @override
  String get mergeShared => 'Merge settings apply to every group.';
  @override
  String get speed => 'Speed';
  @override
  String get direction => 'Direction';
  @override
  String get right => 'Right';
  @override
  String get left => 'Left';
  @override
  String get colors => 'Colors';
  @override
  String colorsCount(int count) => 'Colors ($count)';
  @override
  String get color => 'Color';
  @override
  String get gpuNote =>
      'The controller accepts one effect every 120 ms. The app only sends '
      'colors after reading the card SSID; if the OEM read fails, the GPU is '
      'unavailable.';
  @override
  String get boardHardwareTitle => 'Hardware · Motherboard';
  @override
  String boardMode(int mode) => switch (mode) {
    0 => 'Static',
    1 => 'Pulse',
    2 => 'Flash',
    3 => 'Double flash',
    4 => 'Color cycle',
    5 => 'Wave',
    _ => 'Mode $mode',
  };
  @override
  String boardZone(int zone) => switch (zone) {
    0x20 => 'IO Shield 1',
    0x22 => 'CPU LED',
    0x23 => 'IO Shield 2',
    _ => 'Zone $zone',
  };
  @override
  String gpuEffect(int effect) => switch (effect) {
    0 => 'Off',
    1 => 'Static',
    2 => 'Breathing',
    3 => 'Flash',
    4 => 'Double flash',
    5 => 'Color cycle',
    6 => 'Wave',
    7 => 'Gradient',
    8 => 'Color shift',
    9 => 'Rainbow',
    10 => 'Three colors',
    11 => 'Claws',
    12 => 'Dazzle',
    _ => 'Effect $effect',
  };
  @override
  String get chooseColor => 'Choose color';
  @override
  String get hexadecimal => 'Hexadecimal';
  @override
  String outputIssue(int issue, List<String> args) => switch (issue) {
    0 => 'The graphics card driver is not available yet.',
    1 => 'AL V2 hub not found or without access permission.',
    2 => 'Motherboard ITE controller not found or without access permission.',
    3 =>
      args.isEmpty
          ? 'GPU RGB controller not found or without access permission.'
          : 'GPU RGB controller not found or without access permission: '
                '${args.join(', ')}',
    4 =>
      'Kingston Fury memory not found or without access permission on the '
          'SMBus.',
    5 => 'Blocked for safety: ${args.join(', ')}',
    _ => 'Device unavailable',
  };
}

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
  String compatibilityIssue(int issue) => switch (issue) {
    0 => 'captura de tela',
    1 => 'leitura de pixels',
    2 => 'áudio (silêncio)',
    3 => 'imagens',
    _ => 'API não suportada',
  };
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
  String boardMode(int mode) => switch (mode) {
    0 => 'Estático',
    1 => 'Pulsar',
    2 => 'Piscar',
    3 => 'Piscar duplo',
    4 => 'Ciclo de cores',
    5 => 'Onda',
    _ => 'Modo $mode',
  };
  @override
  String boardZone(int zone) => switch (zone) {
    0x20 => 'IO Shield 1',
    0x22 => 'LED da CPU',
    0x23 => 'IO Shield 2',
    _ => 'Zona $zone',
  };
  @override
  String gpuEffect(int effect) => switch (effect) {
    0 => 'Desligado',
    1 => 'Estático',
    2 => 'Respiração',
    3 => 'Flash',
    4 => 'Flash duplo',
    5 => 'Ciclo de cores',
    6 => 'Onda',
    7 => 'Gradiente',
    8 => 'Troca de cores',
    9 => 'Arco-íris',
    10 => 'Três cores',
    11 => 'Garras',
    12 => 'Ofuscante',
    _ => 'Efeito $effect',
  };
  @override
  String get chooseColor => 'Escolher cor';
  @override
  String get hexadecimal => 'Hexadecimal';
  @override
  String outputIssue(int issue, List<String> args) => switch (issue) {
    0 => 'Placa de vídeo ainda sem suporte.',
    1 => 'Hub AL V2 não encontrado ou sem permissão de acesso.',
    2 =>
      'Controlador ITE da placa-mãe não encontrado ou sem permissão de acesso.',
    3 =>
      args.isEmpty
          ? 'Controlador RGB da GPU não encontrado ou sem permissão de acesso.'
          : 'Controlador RGB da GPU não encontrado ou sem permissão de acesso: '
                '${args.join(', ')}',
    4 =>
      'Memória Kingston Fury não encontrada ou sem permissão de acesso ao '
          'barramento SMBus.',
    5 => 'Bloqueado por segurança: ${args.join(', ')}',
    _ => 'Dispositivo indisponível',
  };
}
