# Documentação do Lumivent

Este diretório reúne a documentação técnica e de uso. O README da raiz é a
porta de entrada; aqui está o detalhe.

## Documentos atuais

| Documento | Para quem | Assunto |
|---|---|---|
| [`instalacao.md`](instalacao.md) | usuário | instalação pelo pacote ou manual, kernel, permissões e desinstalação |
| [`configuracao.md`](configuracao.md) | usuário/desenvolvedor | formato do `config.json`, seções, compatibilidade e importação |
| [`solucao-de-problemas.md`](solucao-de-problemas.md) | usuário | sintomas comuns e como diagnosticar |
| [`arquitetura.md`](arquitetura.md) | desenvolvedor | módulos, camadas, engine, isolates e fluxo de dados |
| [`desenvolvimento.md`](desenvolvimento.md) | desenvolvedor | ambiente, testes, estilo, ferramentas e como estender |
| [`hardware.md`](hardware.md) | desenvolvedor/usuário avançado | dispositivos, protocolos, guardas e limitações |
| [`release.md`](release.md) | mantenedor | versionamento, tags, CI e publicação do `.pkg.tar.zst` |

## Documentos de engenharia reversa

Os arquivos abaixo registram a investigação que originou os drivers. Eles são
**notas históricas** e podem citar programas, arquivos ou comportamentos de
terceiros:

Esses documentos não fazem parte do repositório nem do pacote distribuído e
são ignorados pelo Git. Não devem ser enviados à distribuição pública junto com
código, recursos ou binários de terceiros. Nenhum efeito, fonte ou executável
proprietário é redistribuído pelo projeto.

## Histórico de planejamento

| Documento | Estado |
|---|---|
| [`plans/plano-implementacao.md`](plans/plano-implementacao.md) | histórico das fases 0–4 |
| [`planning/plano.md`](planning/plano.md) | estado e pendências da versão 1.0 |
| [`plans/checklist-final.md`](plans/checklist-final.md) | verificações manuais de hardware |

Planejamento registra decisões e medições; não é contrato de API. Para o
comportamento atual, consulte o código e os documentos da primeira tabela.

## Convenções

- Documentação em português; código e comentários em inglês.
- Caminhos, comandos e nomes de chaves devem ser copiáveis e fiéis ao código.
- Toda mudança de comportamento deve atualizar o documento correspondente e o
  [`CHANGELOG.md`](../CHANGELOG.md).
