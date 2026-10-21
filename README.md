<p align="center">
  <img src="assets/icons/lumivent.svg" width="96" alt="Lumivent">
</p>

<h1 align="center">Lumivent</h1>

<p align="center">
  RGB lighting, fan curves and hardware monitoring on Linux —
  no root daemon and no webview.
</p>

<p align="center">
  <a href="https://github.com/lcsssilva/lumivent/releases/latest"><img alt="Release" src="https://img.shields.io/github/v/release/lcsssilva/lumivent?label=release&sort=semver"></a>
  <a href="https://github.com/lcsssilva/lumivent/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/lcsssilva/lumivent/actions/workflows/ci.yml/badge.svg"></a>
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/github/license/lcsssilva/lumivent"></a>
  <img alt="Platform" src="https://img.shields.io/badge/platform-Arch%20Linux%20x86__64-1793d1">
</p>

Lumivent is a Linux desktop app (Flutter/GTK 3) that brings together, in a
single user process:

- **monitoring** of CPU, GPU, memory, fans, temperatures and NVMe SSD SMART data;
- **fan curves** for the Lian Li UNI FAN AL V2 hub;
- **ARGB lighting** for the fans, the Gigabyte motherboard/case strip, Kingston
  Fury memory and the Gigabyte GPU;
- **effects**: built-in effects and HTML/Canvas effects imported from local files;
- **desktop integration**: system tray, autostart and lights off on suspend.

Hardware access goes through `dart:ffi` (hidraw, I²C/SMBus and sysfs). There is
no root service, no custom kernel module and no webview.

