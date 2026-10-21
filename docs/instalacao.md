# Instalação e permissões

Este documento substitui os antigos `packaging/setup-fase0.sh` e
`packaging/setup-fase2.sh`. O caminho normal é o pacote pronto do release ou o
`makepkg`; o caminho manual, para desenvolvimento ou outra distro, está no fim.

## 1. Pacote pronto (GitHub Releases)

Cada [release](https://github.com/lcsssilva/lumivent/releases/latest) publica um
pacote para Arch Linux/CachyOS `x86_64` e o arquivo de checksums:

- `lumivent-X.Y.Z-1-x86_64.pkg.tar.zst`;
- `lumivent-X.Y.Z-sha256sums.txt`.

Baixe os dois, confira o checksum e instale:

```sh
sha256sum -c lumivent-X.Y.Z-sha256sums.txt
sudo pacman -U lumivent-X.Y.Z-1-x86_64.pkg.tar.zst
```

O `pacman` resolve as dependências e chama o `post_install`, que recarrega o
udev. Para atualizar, baixe o artefato da versão nova e repita o comando. A
configuração em `~/.config/lumivent/` é preservada.

```sh
pacman -Q lumivent
pacman -Ql lumivent | grep /usr/share/doc
```

Reconstruções só de empacotamento mantêm a versão e aumentam o `pkgrel`
(`...-2-x86_64.pkg.tar.zst`); use sempre o artefato mais recente do release.
Ainda não há pacote oficial no AUR; o contrato de publicação está em
[`release.md`](release.md).

Se o checksum falhar, não instale: baixe de novo e confirme que o arquivo veio
da página oficial de releases.

## 2. Compilar o pacote (Arch/CachyOS)

Pré-requisitos de compilação:

- Flutter 3.47 ou mais novo no `PATH` (`flutter-bin` ou `flutter` do AUR);
- `clang`, `cmake`, `ninja`, `pkgconf`, `gcc` e `libcap` (o `makepkg` instala os
  `makedepends` se você confirmar);
- GTK 3, `hidapi` e as bibliotecas de runtime listadas no `PKGBUILD`.

Na raiz do projeto:

```sh
flutter config --enable-linux-desktop
makepkg -si
```

Se o Flutter vier de um SDK manual (ou de um pacote que não declara
`provides=flutter`), use `makepkg -si --nodeps` depois de conferir as demais
dependências.

O `makepkg` compila o bundle Linux em modo release, compila o helper do SMART e
monta o pacote. Para só gerar o arquivo, sem instalar:

```sh
makepkg
```

Para atualizar depois de mudar o código:

```sh
makepkg -si
```

### O que o pacote instala

| Caminho | Conteúdo |
|---|---|
| `/usr/bin/lumivent` | symlink para o binário |
| `/usr/lib/lumivent/` | bundle do Flutter (`lumivent`, `data/`, `lib/`) e o helper `lumivent-nvme-smart` |
| `/usr/share/applications/io.github.lcsssilva.lumivent.desktop` | entrada do menu |
| `/usr/share/icons/hicolor/{256x256,scalable}/apps/lumivent.*` | ícone |
| `/usr/lib/udev/rules.d/99-lumivent.rules` | `uaccess` dos dispositivos usados pelo app |
| `/usr/lib/modprobe.d/lumivent.conf` | `it87 ignore_resource_conflict=1` |
| `/usr/lib/modules-load.d/lumivent.conf` | `it87` e `i2c-dev` no boot |
| `/usr/share/licenses/lumivent/` | licença MIT e licenças da fonte Inter (OFL) e do QuickJS |
| `/usr/share/doc/lumivent/` | README, CHANGELOG, instalação, configuração, diagnóstico e hardware |

O helper fica com `cap_sys_admin,cap_dac_read_search+ep`. Confira:

```sh
getcap /usr/lib/lumivent/lumivent-nvme-smart
```

O `cap_sys_admin` é necessário porque o kernel só permite o `Get Log Page 02h`
do NVMe com essa capability; `cap_dac_read_search` permite abrir
`/dev/nvmeN` (root:root, 600). O helper é somente leitura: o único comando que
ele envia é o log SMART.

## 3. Kernel: `acpi_enforce_resources=lax`

O SMBus PIIX4 (`0x0B00`, usado pelas memórias Kingston Fury) só aparece com
`acpi_enforce_resources=lax`. **O pacote não altera o bootloader.** No GRUB:

```sh
sudo cp -n /etc/default/grub /etc/default/grub.lumivent.bak
sudoedit /etc/default/grub
# acrescente acpi_enforce_resources=lax dentro de GRUB_CMDLINE_LINUX_DEFAULT
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

Exemplo:

```sh
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash acpi_enforce_resources=lax"
```

Reinicie. Em outros bootloaders (systemd-boot, Limine, rEFInd), acrescente o
mesmo parâmetro à linha do kernel. Confira:

```sh
cat /proc/cmdline
i2cdetect -l | grep PIIX4
sensors
```

O `it87` é carregado pelo `modules-load.d` com `ignore_resource_conflict=1`
(arquivo do pacote). Se a versão do kernel não reconhecer o IT8689E, veja o
`it87-dkms-git` do AUR.

## 4. Permissões dos dispositivos

As regras usam `uaccess`: só o usuário logado na sessão recebe ACL `rw`, sem
adicionar ninguém ao grupo `i2c` (o grupo liberaria também os barramentos DDC
dos monitores). O `post_install` recarrega o udev. Se o dispositivo já estava
conectado e a ACL não aparecer, desconecte/reconecte ou saia e entre na sessão.

```sh
getfacl /dev/hidraw* 2>/dev/null | grep -B2 -A4 "$USER"
getfacl /dev/i2c-* 2>/dev/null | grep -B2 -A4 "$USER"
```

As regras cobrem:

- `0cf2:a104` — hub Lian Li UNI FAN AL V2 (fans e ARGB);
- `048d:5702` — ITE IT5702 da Gigabyte (placa-mãe e ARGB do gabinete);
- `SMBus PIIX4 adapter port 0 at 0b00` — memórias Fury;
- `AMDGPU DM i2c OEM bus` — RGB da GPU, no endereço `0x75`.

Os barramentos DDC dos monitores ficam de fora de propósito.

## 5. Diagnóstico

No app: **Configurações → Permissões e sistema**. A tela mostra as regras udev
(instaladas em `/usr/lib/udev/rules.d` ou, no modo antigo,
`/etc/udev/rules.d`), os sensores do `it87`, o SMBus da memória, o `spd5118` e o
helper do NVMe. O cartão de cada dispositivo mostra o estado e a dica.

Fora do app:

```sh
# dispositivos e módulos
i2cdetect -l
lsmod | grep -E 'it87|i2c_dev'
sensors it8689-isa-0a40

# SSDs (o mesmo que o app lê; não precisa de sudo)
/usr/lib/lumivent/lumivent-nvme-smart nvme0 nvme1

# comparação com a ferramenta oficial
sudo nvme smart-log /dev/nvme0

# GPU: identificação (fw 1.1 e SSID 0x2429)
dart run tool/gpu_test.dart identify
```

Se a tela acusar falta de permissão, confira a ACL e o `acpi_enforce_resources`.
Se acusar falta do helper, confira `getcap` e o caminho
`/usr/lib/lumivent/lumivent-nvme-smart`.

## 6. Início automático

O app usa uma unidade `systemd --user` (`lumivent.service`) que aponta para o
binário que está rodando, normalmente `/usr/lib/lumivent/lumivent`. Ative em
**Configurações → Iniciar com a sessão**. Para conferir:

```sh
systemctl --user status lumivent.service
```

## 7. Desinstalar

```sh
sudo pacman -Rns lumivent
```

A configuração (`~/.config/lumivent/config.json`) e os efeitos importados
(`~/.local/share/lumivent/effects/`) ficam no home e não são removidos pelo pacote.

## 8. Instalação manual (desenvolvimento/sem pacote)

Sem `makepkg`, instale os mesmos arquivos à mão. Isto é o que os antigos
`setup-fase0.sh`/`setup-fase2.sh` faziam; use somente se souber o que está
fazendo.

```sh
# regras, módulos e parâmetros
sudo install -Dm644 packaging/99-lumivent.rules /etc/udev/rules.d/99-lumivent.rules
sudo install -Dm644 packaging/modprobe-lumivent.conf /etc/modprobe.d/lumivent.conf
sudo install -Dm644 packaging/modules-load-lumivent.conf /etc/modules-load.d/lumivent.conf
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=hidraw --subsystem-match=i2c-dev
sudo modprobe i2c-dev
sudo modprobe it87 ignore_resource_conflict=1

# helper do SMART
cc -O2 -Wall -Wextra -Werror -o /tmp/lumivent-nvme-smart tool/lumivent-nvme-smart/lumivent-nvme-smart.c
sudo install -Dm755 /tmp/lumivent-nvme-smart /usr/lib/lumivent/lumivent-nvme-smart
sudo setcap cap_sys_admin,cap_dac_read_search+ep /usr/lib/lumivent/lumivent-nvme-smart

# app (bundle de desenvolvimento)
flutter build linux --release
build/linux/x64/release/bundle/lumivent
```

Para rodar o bundle de desenvolvimento, o app também aceita o helper em
`$LUMIVENT_NVME_SMART`:

```sh
LUMIVENT_NVME_SMART=$PWD/build/lumivent-nvme-smart build/linux/x64/release/bundle/lumivent
```
