<p align="center">
  <img src="assets/icons/lumivent.svg" width="96" alt="Lumivent">
</p>

<h1 align="center">Lumivent</h1>

<p align="center">
  Iluminação RGB, curvas de fan e monitoramento de hardware no Linux —
  sem daemon root e sem webview.
</p>

<p align="center">
  <a href="https://github.com/lcsssilva/lumivent/releases/latest"><img alt="Release" src="https://img.shields.io/github/v/release/lcsssilva/lumivent?label=release&sort=semver"></a>
  <a href="https://github.com/lcsssilva/lumivent/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/lcsssilva/lumivent/actions/workflows/ci.yml/badge.svg"></a>
  <a href="LICENSE"><img alt="Licença" src="https://img.shields.io/github/license/lcsssilva/lumivent?label=licen%C3%A7a"></a>
  <img alt="Plataforma" src="https://img.shields.io/badge/plataforma-Arch%20Linux%20x86__64-1793d1">
</p>

O Lumivent é um aplicativo desktop para Linux (Flutter/GTK 3) que reúne, num
único processo de usuário:

- **monitoramento** de CPU, GPU, memória, fans, temperaturas e SMART de SSDs NVMe;
- **curvas de fan** para o hub Lian Li UNI FAN AL V2;
- **iluminação ARGB** das fans, da placa-mãe/gabinete Gigabyte, das memórias
  Kingston Fury e da GPU Gigabyte;
- **efeitos** nativos e efeitos HTML/Canvas importados de arquivos locais;
- **integração com o sistema**: bandeja, início automático e apagar ao suspender.

O acesso ao hardware é feito por `dart:ffi` (hidraw, I²C/SMBus e sysfs). Não há
serviço root, módulo de kernel próprio nem webview.

