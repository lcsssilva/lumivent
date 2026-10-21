# Desenvolvimento

Guia para compilar, testar e estender o Lumivent. Para as regras de convivência
e o processo de PR, veja [`CONTRIBUTING.md`](../CONTRIBUTING.md).

## Requisitos

- Linux x86_64 (o desenvolvimento e os testes de hardware foram feitos em Arch
  Linux/CachyOS, KDE Wayland);
- Flutter 3.47+ (Dart 3.13+);
- GTK 3, `hidapi`, `libcap`;
- `clang`, `cmake`, `ninja`, `pkgconf`, `gcc`;
- para empacotar: `makepkg` (pacman/Arch).

```sh
flutter config --enable-linux-desktop
flutter pub get
flutter run -d linux
```

O app abre a janela principal; `flutter run -d linux -- --minimized` inicia na
bandeja (o runner repassa os argumentos).

## Comandos

| Comando | Uso |
|---|---|
| `flutter run -d linux` | executa em modo debug |
| `flutter analyze` | análise estática (deve terminar sem issues) |
| `flutter test` | toda a suíte |
| `flutter test test/architecture_test.dart` | só as regras de arquitetura |
| `flutter test --coverage` | gera `coverage/lcov.info` |
| `flutter build linux --release` | bundle em `build/linux/x64/release/bundle/` |
| `makepkg -si` | compila e instala o pacote local |
| `dart format lib test tool` | formata código |

O CI executa `flutter analyze` e `flutter test` em cada push e pull request.

## Organização dos testes

| Área | Exemplos |
|---|---|
| domínio puro | `test/features/fans/fan_curve_test.dart`, `test/features/lighting/lighting_domain_test.dart` |
| engine | `test/core/engine_host_test.dart`, `*_engine_test.dart` |
| drivers e protocolos | `test/features/devices/alv2_*_test.dart`, `gpu_controller_test.dart`, `ite_lighting_test.dart` |
| persistência | `test/core/config_store_test.dart`, `test/app/config_transfer_test.dart` |
| UI | `test/app/shell_test.dart`, `*_page_test.dart`, `*_panel_test.dart` |
| arquitetura | `test/architecture_test.dart` |

A suíte usa fakes em `test/fakes.dart` (`FakeEngine`). Os
testes de UI usam os textos em português da interface.

Boas práticas:

- prefira testar o domínio e os protocolos sem hardware;
- para FFI, teste a montagem/parse dos pacotes e use um transporte fake;
- para tempo, injete `DateTime Function() now` (a engine e os smoothers já
  aceitam);
- não dependa de rede, `/dev` real ou estado global entre testes;
- um teste novo deve falhar antes da correção e passar depois.

## Regras de arquitetura

O teste `test/architecture_test.dart` percorre todos os `import`/`export` de
`lib/` e falha se:

1. `core/` importar `app/` ou `features/`;
2. uma feature importar `app/`;
3. um módulo importar outro fora de `features/<outro>/<outro>.dart`;
4. `domain/` importar Flutter, Riverpod, `dart:io`, `dart:ffi`, `dart:ui`,
   `dart:isolate` ou outra camada;
5. `application/` importar `infrastructure/` ou `presentation/`;
6. `presentation/` importar `infrastructure/`.

Além disso, todo diretório em `features/` precisa do barrel
`features/<m>/<m>.dart`.

Se precisar de algo de outro módulo, amplie a API pública dele — não importe o
interno.

## Como o hardware é acessado

| Transporte | Implementação | Uso |
|---|---|---|
| hidraw | `core/platform/hidapi_ffi.dart` (`libhidapi-hidraw`) | hub AL V2, ITE IT5702 |
| SMBus | `core/platform/smbus_ffi.dart` (ioctl `I2C_SMBUS`) | Kingston Fury |
| I²C bruto | `core/platform/raw_i2c_ffi.dart` (ioctl `I2C_RDWR`) | GPU Gigabyte |
| sysfs | `dart:io` | hwmon, cpufreq, `/proc`, NVMe |
| D-Bus | `dbus` | logind (suspender/desligar) |
| processo | `Process.run` | helper NVMe, `systemctl --user` |

Guardas obrigatórias:

- endereços SPD `0x50–0x57` são recusados antes de qualquer ioctl (SMBus e I²C
  bruto);
