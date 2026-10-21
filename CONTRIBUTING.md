# Contribuindo com o Lumivent

Obrigado pelo interesse. Este guia cobre o ambiente, as regras do projeto e o
que esperamos de um pull request.

Antes de começar, leia também:

- [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) — convivência na comunidade;
- [`docs/arquitetura.md`](docs/arquitetura.md) — decisões estruturais;
- [`docs/desenvolvimento.md`](docs/desenvolvimento.md) — guia detalhado.

## Formas de contribuir

- Relatar um bug com o máximo de contexto de hardware e logs.
- Testar o app em um modelo de placa, memória ou GPU diferente e contar o que
  funcionou.
- Corrigir documentação, traduções ou mensagens da interface.
- Implementar ou corrigir um driver, efeito ou teste.
- Melhorar acessibilidade, teclado e leitores de tela.

Para bugs, use o template de issue. Para vulnerabilidades, **não abra issue
pública**: siga [`SECURITY.md`](SECURITY.md).

## Ambiente

Requisitos:

- Linux (Arch Linux ou CachyOS para o pacote; outra distro para desenvolvimento);
- Flutter 3.47+ e Dart 3.13+;
- GTK 3, `hidapi`, `libcap`, `clang`, `cmake`, `ninja`, `pkgconf` e `gcc`;
- hardware compatível para testar o caminho real (sem ele, use os testes).

```sh
git clone https://github.com/lcsssilva/lumivent.git
cd lumivent
flutter config --enable-linux-desktop
flutter pub get
flutter run -d linux
```

Para instalar as regras udev e o helper sem gerar o pacote, veja
[`docs/instalacao.md`](docs/instalacao.md) §7.

## Antes de abrir um PR

Rode, na raiz:

```sh
dart format lib test tool
flutter analyze
flutter test
```

O CI repete `flutter analyze` e `flutter test` em cada push e pull request. Um PR
com teste quebrado ou análise com avisos não é mesclado.

### Testes

- Toda correção de comportamento deve vir com um teste que falha sem ela.
- Todo driver novo deve ter testes de protocolo (bytes exatos), de guardas de
  segurança e de ausência/permissão do dispositivo.
- `test/architecture_test.dart` verifica as regras de dependência entre módulos.
  Se ele falhar, ajuste os imports — não relaxe a regra.
- Testes de widget usam os textos em português da interface (`find.text`).
- Para hardware real, as ferramentas de `tool/` pedem o app fechado.

## Estilo de código

- Código, comentários, nomes de classes, variáveis e testes em **inglês**.
- Textos da interface e mensagens ao usuário em **português**.
- Documentação em `docs/` em **português**.
- Siga o formato do `dart format` e os lints de `analysis_options.yaml`.
- Prefira tipos explícitos nas fronteiras entre módulos e isolates.
- Não adicione dependência nova sem justificar no PR (tamanho, licença,
  manutenção e compatibilidade com Linux desktop).

## Arquitetura em uma página

O projeto é um **monólito modular feature-first** com camadas DDD dentro de cada
módulo. As regras completas estão em [`docs/arquitetura.md`](docs/arquitetura.md),
mas o essencial:

1. `core/` não conhece `app/` nem `features/`.
2. `features/` não conhecem `app/`.
3. Um módulo importa outro **somente** por `features/<m>/<m>.dart`.
4. `domain/` é Dart puro: sem Flutter, Riverpod, `dart:io`, `dart:ffi`,
   `dart:ui` ou isolates.
5. `application/` não depende de `infrastructure/` nem de `presentation/`.
6. `presentation/` não depende de `infrastructure/`.

Handles de hardware pertencem ao isolate da engine. A UI nunca abre `/dev`,
hidraw, SMBus ou sysfs diretamente.

## Adicionando um módulo

O módulo `fans` é o exemplo mais completo. O roteiro:

1. Crie `lib/features/<nome>/` com `domain/`, `application/`,
   `infrastructure/`, `presentation/`.
2. Declare as portas no `domain/` e os providers que lançam
   `UnimplementedError` no `application/`.
3. Implemente as portas no `infrastructure/`.
4. Crie `<nome>_module.dart` para ligar portas e implementações, e
   `<nome>.dart` como API pública.
5. Se o módulo precisar de tempo real, crie um `EngineModule` e os
   `EngineCommand`/`EngineEvent` próprios.
6. Registre o módulo em `lib/app/bootstrap.dart` e, se necessário, em
   `lib/app/engine_modules.dart`.
7. Adicione testes e atualize `docs/arquitetura.md`.

## Adicionando um driver

Checklist mínimo:

- Constantes de protocolo em `protocol.dart`, com referência ao documento de
  engenharia reversa.
- Nenhum comando destrutivo, de persistência ou de sincronização sem guarda
  explícita e teste.
- Identidade do dispositivo lida **antes** de qualquer escrita.
- Timeouts, erros de permissão e dispositivo ausente tratados sem derrubar a
  engine.
- `bool` de retorno significa “o dispositivo aceitou a escrita”; falhas não
  lançam exceção para o chamador.
- Testes com fake de transporte, incluindo os bytes enviados.
- Documentação em [`docs/hardware.md`](docs/hardware.md) e, se houver protocolo
  novo, uma nota em `docs/`.

Não envie para o repositório:

- código-fonte descompilado de programas de terceiros (`docs/re/`);
- recursos, fontes ou efeitos proprietários de terceiros;
- arquivos de captura ou dumps que contenham dados pessoais.

## Adicionando um efeito nativo

- O efeito vive em `lib/features/lighting/domain/native_effects.dart`.
- Parâmetros seguem os tipos dos efeitos HTML (`number`, `color`, `boolean`,
  `combobox`, `hue`) para a UI gerar os controles.
- A cor é calculada por LED, em função do tempo e da posição no canvas.
- Se o firmware tiver um modo equivalente, avalie adicionar o mapeamento em
  `hardware_equivalents.dart` e documente a diferença de fase/velocidade.
- Inclua teste determinístico com tempos fixos.

## Commits e pull requests

Usamos mensagens no padrão [Conventional Commits](https://www.conventionalcommits.org/pt-br/):

```text
feat(fans): adiciona resposta suave por grupo
fix(lighting): corrige fase do breathing no resume
docs(release): documenta checksums do pacote
test(devices): cobre guarda do comando 0x18 da GPU
```

Um PR deve:

- ter um objetivo claro e um título no mesmo padrão;
- explicar **por que** a mudança existe e como foi testada;
- listar o hardware usado no teste, quando aplicável;
- atualizar documentação e `CHANGELOG.md` quando o comportamento muda;
- não misturar refatoração ampla com correção funcional.

## Documentação

- `README.md` é a porta de entrada.
- `docs/` é a referência; mantenha exemplos e caminhos fiéis ao código.
- `docs/README.md` lista o que é atual e o que é histórico.
- Ao mudar `config.json`, `PKGBUILD`, regras udev ou o fluxo de release,
  atualize o documento correspondente no mesmo PR.

## Licença das contribuições

Ao enviar um PR, você concorda que sua contribuição é licenciada sob a MIT, a
mesma do projeto. Não envie código incompatível com essa licença.