> **Status:** 1.x. O suporte é específico ao hardware validado nesta máquina —
> veja [Hardware suportado](#hardware-suportado) antes de instalar.

## Índice

- [Recursos](#recursos)
- [Hardware suportado](#hardware-suportado)
- [Instalação](#instalação)
- [Primeiros passos](#primeiros-passos)
- [Permissões e kernel](#permissões-e-kernel)
- [Configuração e dados](#configuração-e-dados)
- [Diagnóstico](#diagnóstico)
- [Desenvolvimento](#desenvolvimento)
- [Documentação](#documentação)
- [Contribuindo](#contribuindo)
- [Licença e avisos legais](#licença-e-avisos-legais)

## Recursos

### Monitoramento

- CPU: temperatura (`k10temp`), clock e uso.
- GPU: temperaturas de borda/junção/memória, uso, clock, potência, VRAM e RPM.
- Memória: uso, total e temperatura por pente (`spd5118`).
- Placa-mãe: temperaturas e RPM dos conectores via `it87` (somente leitura).
- Fans AL V2: RPM por grupo.
- SSDs NVMe: identificação por sysfs e log SMART/Health 02h via helper
  `lumivent-nvme-smart` (somente leitura).
- Histórico de 5 minutos (300 amostras de 1 s) para os gráficos.

### Fans

- Quatro grupos (portas) do hub AL V2, até 6 fans por grupo.
- Presets Quiet, Standard, High e Full, curvas Custom e UserDefine 1–4.
- Modo Fixo por porcentagem, start/stop e tamanho de fan (120/140 mm).
- Fonte de temperatura: CPU, GPU (borda/junção) ou sensores da placa-mãe.
- Resposta Normal, Rápida ou Suave (média móvel + rampa assimétrica).
- Ao sair, cada grupo recebe o duty da própria curva na última temperatura —
  o hub não executa curvas sozinho.

### Iluminação

- Canvas de 320×200 por dispositivo, com posicionamento arrastável.
- Efeitos nativos (cor sólida, espectro, respiração, varredura, onda etc.).
- Modos de hardware do firmware: fans, zonas da placa-mãe, fita do gabinete,
  memória e GPU.
- Efeitos HTML/Canvas importados de `.html`, pastas, `.zip` ou do cache de uma
  instalação Windows. Efeitos pagos (assinatura ou compra) não são importados.
- Brilho global, cor fixa por dispositivo e “Desligar todos os ARGB”.
- Apagar ao suspender/desligar via logind (inhibitor `delay`).

### Sistema

- Fechar a janela minimiza para a bandeja (configurável).
- Início automático por unidade `systemd --user` em `graphical-session.target`.
- Exportar/importar preferências, iluminação e fans em JSON.
- Diagnóstico de udev, `it87`, PIIX4, `spd5118`, helper NVMe e conflitos com
  OpenRGB, liquidctl, CoolerControl e ckb-next.

## Hardware suportado

O Lumivent foi escrito e validado contra um conjunto específico de hardware.
Outros modelos podem funcionar parcialmente, mas não são testados.

| Dispositivo | Identificação | O que o app faz |
|---|---|---|
| Hub Lian Li UNI FAN AL V2 | `0cf2:a104` (hidraw) | RPM, duty, curvas e ARGB das fans |
| Gigabyte B650E AORUS MASTER (ITE IT5702) | `048d:5702` (hidraw) | Zonas ARGB da placa, D_LED1 (gabinete) e efeitos do firmware |
| Kingston Fury DDR5 (SMBus PIIX4) | `0x61`, `0x63` | ARGB das memórias (12 LEDs por pente) |
| Gigabyte RX 9060 XT GAMING OC 8G | `AMDGPU DM i2c OEM bus`, `0x75`, SSID `0x2429` | RGB da GPU e efeitos do firmware |

Limitações conhecidas:

- Fans e bomba da placa-mãe são **somente monitorados**; a curva continua no
  BIOS/SmartGuardian.
- O RGB da GPU é liberado apenas quando o SSID `0x2429` é lido. Placas
  diferentes são recusadas por segurança.
- O hub AL V2 não roda curvas por conta própria; com o app fechado as fans ficam
  no último duty enviado.
- A tela do AIO SmartMonitor X28 está fora do escopo.

Detalhes de protocolo, guardas de segurança e engenharia reversa estão em
[`docs/hardware.md`](docs/hardware.md).

## Instalação

### Pacote pronto (Arch Linux/CachyOS, x86_64)

Cada [release](https://github.com/lcsssilva/lumivent/releases) publica o pacote
`.pkg.tar.zst` e o arquivo de checksums:

```sh
# baixe o pacote e o arquivo de checksums do release desejado
sha256sum -c lumivent-<versão>-sha256sums.txt
sudo pacman -U lumivent-<versão>-1-x86_64.pkg.tar.zst
```

Para atualizar, repita com o pacote da versão nova. O `pacman` preserva
`~/.config/lumivent/`.

### Compilando o pacote

Pré-requisitos:

- Flutter 3.47+ no `PATH` (`flutter-bin` ou `flutter` do AUR);
- `clang`, `cmake`, `ninja`, `pkgconf`, `gcc`, `libcap`;
- GTK 3, `hidapi` e as bibliotecas de runtime listadas no `PKGBUILD`.

Na raiz do repositório:

```sh
flutter config --enable-linux-desktop
makepkg -si
```

Se o Flutter vier de um SDK manual (ou de um pacote que não declara
`provides=flutter`), use `makepkg -si --nodeps` depois de conferir as demais
dependências.

O pacote instala:

| Caminho | Conteúdo |
|---|---|
| `/usr/bin/lumivent` | symlink para o binário |
| `/usr/lib/lumivent/` | bundle Flutter e o helper `lumivent-nvme-smart` |
| `/usr/share/applications/io.github.lcsssilva.lumivent.desktop` | entrada do menu |
| `/usr/share/icons/hicolor/{256x256,scalable}/apps/lumivent.*` | ícone |
| `/usr/lib/udev/rules.d/99-lumivent.rules` | ACL `uaccess` dos dispositivos |
| `/usr/lib/modprobe.d/lumivent.conf` | `it87 ignore_resource_conflict=1` |
| `/usr/lib/modules-load.d/lumivent.conf` | `it87` e `i2c-dev` no boot |
| `/usr/share/licenses/lumivent/` | licença MIT e licenças da fonte Inter (OFL) e do QuickJS |
| `/usr/share/doc/lumivent/` | README e documentação |

Depois de instalar, abra **Lumivent** pelo menu ou rode `lumivent`.

## Primeiros passos

1. **Confira as permissões** em **Configurações → Permissões e sistema**.
2. **Fans**: escolha o número de fans de cada grupo e ajuste as curvas em
   **Fans**. O grupo 0 do hub é vazio e fica sempre apagado.
3. **Iluminação**: escolha o dispositivo, o modo (Canvas, Hardware ou Cor fixa)
   e posicione o dispositivo no canvas.
4. **Efeitos**: importe efeitos HTML em **Explore** ou use os efeitos
   nativos na página de Iluminação.
5. **Sistema**: ative “Iniciar com o sistema” e “Fechar para a bandeja” se
   quiser o app sempre disponível.

### Kernel: memórias Fury

O SMBus PIIX4 usado pelas memórias só aparece com:

```
acpi_enforce_resources=lax
```

**O pacote não altera o bootloader.** No GRUB:

```sh
sudo cp -n /etc/default/grub /etc/default/grub.lumivent.bak
sudoedit /etc/default/grub
# acrescente acpi_enforce_resources=lax em GRUB_CMDLINE_LINUX_DEFAULT
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

Reinicie depois. Em systemd-boot, Limine ou rEFInd, acrescente o mesmo
parâmetro à linha do kernel. O `it87` já vem configurado pelo pacote com
`ignore_resource_conflict=1`.

## Permissões e kernel

As regras udev usam `uaccess`: só o usuário da sessão recebe ACL `rw` nos
dispositivos do app. Não é preciso entrar no grupo `i2c`, e os barramentos DDC
dos monitores ficam de fora de propósito.

| Dispositivo | Regra |
|---|---|
| Hub Lian Li AL V2 | `0cf2:a104` (hidraw) |
| ITE IT5702 da Gigabyte | `048d:5702` (hidraw) |
| SMBus PIIX4 (Fury) | nome do adaptador, porta 0 em `0x0B00` |
| RGB da GPU | `AMDGPU DM i2c OEM bus` |

Depois de instalar, desconecte/reconecte o dispositivo ou saia e entre na sessão
se a ACL ainda não aparecer:

```sh
getfacl /dev/i2c-* 2>/dev/null | grep -B2 -A4 "$USER"
getcap /usr/lib/lumivent/lumivent-nvme-smart
```

O helper do SMART usa `cap_sys_admin` (Get Log Page 02h) e
`cap_dac_read_search` (abrir `/dev/nvmeN`). Ele é somente leitura.

## Configuração e dados

| Caminho | Conteúdo |
|---|---|
| `~/.config/lumivent/config.json` | preferências, iluminação e fans |
| `~/.config/lumivent/config.json.antes-import` | backup criado ao importar |
| `~/.config/lumivent/config.json.bad` | cópia de um arquivo corrompido |
| `~/.local/share/lumivent/effects/` | efeitos HTML importados |

Os caminhos respeitam `XDG_CONFIG_HOME` e `XDG_DATA_HOME`.
Exportar/importar tudo fica em **Configurações**. A desinstalação do pacote não
apaga esses arquivos.

O formato do `config.json`, as seções e a política de compatibilidade estão em
[`docs/configuracao.md`](docs/configuracao.md).

## Diagnóstico

No app: **Configurações → Permissões e sistema**. A tela mostra regras udev,
`it87`, SMBus/PIIX4, `spd5118`, helper do NVMe, laço da iluminação e o estado dos
dispositivos. O cartão de cada dispositivo mostra o motivo quando algo falta.

Fora do app:

```sh
i2cdetect -l
sensors
/usr/lib/lumivent/lumivent-nvme-smart nvme0 nvme1
sudo nvme smart-log /dev/nvme0
dart run tool/gpu_test.dart identify
```

Sintomas e correções: [`docs/solucao-de-problemas.md`](docs/solucao-de-problemas.md).

## Desenvolvimento

```sh
flutter pub get
flutter run -d linux
flutter test
flutter analyze
```

O bundle de release fica em `build/linux/x64/release/bundle/`. Para usar o helper
sem instalar:

```sh
cc -O2 -Wall -Wextra -Werror -o build/lumivent-nvme-smart tool/lumivent-nvme-smart/lumivent-nvme-smart.c
LUMIVENT_NVME_SMART=$PWD/build/lumivent-nvme-smart \
  build/linux/x64/release/bundle/lumivent
```

As ferramentas de bancada ficam em `tool/` (`hw_test_fase4.dart`,
`alv2_stream_bench.dart`, `gpu_test.dart`, `period_tap.dart`) e pedem o app
fechado.

Guia completo (arquitetura, testes, como adicionar módulo/driver/efeito):
[`docs/desenvolvimento.md`](docs/desenvolvimento.md).

## Documentação

| Documento | Assunto |
|---|---|
| [`docs/instalacao.md`](docs/instalacao.md) | instalação, kernel, permissões, desinstalação |
| [`docs/arquitetura.md`](docs/arquitetura.md) | módulos, camadas, engine e fluxo de dados |
| [`docs/desenvolvimento.md`](docs/desenvolvimento.md) | ambiente, testes, estilo e extensão |
| [`docs/configuracao.md`](docs/configuracao.md) | formato do `config.json` e migração |
| [`docs/hardware.md`](docs/hardware.md) | protocolos, guardas e limitações |
| [`docs/release.md`](docs/release.md) | versionamento, tags e publicação do `.pkg` |
| [`docs/solucao-de-problemas.md`](docs/solucao-de-problemas.md) | diagnóstico e correções |
| [`CHANGELOG.md`](CHANGELOG.md) | histórico de versões |
| [`docs/README.md`](docs/README.md) | índice da documentação |

## Contribuindo

Contribuições são bem-vindas, especialmente relatos de hardware novo, correções
de protocolo e melhorias de acessibilidade. Leia
[`CONTRIBUTING.md`](CONTRIBUTING.md) e o
[Código de Conduta](CODE_OF_CONDUCT.md) antes de abrir um PR.

- Bugs e ideias: [issues](https://github.com/lcsssilva/lumivent/issues).
- Vulnerabilidades: siga [`SECURITY.md`](SECURITY.md) (não abra issue pública).
- Versões: [SemVer](https://semver.org/lang/pt-BR/), tags `vX.Y.Z`, releases com
  pacote `.pkg.tar.zst` e checksums. Veja [`docs/release.md`](docs/release.md).

## Licença e avisos legais

O código do Lumivent é distribuído sob a licença **MIT** — veja [`LICENSE`](LICENSE).
A fonte Inter é distribuída sob a SIL Open Font License 1.1 e o motor QuickJS
(embutido pelo `flutter_js`) sob a licença MIT. Os textos de todas as licenças
ficam em **Configurações → Sobre → Licenças** e em `/usr/share/licenses/lumivent/`.

Este é um projeto independente, **não afiliado** à Lian Li, Gigabyte, Kingston
ou AORUS. Marcas citadas pertencem aos seus donos.

O Lumivent não inclui nem distribui efeitos, arquivos ou recursos proprietários
de terceiros. A importação lê apenas arquivos que o
usuário já possui, na própria máquina. As notas de engenharia reversa e os
artefatos de terceiros usados durante o desenvolvimento **não fazem parte** da
distribuição pública.
