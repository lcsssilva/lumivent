import 'common_strings.dart';

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