- o ITE bloqueia comandos proibidos (`0x5E`, `0x47`, `0x48`, `0x59` e `CC 32`
  com D_LED2);
- a GPU lê firmware e SSID antes de qualquer `0x12` e bloqueia `0x13`, `0x16`,
  `0x17` e `0x18`;
- handles FFI vivem no isolate que os abriu; nunca os envie entre isolates.

Mais detalhes: [`hardware.md`](hardware.md).

## Rodando sem instalar

```sh
flutter build linux --release

cc -O2 -Wall -Wextra -Werror \
  -o build/lumivent-nvme-smart \
  tool/lumivent-nvme-smart/lumivent-nvme-smart.c

LUMIVENT_NVME_SMART=$PWD/build/lumivent-nvme-smart \
  build/linux/x64/release/bundle/lumivent
```

Sem as regras udev instaladas, os dispositivos aparecem como “sem permissão”.
Para instalar só as regras e os módulos, veja
[`instalacao.md`](instalacao.md) §7.

## Variáveis de ambiente

| Variável | Efeito |
|---|---|
| `LUMIVENT_NVME_SMART` | caminho alternativo do helper de SMART |
| `LUMIVENT_FANS_TRACE=1` | imprime um traço por ciclo do laço de fans em `stderr` |
| `LUMIVENT_LIGHTING_TRACE=1` | imprime tempos e latências do laço de iluminação |
| `XDG_CONFIG_HOME`, `XDG_DATA_HOME` | mudam os diretórios de dados |

Os traces são para bancada; não os deixe ativos em uso normal.

## Ferramentas de bancada

Ficam em `tool/` e exigem o app e os programas concorrentes fechados (OpenRGB,
liquidctl, CoolerControl, ckb-next).

| Ferramenta | Para que serve |
|---|---|
| `tool/hw_test_fase4.dart <step>` | teste visual de fita, placa, fans, RAM, merge e off/restore |
| `tool/alv2_stream_bench.dart <modo> <gapMs> [s]` | mede fps e estabilidade do streaming do hub AL V2 |
| `tool/gpu_test.dart <step>` | identifica a GPU e testa cores/efeitos do firmware |
| `tool/period_tap.dart <fans\|ite\|case>` | mede períodos de animações marcando picos com Enter |
| `tool/spike_hid.dart` | leitura de firmware/RPM do AL V2 e tabela do ITE (somente leitura) |
| `tool/video_led/*.py` | análise de vídeos de LED (série temporal, fase, ACF) |

Exemplos:

```sh
dart run tool/gpu_test.dart id
dart run tool/gpu_test.dart static 255,0,0 10
dart run tool/hw_test_fase4.dart fans
dart run tool/alv2_stream_bench.dart full 2 10
```

As ferramentas usam os mesmos drivers do app, incluindo as guardas de segurança.

## Estilo

- Código, comentários e testes em **inglês**; interface e mensagens ao usuário
  em **português**.
- `dart format` antes de abrir o PR.
- Prefira nomes explícitos a abreviações; evite `dynamic` nas fronteiras.
- Não use `print` no app; a engine escreve diagnóstico em `stderr`.
- Erros de hardware não derrubam a engine: registre, devolva `false` e mostre o
  motivo na UI.
- Comentários explicam **por que**, não o óbvio; referencie o documento de
  protocolo quando o número for medido.

## Adicionando funcionalidades

- **Módulo**: siga o roteiro de [`arquitetura.md`](arquitetura.md) e registre em
  `app/bootstrap.dart`/`app/engine_modules.dart`.
- **Driver**: checklist em [`CONTRIBUTING.md`](../CONTRIBUTING.md#adicionando-um-driver).
- **Efeito nativo**: `lib/features/lighting/domain/native_effects.dart` +
  testes determinísticos.
- **Efeito HTML**: o runtime fica em
  `lib/features/lighting/infrastructure/html_effects/`; a compatibilidade estática
  em `effect_compat.dart`.
- **Documentação**: atualize `README.md`, o documento temático em `docs/` e o
  `CHANGELOG.md` no mesmo PR.

## Release

Não publique versões manualmente. O fluxo de tag, validação de versão, CI e
artefatos está em [`release.md`](release.md).
