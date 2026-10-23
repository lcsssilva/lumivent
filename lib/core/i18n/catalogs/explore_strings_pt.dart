import 'explore_strings.dart';

class ExploreStringsPt extends ExploreStrings {
  const ExploreStringsPt();

  @override
  @override
  String get subtitle => 'Biblioteca local de efeitos HTML/Canvas';
  @override
  String get importEffect => 'Importar efeito…';
  @override
  String get folder => 'Pasta…';
  @override
  String get importFromWindows => 'Importar do Windows…';
  @override
  String get importEffectsDialogTitle => 'Importar efeitos (.html ou .zip)';
  @override
  String get importFolderDialogTitle => 'Importar pasta com efeitos';
  @override
  String get importWindowsDialogTitle =>
      'Pasta de efeitos do Windows (ou a pasta cache)';
  @override
  String get searchHint => 'Buscar por nome, autor ou tag';
  @override
  String get filterAll => 'Todos';
  @override
  String get filterCompatible => 'Compatíveis';
  @override
  String get filterPartial => 'Parciais';
  @override
  String get filterUnsupported => 'Não suportados';
  @override
  String get allCategories => 'Todas as categorias';
  @override
  String get allPublishers => 'Todos os autores';
  @override
  String get libraryReadFailed => 'Não foi possível ler a biblioteca';
  @override
  String get noMatch => 'Nenhum efeito corresponde aos filtros.';
  @override
  String get noEffectsTitle => 'Nenhum efeito instalado';
  @override
  String get noEffectsBody =>
      'Importe um arquivo .html, uma pasta com effect.html, um ZIP ou a pasta '
      'cache de efeitos do Windows (efeitos pagos não são importados). Os '
      'efeitos ficam em ~/.local/share/lumivent/effects.';
  @override
  String get appliedBadge => 'Aplicado';
  @override
  String get compatible => 'Compatível';
  @override
  String get partial => 'Parcial';
  @override
  String get unsupported => 'Não suportado';
  @override
  String get apply => 'Aplicar';
  @override
  String get applied => 'Aplicado';
  @override
  String get removeFromLibrary => 'Remover da biblioteca';
  @override
  String requires(String issues) => 'Requer $issues';
  @override
  String get originFile => 'Arquivo HTML';
  @override
  String get originFolder => 'Pasta';
  @override
  String get originZip => 'ZIP';
  @override
  String get originWindowsCache => 'Windows';
  @override
  String importDone(String summary) => 'Importação concluída: $summary';
  @override
  String importDoneWithError(String summary, String error) =>
      '$summary. $error';
  @override
  String importFailed(String error) =>
      'Falha na importação. Detalhes técnicos: $error';
  @override
  String effectApplied(String name) =>
      '“$name” aplicado. Ajuste os controles em Iluminação.';
  @override
  String removeTitle(String name) => 'Remover “$name”?';
  @override
  String get removeAppliedBody =>
      'Ele está aplicado agora e será trocado pelo efeito padrão. O arquivo '
      'será apagado da biblioteca.';
  @override
  String get removeBody => 'O arquivo será apagado da biblioteca.';
  @override
  String effectRemoved(String name) => '“$name” removido.';
  @override
  String removeFailed(String error) =>
      'Não foi possível remover o efeito. Detalhes técnicos: $error';
  @override
  String importSummary({
    required int imported,
    required int replaced,
    required int skipped,
    required int paidSkipped,
    required int errors,
  }) {
    final parts = <String>[
      if (imported > 0) '$imported importado${imported == 1 ? '' : 's'}',
      if (replaced > 0) '$replaced substituído${replaced == 1 ? '' : 's'}',
      if (skipped > 0) '$skipped ignorado${skipped == 1 ? '' : 's'}',
      if (paidSkipped > 0)
        '$paidSkipped pago${paidSkipped == 1 ? '' : 's'} não '
            'importado${paidSkipped == 1 ? '' : 's'}',
      if (errors > 0) '$errors erro${errors == 1 ? '' : 's'}',
    ];
    return parts.isEmpty ? 'Nada para importar.' : parts.join(', ');
  }

  @override
  String importNotHtmlOrZip(String path) => '$path: não é HTML nem ZIP';
  @override
  String importNotFound(String path) => '$path: não encontrado';
  @override
  String importFolderNotFound(String path) => '$path: pasta não encontrada';
  @override
  String get importChooseWindowsCache =>
      'Escolha a pasta cache de efeitos do Windows.';
  @override
  String get importCatalogMissing =>
      'catalog_en.json não encontrado na pasta cache: sem ele não dá para '
      'saber quais efeitos são pagos.';
  @override
  String importNoEffectHtml(String path) =>
      'Nenhum effect.html encontrado em $path.';
  @override
  String importInvalidZip(String path, String error) =>
      '$path: ZIP inválido. Detalhes técnicos: $error';
  @override
  String get importNoHtmlInZip => 'O ZIP não tem arquivos HTML.';
  @override
  String importTooLarge(String path) =>
      '$path: excede o limite de tamanho de importação.';
  @override
  String importUnsupportedZipEntry(String path) =>
      '$path: ignorado, é um link ou outro arquivo especial.';
  @override
  String importUnknown(String path, String error) =>
      '$path. Detalhes técnicos: $error';
}
