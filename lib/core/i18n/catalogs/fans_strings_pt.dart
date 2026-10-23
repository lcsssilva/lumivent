import 'fans_strings.dart';

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
