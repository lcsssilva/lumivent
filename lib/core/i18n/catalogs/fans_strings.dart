/// Fans page: presets, temperature sources, response, groups, and curve editor.
abstract class FansStrings {
  const FansStrings();

  // Presets.
  String get presetQuiet;
  String get presetStandard;
  String get presetHigh;
  String get presetFull;
  String get presetFixed;
  String get presetUser1;
  String get presetUser2;
  String get presetUser3;
  String get presetUser4;
  String get presetCustom;

  // Temperature sources.
  String get sourceCpuTctl;
  String get sourceGpuJunction;
  String get sourceGpuEdge;
  String get sourceSystem1;
  String get sourceSystem2;
  String get sourcePch;
  String get sourceCpuSocket;
  String get sourceVrm;
  String get sourcePciex16;
  String get sourcePciex4;

  /// Prefix for motherboard sources in the source list.
  String get motherboardPrefix;

  // Temperature response.
  String get responseFast;
  String get responseNormal;
  String get responseSmooth;
  String get responseFastHint;
  String get responseNormalHint;
  String get responseSmoothHint;

  // Page.
  String get groupsTitle;
  String applyAllTooltip(String name);
  String applyAllLabel(String name);
  String appliedToAll(String name);
  String get speedCurve;
  String get dragFixedHint;
  String dragHint(int maxPoints);
  String get groupOptions;
  String get startStop;
  String get startStopHint;
  String get temperatureSource;
  String get temperatureSourceHint;
  String get temperatureResponse;

  // Live values.
  String nowTemperature(String temperature);
  String get noTemperature;
  String get hubUnavailable;
  String get noFan;
  String get groupName;
  String get currentRpm;
  String get duty;
  String get target;
  String dutyAndRpm(String duty, String rpm);
}

class FansStringsEn extends FansStrings {
  const FansStringsEn();

  @override
  String get presetQuiet => 'Quiet';
  @override
  String get presetStandard => 'Standard';
  @override
  String get presetHigh => 'High';
  @override
  String get presetFull => 'Full';
  @override
  String get presetFixed => 'Fixed';
  @override
  String get presetUser1 => 'User 1';
  @override
  String get presetUser2 => 'User 2';
  @override
  String get presetUser3 => 'User 3';
  @override
  String get presetUser4 => 'User 4';
  @override
  String get presetCustom => 'Custom';
  @override
  String get sourceCpuTctl => 'CPU Tctl';
  @override
  String get sourceGpuJunction => 'GPU junction';
  @override
  String get sourceGpuEdge => 'GPU edge';
  @override
  String get sourceSystem1 => 'System 1';
  @override
  String get sourceSystem2 => 'System 2';
  @override
  String get sourcePch => 'PCH';
  @override
  String get sourceCpuSocket => 'CPU socket';
  @override
  String get sourceVrm => 'VRM';
  @override
  String get sourcePciex16 => 'PCIEX16';
  @override
  String get sourcePciex4 => 'PCIEX4';
  @override
  String get motherboardPrefix => 'Motherboard';
  @override
  String get responseFast => 'Fast';
  @override
  String get responseNormal => 'Normal';
  @override
  String get responseSmooth => 'Smooth';
  @override
  String get responseFastHint =>
      'No average or ramp: the fan follows the temperature every second.';
  @override
  String get responseNormalHint =>
      '4 s average; rises up to 15%/s and falls 3%/s to avoid Tctl spikes.';
  @override
  String get responseSmoothHint =>
      '10 s average; rises up to 5%/s and falls 1%/s for quiet fans.';
  @override
  String get groupsTitle => 'AL V2 hub groups';
  @override
  String applyAllTooltip(String name) =>
      'Copies the preset, points, Start/Stop, source, and response from '
      '"$name" to the other groups.';
  @override
  String applyAllLabel(String name) => 'Apply curve "$name" to all';
  @override
  String appliedToAll(String name) => 'Curve "$name" applied to all groups.';
  @override
  String get speedCurve => 'Fan curve';
  @override
  String get dragFixedHint =>
      'Drag the point up or down to change the fixed speed.';
  @override
  String dragHint(int maxPoints) =>
      'Drag the points · double-click adds (max. $maxPoints) · right-click '
      'removes.';
  @override
  String get groupOptions => 'Group options';
  @override
  String get startStop => 'Start/Stop';
  @override
  String get startStopHint =>
      'Stops the fans below the temperature of the first point.';
  @override
  String get temperatureSource => 'Temperature source';
  @override
  String get temperatureSourceHint =>
      'CPU/GPU for radiators; motherboard temperature (System, VRM…) for case '
      'fans.';
  @override
  String get temperatureResponse => 'Temperature response';
  @override
  String nowTemperature(String temperature) => '(now $temperature)';
  @override
  String get noTemperature => 'No temperature';
  @override
  String get hubUnavailable => 'Hub unavailable';
  @override
  String get noFan => 'no fan';
  @override
  String get groupName => 'Group name';
  @override
  String get currentRpm => 'Current RPM';
  @override
  String get duty => 'Duty';
  @override
  String get target => 'Target';
  @override
  String dutyAndRpm(String duty, String rpm) => 'duty $duty % · $rpm rpm';
}

