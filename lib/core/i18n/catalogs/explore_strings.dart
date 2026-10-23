/// Explore page: effect library, filters, import, and import reports.
abstract class ExploreStrings {
  const ExploreStrings();

  String get subtitle;

  // Import buttons and dialogs.
  String get importEffect;
  String get folder;
  String get importFromWindows;
  String get importEffectsDialogTitle;
  String get importFolderDialogTitle;
  String get importWindowsDialogTitle;

  // Search and filters.
  String get searchHint;
  String get filterAll;
  String get filterCompatible;
  String get filterPartial;
  String get filterUnsupported;
  String get allCategories;
  String get allPublishers;

  // Library states.
  String get libraryReadFailed;
  String get noMatch;
  String get noEffectsTitle;
  String get noEffectsBody;

  // Cards.
  String get compatible;
  String get partial;
  String get unsupported;
  String get appliedBadge;
  String get apply;
  String get applied;
  String get removeFromLibrary;
  String requires(String issues);
  String get originFile;
  String get originFolder;
  String get originZip;
  String get originWindowsCache;

  // Snacks and dialogs.
  String importDone(String summary);
  String importDoneWithError(String summary, String error);
  String importFailed(String error);
  String effectApplied(String name);
  String removeTitle(String name);
  String get removeAppliedBody;
  String get removeBody;
  String effectRemoved(String name);
  String removeFailed(String error);

  /// Summary of an import: imported/replaced/skipped/paid/errors.
  String importSummary({
    required int imported,
    required int replaced,
    required int skipped,
    required int paidSkipped,
    required int errors,
  });

  // Import errors: [path] and [error] are data.
  String importNotHtmlOrZip(String path);
  String importNotFound(String path);
  String importFolderNotFound(String path);
  String get importChooseWindowsCache;
  String get importCatalogMissing;
  String importNoEffectHtml(String path);
  String importInvalidZip(String path, String error);
  String get importNoHtmlInZip;
  String importUnknown(String path, String error);
}

class ExploreStringsEn extends ExploreStrings {
  const ExploreStringsEn();

  @override
  @override
  String get subtitle => 'Local library of HTML/Canvas effects';
  @override
  String get importEffect => 'Import effect…';
  @override
  String get folder => 'Folder…';
  @override
  String get importFromWindows => 'Import from Windows…';
  @override
  String get importEffectsDialogTitle => 'Import effects (.html or .zip)';
  @override
  String get importFolderDialogTitle => 'Import folder with effects';
  @override
  String get importWindowsDialogTitle =>
      'Windows effects folder (or the cache folder)';
  @override
  String get searchHint => 'Search by name, author, or tag';
  @override
  String get filterAll => 'All';
  @override
  String get filterCompatible => 'Compatible';
  @override
  String get filterPartial => 'Partial';
  @override
  String get filterUnsupported => 'Unsupported';
  @override
  String get allCategories => 'All categories';
  @override
  String get allPublishers => 'All authors';
  @override
  String get libraryReadFailed => 'Could not read the library';
  @override
  String get noMatch => 'No effect matches the filters.';
  @override
  String get noEffectsTitle => 'No effects installed';
  @override
  String get noEffectsBody =>
      'Import an .html file, a folder with effect.html, a ZIP, or the Windows '
      'effects cache folder (paid effects are not imported). Effects are kept '
      'in ~/.local/share/lumivent/effects.';
  @override
  String get appliedBadge => 'Applied';
  @override
  String get compatible => 'Compatible';
  @override
  String get partial => 'Partial';
  @override
  String get unsupported => 'Unsupported';
  @override
  String get apply => 'Apply';
  @override
  String get applied => 'Applied';
  @override
  String get removeFromLibrary => 'Remove from library';
  @override
  String requires(String issues) => 'Requires $issues';
  @override
  String get originFile => 'HTML file';
  @override
  String get originFolder => 'Folder';
  @override
  String get originZip => 'ZIP';
  @override
  String get originWindowsCache => 'Windows';
  @override
  String importDone(String summary) => 'Import finished: $summary';
  @override
  String importDoneWithError(String summary, String error) =>
      '$summary. $error';
  @override
  String importFailed(String error) =>
      'Import failed. Technical details: $error';
  @override
  String effectApplied(String name) =>
      '“$name” applied. Adjust the controls in Lighting.';
  @override
  String removeTitle(String name) => 'Remove “$name”?';
  @override
  String get removeAppliedBody =>
      'It is applied right now and will be replaced by the default effect. '
      'The file will be deleted from the library.';
  @override
  String get removeBody => 'The file will be deleted from the library.';
  @override
  String effectRemoved(String name) => '“$name” removed.';
  @override
  String removeFailed(String error) =>
      'Could not remove the effect. Technical details: $error';
  @override
  String importSummary({
    required int imported,
    required int replaced,
    required int skipped,
    required int paidSkipped,
    required int errors,
  }) {
    final parts = <String>[
      if (imported > 0) '$imported imported',
      if (replaced > 0) '$replaced replaced',
      if (skipped > 0) '$skipped skipped',
      if (paidSkipped > 0) '$paidSkipped paid not imported',
      if (errors > 0) '$errors ${errors == 1 ? 'error' : 'errors'}',
    ];
    return parts.isEmpty ? 'Nothing to import.' : parts.join(', ');
  }

  @override
  String importNotHtmlOrZip(String path) => '$path: not HTML or ZIP';
  @override
  String importNotFound(String path) => '$path: not found';
  @override
  String importFolderNotFound(String path) => '$path: folder not found';
  @override
  String get importChooseWindowsCache =>
      'Choose the Windows effects cache folder.';
  @override
  String get importCatalogMissing =>
      'catalog_en.json not found in the cache folder: without it there is '
      'no way to tell which effects are paid.';
  @override
  String importNoEffectHtml(String path) => 'No effect.html found in $path.';
  @override
  String importInvalidZip(String path, String error) =>
      '$path: invalid ZIP. Technical details: $error';
  @override
  String get importNoHtmlInZip => 'The ZIP has no HTML files.';
  @override
  String importUnknown(String path, String error) =>
      '$path. Technical details: $error';
}

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
  String importUnknown(String path, String error) =>
      '$path. Detalhes técnicos: $error';
}
