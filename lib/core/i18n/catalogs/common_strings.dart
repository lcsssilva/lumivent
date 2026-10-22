/// Strings shared by more than one area.
abstract class CommonStrings {
  const CommonStrings();

  String get cancel;
  String get save;
  String get remove;
  String get close;
  String get retry;
  String get details;
  String get technicalDetails;
  String get none;
  String get before;
  String get after;
  String get configWriteFailed;

  /// Default name of a fan group (group 0–3).
  String groupName(int group);
}

class CommonStringsEn extends CommonStrings {
  const CommonStringsEn();

  @override
  String get cancel => 'Cancel';
  @override
  String get save => 'Save';
  @override
  String get remove => 'Remove';
  @override
  String get close => 'Close';
  @override
  String get retry => 'Try again';
  @override
  String get details => 'Details';
  @override
  String get technicalDetails => 'Technical details';
  @override
  String get none => 'None';
  @override
  String get before => 'Before';
  @override
  String get after => 'After';
  @override
  String get configWriteFailed =>
      'Could not save your changes. Check the configuration folder permissions and available disk space.';
  @override
  String groupName(int group) => 'Group $group';
}

class CommonStringsPt extends CommonStrings {
  const CommonStringsPt();

  @override
  String get cancel => 'Cancelar';
  @override
  String get save => 'Salvar';
  @override
  String get remove => 'Remover';
  @override
  String get close => 'Fechar';
  @override
  String get retry => 'Tentar de novo';
  @override
  String get details => 'Detalhes';
  @override
  String get technicalDetails => 'Detalhes técnicos';
  @override
  String get none => 'Nenhum';
  @override
  String get before => 'Antes';
  @override
  String get after => 'Depois';
  @override
  String get configWriteFailed =>
      'Não foi possível salvar suas alterações. Verifique as permissões da pasta de configuração e o espaço disponível.';
  @override
  String groupName(int group) => 'Grupo $group';
}