class FansStringsPt extends FansStrings {
  const FansStringsPt();

  @override
  String get presetQuiet => 'Quiet';
  @override
  String get presetStandard => 'Standard';
  @override
  String get presetHigh => 'High';
  @override
  String get presetFull => 'Full';
  @override
  String get presetFixed => 'Fixo';
  @override
  String get presetUser1 => 'Usuário 1';
  @override
  String get presetUser2 => 'Usuário 2';
  @override
  String get presetUser3 => 'Usuário 3';
  @override
  String get presetUser4 => 'Usuário 4';
  @override
  String get presetCustom => 'Personalizado';
  @override
  String get sourceCpuTctl => 'CPU Tctl';
  @override
  String get sourceGpuJunction => 'GPU junction';
  @override
  String get sourceGpuEdge => 'GPU edge';
  @override
  String get sourceSystem1 => 'System 1';
  @override
  String get sourceSystem2 => 'System 2';
  @override
  String get sourcePch => 'PCH';
  @override
  String get sourceCpuSocket => 'CPU socket';
  @override
  String get sourceVrm => 'VRM';
  @override
  String get sourcePciex16 => 'PCIEX16';
  @override
  String get sourcePciex4 => 'PCIEX4';
  @override
  String get motherboardPrefix => 'Placa-mãe';
  @override
  String get responseFast => 'Rápida';
  @override
  String get responseNormal => 'Normal';
  @override
  String get responseSmooth => 'Suave';
  @override
  String get responseFastHint =>
      'Sem média nem rampa: a fan segue a temperatura a cada segundo.';
  @override
  String get responseNormalHint =>
      'Média de 4 s; sobe até 15%/s e desce 3%/s para evitar picos do Tctl.';
  @override
  String get responseSmoothHint =>
      'Média de 10 s; sobe até 5%/s e desce 1%/s para fans silenciosas.';
  @override
  String get groupsTitle => 'Grupos do hub AL V2';
  @override
  String applyAllTooltip(String name) =>
      'Copia o preset, os pontos, o Start/Stop, a fonte e a resposta de "$name" '
      'para os outros grupos.';
  @override
  String applyAllLabel(String name) => 'Aplicar curva "$name" a todos';
  @override
  String appliedToAll(String name) =>
      'Curva "$name" aplicada a todos os grupos.';
  @override
  String get speedCurve => 'Curva de velocidade';
  @override
  String get dragFixedHint =>
      'Arraste o ponto para cima ou para baixo para mudar a velocidade fixa.';
  @override
  String dragHint(int maxPoints) =>
      'Arraste os pontos · clique duplo adiciona (máx. $maxPoints) · botão '
      'direito remove.';
  @override
  String get groupOptions => 'Opções do grupo';
  @override
  String get startStop => 'Start/Stop';
  @override
  String get startStopHint =>
      'Para as fans abaixo da temperatura do primeiro ponto.';
  @override
  String get temperatureSource => 'Fonte de temperatura';
  @override
  String get temperatureSourceHint =>
      'CPU/GPU para radiadores; temperatura da placa-mãe (System, VRM…) para '
      'fans do gabinete.';
  @override
  String get temperatureResponse => 'Resposta à temperatura';
  @override
  String nowTemperature(String temperature) => '(agora $temperature)';
  @override
  String get noTemperature => 'Sem temperatura';
  @override
  String get hubUnavailable => 'Hub indisponível';
  @override
  String get noFan => 'sem fan';
  @override
  String get groupName => 'Nome do grupo';
  @override
  String get currentRpm => 'RPM atual';
  @override
  String get duty => 'Duty';
  @override
  String get target => 'Alvo';
  @override
  String dutyAndRpm(String duty, String rpm) => 'duty $duty % · $rpm rpm';
}
