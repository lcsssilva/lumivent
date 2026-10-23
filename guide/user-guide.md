# User guide

A tour of every page of Lumivent. The interface is available in English (the
default) and Portuguese; choose **Settings → Preferences → Language**
(**Configurações → Preferências → Idioma**) to switch. The change applies at
once and is saved in `config.json`. This guide shows the English and
Portuguese labels where they differ.

- [Features](#features)
- [The window](#the-window)
- [First run](#first-run)
- [Monitoring](#monitoring-monitoramento)
- [Fans](#fans)
- [Lighting](#lighting-iluminação)
- [Explore](#explore)
- [Settings](#settings-configurações)
- [Accessibility](#accessibility)

## Features

**Monitoring**

- CPU: temperature (`k10temp`), clock and load.
- GPU: edge/junction/memory temperatures, load, clock, power, VRAM and fan RPM.
- Memory: usage, total and per-module temperature (`spd5118`).
- Motherboard: temperatures and header RPM via `it87` (read-only).
- AL V2 fans: RPM per group.
- NVMe SSDs: identification from sysfs and the SMART/Health log through the
  read-only `lumivent-nvme-smart` helper.
- 5-minute history (300 samples, one per second) for the charts.

**Fans**

- Four groups (ports) on the AL V2 hub, up to 6 fans per group.
- Quiet, Standard, High and Full presets, custom curves and four user curves.
- Fixed percentage mode, start/stop and fan size (120/140 mm).
- Temperature source: CPU, GPU (edge/junction) or motherboard sensors.
- Normal, Fast or Smooth response (moving average plus asymmetric ramp).
- On exit, each group gets the duty from its own curve at the last
  temperature — the hub cannot run curves by itself.

**Lighting**

- A 320×200 canvas with draggable, resizable device placement.
- Built-in effects (solid color, color cycle, rainbow wave, breathing, scanner
  and more).
- Firmware modes for the fans, motherboard zones, case strip and GPU.
- HTML/Canvas effects imported from `.html` files, folders, `.zip` archives or
  the effect cache of an existing Windows installation. Paid effects
  (subscription or purchase) are never imported.
- Global brightness, per-device fixed color and "turn off all ARGB".
- Lights off on suspend/shutdown through logind (`delay` inhibitor).

**System**

- Closing the window hides it to the tray (configurable).
- Autostart through a `systemd --user` unit bound to `graphical-session.target`.
- Export/import of preferences, lighting and fans as JSON.
- Diagnostics for udev, `it87`, PIIX4, `spd5118`, the NVMe helper and conflicts
  with OpenRGB, liquidctl, CoolerControl and ckb-next.

## The window

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

## First run

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

## Monitoring (Monitoramento)

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

## Fans

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

## Lighting (Iluminação)

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

### Fans per group

The **Ventoinhas no grupo** (fans in group, 0–6) control lives in the Hardware
panel of each fan group. The count applies to every mode: it defines how many
LEDs the group has on the canvas. To change it for a group in Canvas mode,
switch the group to Hardware, adjust the count and switch back.

### Motherboard and GPU

**Hardware mode on the motherboard and GPU.** The motherboard has mode, color,
speed and brightness per zone (IO Shield 1 and 2, CPU LED). The GPU has mode,
speed and brightness (1–10) and up to 8 colors; the app only sends colors after
confirming the board's subsystem ID, and the GPU is marked unavailable if that
read fails.

When the app exits, the LEDs stay as they were.

## Explore

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

## Settings (Configurações)

| Card | Contents |
|---|---|
| Inicialização (startup) | **Iniciar com o sistema**: a `systemd --user` unit that starts minimized in the tray. If the unit points to another executable, turn it off and on again |
| Preferências (preferences) | language (**English** / **Português**, applies immediately), keep in tray on close, temperature unit (°C/°F) and effect frame rate (15, 30 or 60 fps) |
| Configuração (configuration) | **Exportar…** / **Importar…** (export/import) preferences, lighting and fans as JSON — see [Configuration and data](configuration.md) |
| Dispositivos (devices) | state of each device, **Detectar novamente** (detect again) and competing-program warnings |
| Permissões e sistema (permissions and system) | checks for udev rules, `it87`, SMBus/PIIX4, `spd5118`, the NVMe helper and the lighting loop |
| Sobre (about) | version, license and **Licenças…** (licenses of every bundled dependency) |

## Accessibility

- Controls are standard Flutter widgets: **Tab** to move, **Space/Enter** to
  activate, tooltips on hover.
- Device state never relies on color alone: cards and tooltips also show the
  state as text.
- The curve editor and the canvas need a mouse (drag, double-click,
  right-click). Factory presets and saved user curves can be selected without
  dragging points.