> **Status:** 1.x. Support targets a specific, validated set of hardware —
> check [Supported hardware](#supported-hardware) before installing.
>
> The interface is available in English (the default) and Portuguese. Choose
> **Settings → Preferences → Language** (**Configurações → Preferências →
> Idioma**) to switch; the change applies at once and is saved in `config.json`.
> The user guide below shows the English and Portuguese labels where they
> differ.

## Contents

- [Features](#features)
- [Supported hardware](#supported-hardware)
- [Installation](#installation)
- [Kernel and permissions](#kernel-and-permissions)
- [User guide](#user-guide)
- [Configuration and data](#configuration-and-data)
- [Troubleshooting](#troubleshooting)
- [Development](#development)
- [Contributing](#contributing)
- [License and legal notice](#license-and-legal-notice)

## Features

### Monitoring

- CPU: temperature (`k10temp`), clock and load.
- GPU: edge/junction/memory temperatures, load, clock, power, VRAM and fan RPM.
- Memory: usage, total and per-module temperature (`spd5118`).
- Motherboard: temperatures and header RPM via `it87` (read-only).
- AL V2 fans: RPM per group.
- NVMe SSDs: identification from sysfs and the SMART/Health log through the
  read-only `lumivent-nvme-smart` helper.
- 5-minute history (300 samples, one per second) for the charts.

### Fans

- Four groups (ports) on the AL V2 hub, up to 6 fans per group.
- Quiet, Standard, High and Full presets, custom curves and four user curves.
- Fixed percentage mode, start/stop and fan size (120/140 mm).
- Temperature source: CPU, GPU (edge/junction) or motherboard sensors.
- Normal, Fast or Smooth response (moving average plus asymmetric ramp).
- On exit, each group gets the duty from its own curve at the last
  temperature — the hub cannot run curves by itself.

### Lighting

- A 320×200 canvas with draggable, resizable device placement.
- Built-in effects (solid color, color cycle, rainbow wave, breathing, scanner
  and more).
- Firmware modes for the fans, motherboard zones, case strip and GPU.
- HTML/Canvas effects imported from `.html` files, folders, `.zip` archives or
  the effect cache of an existing Windows installation. Paid effects
  (subscription or purchase) are never imported.
- Global brightness, per-device fixed color and "turn off all ARGB".
- Lights off on suspend/shutdown through logind (`delay` inhibitor).

### System

- Closing the window hides it to the tray (configurable).
- Autostart through a `systemd --user` unit bound to `graphical-session.target`.
- Export/import of preferences, lighting and fans as JSON.
- Diagnostics for udev, `it87`, PIIX4, `spd5118`, the NVMe helper and conflicts
  with OpenRGB, liquidctl, CoolerControl and ckb-next.

## Supported hardware

Lumivent was written and validated against a specific set of hardware. Other
models may partially work but are not tested.

| Device | Identified by | What the app does |
|---|---|---|
| Lian Li UNI FAN AL V2 hub | USB `0cf2:a104` (hidraw) | RPM, duty, curves and fan ARGB |
| Gigabyte B650E AORUS MASTER (ITE IT5702) | USB `048d:5702` (hidraw) | Motherboard ARGB zones, case strip and firmware effects |
| Kingston Fury DDR5 | SMBus PIIX4 adapter | Memory ARGB (12 LEDs per module) |
| Gigabyte RX 9060 XT GAMING OC 8G | `AMDGPU DM i2c OEM bus`, subsystem ID `0x2429` | GPU RGB and firmware effects |

Known limitations:

- Motherboard fans and pump are **monitored only**; their curves stay in the
  BIOS.
- GPU RGB is enabled only after the subsystem ID `0x2429` is read. Other boards
  are refused for safety.
- The AL V2 hub does not run curves on its own; with the app closed, the fans
  stay at the last duty sent.
- The SmartMonitor X28 AIO display is out of scope.

## Installation

### Prebuilt package (Arch Linux/CachyOS, x86_64)

Each [release](https://github.com/lcsssilva/lumivent/releases) publishes two
files, named after its version (for example, `v1.0.0`):

- `lumivent-1.0.0-1-x86_64.pkg.tar.zst` — the package;
- `lumivent-1.0.0-sha256sums.txt` — its checksum.

Download both into a new, empty directory, verify the checksum and install.
With the [GitHub CLI](https://cli.github.com/) (works in bash, zsh and fish):

```sh
mkdir lumivent-release && cd lumivent-release
gh release download --repo lcsssilva/lumivent --pattern 'lumivent-*'
sha256sum -c lumivent-*-sha256sums.txt
sudo pacman -U lumivent-*-x86_64.pkg.tar.zst
```

`gh release download` without a tag fetches the latest release; append a tag
(`gh release download v1.0.0 --repo lcsssilva/lumivent`) for a specific one.
Without `gh`, download both files from the releases page in your browser, then
run the last two commands in the directory where they were saved. The checksum
file refers to the package by name, so both must be in the same directory.

`sha256sum -c` must report `OK` (localized, e.g. `SUCESSO`). If it reports
`FAILED` or a missing file, do not install: download again from the official
releases page. To upgrade, repeat the steps in a new, empty directory (so the
wildcards match only the new files); `pacman` keeps `~/.config/lumivent/`.
Packaging-only rebuilds keep the version and bump the `pkgrel`
(`...-2-x86_64.pkg.tar.zst`); always use the latest artifact of a release.

### Building the package

Requirements:

- Flutter 3.47+ on `PATH` (`flutter-bin` or `flutter` from the AUR);
- `clang`, `cmake`, `ninja`, `pkgconf`, `gcc`, `libcap`;
- GTK 3, `hidapi` and the runtime libraries listed in the `PKGBUILD`.

From the repository root:

```sh
flutter config --enable-linux-desktop
makepkg -si
```

If Flutter comes from a manual SDK (or a package that does not declare
`provides=flutter`), use `makepkg -si --nodeps` after checking the other
dependencies. Use `makepkg` alone to build the package without installing it.

### What the package installs

| Path | Contents |
|---|---|
| `/usr/bin/lumivent` | symlink to the binary |
| `/usr/lib/lumivent/` | Flutter bundle and the `lumivent-nvme-smart` helper |
| `/usr/share/applications/io.github.lcsssilva.lumivent.desktop` | menu entry |
| `/usr/share/icons/hicolor/{256x256,scalable}/apps/lumivent.*` | icon |
| `/usr/lib/udev/rules.d/99-lumivent.rules` | `uaccess` ACLs for the devices |
| `/usr/lib/modprobe.d/lumivent.conf` | `it87 ignore_resource_conflict=1` |
| `/usr/lib/modules-load.d/lumivent.conf` | loads `it87` and `i2c-dev` at boot |
| `/usr/share/licenses/lumivent/` | MIT license plus the Inter font (OFL) and QuickJS licenses |
| `/usr/share/doc/lumivent/` | this README and the CHANGELOG |

Then open **Lumivent** from the menu or run `lumivent`.

### Uninstalling

```sh
sudo pacman -Rns lumivent
```

Your configuration (`~/.config/lumivent/`) and imported effects
(`~/.local/share/lumivent/effects/`) stay in your home directory.

### Manual installation (development, no package)

Install the same files by hand only if you know what you are doing:

```sh
# rules, modules and parameters
sudo install -Dm644 packaging/99-lumivent.rules /etc/udev/rules.d/99-lumivent.rules
sudo install -Dm644 packaging/modprobe-lumivent.conf /etc/modprobe.d/lumivent.conf
sudo install -Dm644 packaging/modules-load-lumivent.conf /etc/modules-load.d/lumivent.conf
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=hidraw --subsystem-match=i2c-dev
sudo modprobe i2c-dev
sudo modprobe it87 ignore_resource_conflict=1

# SMART helper
cc -O2 -Wall -Wextra -Werror -o /tmp/lumivent-nvme-smart tool/lumivent-nvme-smart/lumivent-nvme-smart.c
sudo install -Dm755 /tmp/lumivent-nvme-smart /usr/lib/lumivent/lumivent-nvme-smart
sudo setcap cap_sys_admin,cap_dac_read_search+ep /usr/lib/lumivent/lumivent-nvme-smart
```

## Kernel and permissions

### Kernel parameter for Fury memory

The PIIX4 SMBus used by the memory modules only shows up with:

```
acpi_enforce_resources=lax
```

**The package does not touch your bootloader.** With GRUB:

```sh
sudo cp -n /etc/default/grub /etc/default/grub.lumivent.bak
sudoedit /etc/default/grub
# add acpi_enforce_resources=lax to GRUB_CMDLINE_LINUX_DEFAULT
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

Reboot afterwards. With systemd-boot, Limine or rEFInd, add the same parameter
to the kernel command line. Check with:

```sh
cat /proc/cmdline
i2cdetect -l | grep PIIX4
```

The package already loads `it87` with `ignore_resource_conflict=1`. If your
kernel does not recognize the IT8689E chip, see `it87-dkms-git` on the AUR.

### Device permissions

The udev rules use `uaccess`: only the user logged into the session gets an
`rw` ACL on the app's devices. You do **not** need to join the `i2c` group —
doing so would also expose the monitors' DDC buses, which the rules leave out on
purpose.

| Device | Rule matches |
|---|---|
| Lian Li AL V2 hub | `0cf2:a104` (hidraw) |
| Gigabyte ITE IT5702 | `048d:5702` (hidraw) |
| PIIX4 SMBus (Fury) | the adapter name, port 0 |
| GPU RGB | `AMDGPU DM i2c OEM bus` |

If an ACL does not show up after installing, unplug/replug the device or log
out and back in:

```sh
getfacl /dev/hidraw* /dev/i2c-* 2>/dev/null | grep -B2 -A4 "$USER"
getcap /usr/lib/lumivent/lumivent-nvme-smart
```

The SMART helper uses `cap_sys_admin` (the kernel requires it for the NVMe Get
Log Page command) and `cap_dac_read_search` (to open `/dev/nvmeN`). It is
read-only: the SMART log is the only command it sends.

## User guide

### The window

- **Sidebar**: the five pages and, at the bottom, a summary of the detected
  devices (AL V2 hub, ITE 5702, memory, GPU). The dot color shows the state;
  hover it for the reason.
- **Top bar**: CPU (`Tctl`) and GPU (edge) temperatures, the **ARGB** button
  (turns every LED on or off at once) and a shortcut to **Configurações**
  (Settings).
- **Tray**: with **Manter na bandeja ao fechar** (keep in tray on close)
  enabled, closing the window only hides it. The tray menu has show/hide
  window, **Desligar todos os ARGB** (turn off all ARGB) and **Sair** (quit).
  Fan curves and effects keep running while the window is hidden.

Device states shown throughout the app:

| Label | Meaning |
|---|---|
| Conectado (connected) | open and responding |
| Não encontrado (not found) | not present (unplugged or a different model) |
| Sem permissão (no permission) | present, but the udev rule has not granted access to the session yet |
| Indisponível (unavailable) | stopped responding; the app retries every 5 s |
| Bloqueado (blocked) | refused by a safety check (e.g. a different GPU subsystem ID) |
| Sem suporte (unsupported) | model or firmware not supported |
| Erro (error) | unexpected failure; the device card shows the details |

### First run

1. Open **Configurações → Permissões e sistema** (Settings → Permissions and
   system) and check that every item is green. If a device shows "Sem
   permissão", log out and back in (or replug the device).
2. In **Configurações → Dispositivos** (Devices), check whether a competing
   program (OpenRGB, liquidctl, CoolerControl, ckb-next) was detected. Close it
   before using lighting and fans: two programs on the same device fight over
   it. Lumivent only warns; it never kills processes.
3. In **Iluminação** (Lighting), set how many fans each group has — see
   [Fans per group](#fans-per-group).
4. In **Fans**, pick a curve for each group. Hub group 0 is empty and always
   off.
5. In **Configurações → Inicialização** (Startup), enable **Iniciar com o
   sistema** (start with the system) if you want the app always running.

### Monitoring (Monitoramento)

Sensors are read every second; charts cover the last 5 minutes, with the
minimum and maximum of the period.

| Card | Shows |
|---|---|
| CPU | `Tctl`, `CCD 1`, average clock and load |
| GPU | junction, edge and memory temperatures, clock, power, VRAM and fan RPM |
| Memória (memory) | total usage and the temperature of each module |
| Placa-mãe (motherboard) | motherboard temperatures and header RPM (read-only) |
| Fans AL V2 | RPM of each hub group |
| Armazenamento (storage) | NVMe SSDs: model, firmware, life remaining, temperature, data written and power-on hours |

- "parado (zero-fan)" means the GPU stopped its fan at low temperature, which is
  normal. "parado (GPU quente!)" means the fan is stopped while the GPU is hot.
- SSD SMART data refreshes every minute. **Detalhes** (details) opens the full
  SMART/Health log.
- "Sem sensores da placa-mãe" (no motherboard sensors) means `it87` is not
  loaded. "SMART indisponível" (SMART unavailable) means the helper is missing
  or lacks its capabilities.

### Fans

The app runs the curve every second; the hub cannot run curves by itself.

**Pick a group.** Each tile at the top shows the group name, fan size and
current RPM ("sem fan" when the group has never spun). Click a tile to edit it.
The group header has:

- **Nome do grupo** (group name), up to 24 characters; it is also used in
  Lighting;
- **120 mm / 140 mm**, which sets the maximum RPM used to convert percent to RPM;
- **RPM atual** (current RPM), **Duty** and **Alvo** (target);
- warnings "Sem temperatura" (the chosen source has no reading, so the group is
  not updated) and "Hub indisponível" (hub unavailable).

**Speed curve (Curva de velocidade).**

| Preset | Behavior |
|---|---|
| Quiet, Standard, High, Full | factory curves; editing a point turns the curve into **Personalizado** (custom) |
| Fixo (fixed) | a single speed; drag the point up or down |
| Usuário 1–4 (user 1–4) | four curves of your own, saved per group; edits stay in that slot |
| Personalizado (custom) | a curve edited from a factory preset |

In the editor: drag a point to change temperature and speed, **double-click**
to add a point (up to 8) and **right-click** to remove one. The thin line shows
the last minute (temperature × RPM) and the marker shows the current
temperature and duty.

**Group options (Opções do grupo).**

- **Start/Stop**: stops the fans below the temperature of the first point.
- **Fonte de temperatura** (temperature source): CPU (`Tctl`), GPU (junction or
  edge) or a motherboard sensor (System 1/2, PCH, CPU socket, VRM, PCIEX16,
  PCIEX4). Use CPU/GPU for radiators and motherboard temperatures for case fans.
- **Resposta à temperatura** (temperature response):

  | Response | Average | Ramp up | Ramp down |
  |---|---|---|---|
  | Rápida (fast) | none | immediate | immediate |
  | Normal | 4 s | up to 15 %/s | up to 3 %/s |
  | Suave (smooth) | 10 s | up to 5 %/s | up to 1 %/s |

  When the average differs from the instant reading, the header shows both
  ("CPU Tctl 61 °C (agora 68 °C)").

**Aplicar curva a todos** (apply curve to all) copies preset, points,
start/stop, source and response from the current group to the others.

When the app exits, each group receives the duty from its own curve at the last
temperature and stays there until the app runs again.

### Lighting (Iluminação)

**Global controls.**

- **Brilho** (brightness) scales every device.
- **Apagar ao suspender ou desligar** (turn off on suspend or shutdown) turns
  the LEDs off before the system sleeps or powers off, and back on at resume.
- **Usar os efeitos do próprio hardware quando possível** (use the hardware's
  own effects when possible): when the canvas effect has a firmware equivalent
  (fans and motherboard), the device animates it by itself, with smoother
  motion, and is tagged "Hardware (auto)". The phase between devices may not
  match exactly. Without it, fans receive about 2 frames per second so their RPM
  does not fluctuate.
- **ARGB** in the top bar turns every LED off; a yellow banner stays visible
  until you press **Ligar** (turn on).

**Devices and modes.** The **Dispositivos** strip lists the fan groups 1–3,
**Gabinete** (case), **Placa-mãe** (motherboard), **Memória 1/2** (memory) and
**Placa de vídeo** (GPU). Each entry has an on/off switch and a mode:

| Mode | Who decides the color | Available on |
|---|---|---|
| Canvas | the global effect, sampled at each LED position | all devices |
| Hardware | the device's firmware modes | fans, motherboard, GPU |
| Cor fixa (fixed color) | one color from the picker | all devices |

The right-hand panel changes with the selected device's mode.

**Canvas.** The 320×200 canvas shows the effect behind the devices in Canvas or
fixed-color mode. Drag a device to move it and drag its corner to resize it.
The GPU has no addressable LEDs: its rectangle is the area whose average color
it shows. Devices in Hardware mode or turned off are not drawn.

Below the canvas, **Biblioteca de efeitos** (effect library) lists the built-in
effects and the HTML effects imported in [Explore](#explore). The **Efeito**
(effect) panel shows the controls of the selected effect; for HTML effects it
also shows the real frame rate and frame time.

**Hardware mode on fans.** Choose **Ventoinha inteira** (whole fan) or
**Interno + externo** (inner + outer rings), then mode, speed, brightness,
direction and colors. **Identificar** (identify) blinks the group so you can
tell which port is which. **Merge entre grupos** (merge across groups) runs one
effect across all groups in sequence; use **Ordem do merge** (merge order) to
follow the physical path of your fans.

#### Fans per group

The **Ventoinhas no grupo** (fans in group, 0–6) control lives in the Hardware
panel of each fan group. The count applies to every mode: it defines how many
LEDs the group has on the canvas. To change it for a group in Canvas mode,
switch the group to Hardware, adjust the count and switch back.

**Hardware mode on the motherboard and GPU.** The motherboard has mode, color,
speed and brightness per zone (IO Shield 1 and 2, CPU LED). The GPU has mode,
speed and brightness (1–10) and up to 8 colors; the app only sends colors after
confirming the board's subsystem ID, and the GPU is marked unavailable if that
read fails.

When the app exits, the LEDs stay as they were.

### Explore

The local library of imported HTML/Canvas effects.

| Button | Accepts |
|---|---|
| **Importar efeito…** (import effect) | one or more `.html`/`.htm` or `.zip` files |
| **Pasta…** (folder) | a folder with one or more effects (`effect.html`) |
| **Importar do Windows…** (import from Windows) | the effects folder (or its `cache` folder) of a Windows installation already on this machine |

A message summarizes what was imported. Paid effects are never imported. Files
go to `~/.local/share/lumivent/effects/`.

Search by name, author or tag, and filter by compatibility (**Compatíveis**,
**Parciais**, **Não suportados** — compatible, partial, unsupported), category
and author. "Partial" means the effect uses browser features Lumivent does not
implement: it runs but may look different. Unsupported effects cannot be
applied. **Aplicar** (apply) puts the effect on the canvas; tune it in Lighting.
**Remover da biblioteca** (remove from library) deletes the files; if the effect
was in use, it is replaced by the default effect.

Only import effects from sources you trust: an effect runs JavaScript inside the
app's QuickJS runtime.

### Settings (Configurações)

| Card | Contents |
|---|---|
| Inicialização (startup) | **Iniciar com o sistema**: a `systemd --user` unit that starts minimized in the tray. If the unit points to another executable, turn it off and on again |
| Preferências (preferences) | language (**English** / **Português**, applies immediately), keep in tray on close, temperature unit (°C/°F) and effect frame rate (15, 30 or 60 fps) |
| Configuração (configuration) | **Exportar…** / **Importar…** (export/import) preferences, lighting and fans as JSON |
| Dispositivos (devices) | state of each device, **Detectar novamente** (detect again) and competing-program warnings |
| Permissões e sistema (permissions and system) | checks for udev rules, `it87`, SMBus/PIIX4, `spd5118`, the NVMe helper and the lighting loop |
| Sobre (about) | version, license and **Licenças…** (licenses of every bundled dependency) |

### Accessibility

- Controls are standard Flutter widgets: **Tab** to move, **Space/Enter** to
  activate, tooltips on hover.
- Device state never relies on color alone: cards and tooltips also show the
  state as text.
- The curve editor and the canvas need a mouse (drag, double-click,
  right-click). Factory presets and saved user curves can be selected without
  dragging points.

## Configuration and data

| Path | Contents |
|---|---|
| `~/.config/lumivent/config.json` | preferences, lighting and fans |
| `~/.config/lumivent/config.json.antes-import` | backup taken before an import |
| `~/.config/lumivent/config.json.bad` | a corrupted file, preserved |
| `~/.local/share/lumivent/effects/<id>/` | imported effects |
| `~/.config/systemd/user/lumivent.service` | autostart unit, when enabled |

Paths follow `XDG_CONFIG_HOME` and `XDG_DATA_HOME`. Uninstalling the package
does not delete them.

How the configuration file is handled:

- **Atomic writes**: the app writes a temporary file and renames it.
- **Tolerant reads**: a missing key, a wrong type or an unknown value falls back
  to the default, so older or hand-edited files still open.
- **Corruption**: invalid JSON is renamed to `config.json.bad` (never silently
  overwritten) and the app starts with defaults.
- **Import**: replaces the preferences, lighting and fans sections in a single
  write, after copying the current file to `config.json.antes-import`. Files
  from a newer schema version are refused. The import applies immediately, with
  no restart.

Close the app before editing `config.json` by hand; otherwise the next save
overwrites your changes. For backups, prefer **Configurações → Configuração →
Exportar…**.

The `preferences` section:

| Key | Type | Default | Description |
|---|---|---|---|
| `closeToTray` | bool | `true` | closing the window only hides it to the tray |
| `temperatureUnit` | `"celsius"` \| `"fahrenheit"` | `"celsius"` | unit shown in the interface |
| `effectsFps` | `15` \| `30` \| `60` | `30` | frame rate of the lighting loop |
| `language` | `"en"` \| `"pt"` | `"en"` | interface language; missing or invalid values fall back to English |

## Troubleshooting

Start with **Configurações → Permissões e sistema**; each device card also
shows why something is missing. Run `lumivent` from a terminal to see engine
errors on `stderr`.

| Symptom | Likely cause and fix |
|---|---|
| `error while loading shared libraries` | missing dependency: `sudo pacman -S --needed gtk3 hidapi libcap` |
| window does not appear, process stays alive | started with `--minimized`: open it from the tray icon |
| app closes right away | corrupted configuration: see the `config.json.bad` notes above |
| device shows "Sem permissão" | check the ACL with `getfacl` (above), then `sudo udevadm control --reload-rules && sudo udevadm trigger --subsystem-match=hidraw --subsystem-match=i2c-dev`, or log out and back in |
| Fury memory / SMBus missing | `/proc/cmdline` must contain `acpi_enforce_resources=lax` |
| no motherboard sensors | `sudo modprobe it87 ignore_resource_conflict=1`; on older kernels install `it87-dkms-git` |
| no memory temperature | `sudo modprobe spd5118`; if the kernel lacks the driver, the warning is expected |
| no SSD SMART data | `getcap /usr/lib/lumivent/lumivent-nvme-smart` must list both capabilities; reinstall the package or run `setcap` as shown above |
| fans do not change speed | close competing programs; check that the temperature source has a reading (switch to CPU to test); check preset, start/stop and fan size; use groups 1–3 |
| fans stop when the app closes | expected: the hub keeps the last duty. Keep the app in the tray or enable autostart |
| RGB does not change | the device may be in Hardware mode (firmware in control), ARGB may be turned off, brightness may be zero, or "use hardware effects" may have handed the device to the firmware |
| GPU RGB refused | the subsystem ID is not `0x2429` (unsupported board, do not force it), `amdgpu` is not loaded, or the I²C rule is missing |
| HTML effect paused | a frame took over 250 ms three times in a row; pick another effect or lower the frame rate |
| no tray icon | the desktop needs system tray support (on GNOME, an AppIndicator extension); without a tray, closing the window quits |
| autostart runs another build | turn **Iniciar com o sistema** off and on again; check `systemctl --user status lumivent.service` |
| high CPU usage | lower the effect frame rate to 15; some HTML effects are heavy; fan streaming is capped at ~2 fps on purpose |

Import errors: "O arquivo não é um JSON válido." (not valid JSON), "O arquivo
veio de uma versão mais nova do app." (created by a newer app version — update
Lumivent), "O arquivo não tem preferências, iluminação nem fans." (not a
Lumivent configuration file).

Diagnostic traces for fan and lighting issues:

```sh
LUMIVENT_FANS_TRACE=1 lumivent
LUMIVENT_LIGHTING_TRACE=1 lumivent
```

When opening an issue, include:

```sh
pacman -Q lumivent
uname -r
cat /proc/cmdline
i2cdetect -l
sensors
getfacl /dev/hidraw* /dev/i2c-* 2>/dev/null | grep -B2 -A4 "$USER"
getcap /usr/lib/lumivent/lumivent-nvme-smart
journalctl --user -u lumivent.service -n 100   # if you use autostart
```

plus the terminal output of `lumivent`. **Remove personal data** (serial
numbers, home paths) before posting.

## Development

```sh
flutter config --enable-linux-desktop
flutter pub get
flutter run -d linux
flutter test
flutter analyze
dart format lib test tool
```

`flutter run -d linux -- --minimized` starts in the tray. The release bundle is
built with `flutter build linux --release` into
`build/linux/x64/release/bundle/`. To use the SMART helper without installing
it:

```sh
cc -O2 -Wall -Wextra -Werror -o build/lumivent-nvme-smart tool/lumivent-nvme-smart/lumivent-nvme-smart.c
LUMIVENT_NVME_SMART=$PWD/build/lumivent-nvme-smart \
  build/linux/x64/release/bundle/lumivent
```

Without the udev rules installed, devices show as "Sem permissão".

| Environment variable | Effect |
|---|---|
| `LUMIVENT_NVME_SMART` | alternative path to the SMART helper |
| `LUMIVENT_FANS_TRACE=1` | prints one line per fan loop cycle to `stderr` |
| `LUMIVENT_LIGHTING_TRACE=1` | prints timings and latencies of the lighting loop |
| `XDG_CONFIG_HOME`, `XDG_DATA_HOME` | change the data directories |

The bench tools in `tool/` drive real hardware and require the app and any
competing programs to be closed.

## Contributing

Contributions are welcome — especially reports from other hardware, protocol
fixes and accessibility improvements. Read [`CONTRIBUTING.md`](CONTRIBUTING.md)
and the [Code of Conduct](CODE_OF_CONDUCT.md) before opening a pull request.

- Bugs and ideas: [issues](https://github.com/lcsssilva/lumivent/issues).
- Vulnerabilities: follow [`SECURITY.md`](SECURITY.md) (do not open a public
  issue).
- Versions follow [SemVer](https://semver.org/); tags are `vX.Y.Z` and each
  release ships the `.pkg.tar.zst` package with checksums. Changes are listed in
  [`CHANGELOG.md`](CHANGELOG.md).

## License and legal notice

Lumivent's code is released under the **MIT** license — see [`LICENSE`](LICENSE).
The Inter font is distributed under the SIL Open Font License 1.1, and the
QuickJS engine (bundled by `flutter_js`) under the MIT license. All license
texts are available in **Configurações → Sobre → Licenças…** and in
`/usr/share/licenses/lumivent/`.

This is an independent project, **not affiliated** with Lian Li, Gigabyte,
Kingston or AORUS. Trademarks belong to their owners.

Lumivent does not include or distribute any third-party proprietary effects,
files or assets. Importing only reads files the user already has on their own
machine.
