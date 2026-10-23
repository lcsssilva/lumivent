# Troubleshooting

Start with **Configurações → Permissões e sistema** (Settings → Permissions and
system); each device card also shows why something is missing. Run `lumivent`
from a terminal to see engine errors on `stderr`.

## Common problems

| Symptom | Likely cause and fix |
|---|---|
| `error while loading shared libraries` | missing dependency: `sudo pacman -S --needed gtk3 hidapi libcap` |
| window does not appear, process stays alive | started with `--minimized`: open it from the tray icon |
| "Lumivent could not start" screen | the error is printed in the terminal; check `config.json` with **Open configuration folder** — see [how the file is handled](configuration.md#how-the-configuration-file-is-handled) |
| device shows "Sem permissão" | check the ACL with `getfacl` ([Device permissions](installation.md#device-permissions)), then `sudo udevadm control --reload-rules && sudo udevadm trigger --subsystem-match=hidraw --subsystem-match=i2c-dev`, or log out and back in |
| Fury memory / SMBus missing | `/proc/cmdline` must contain `acpi_enforce_resources=lax` ([Kernel parameter](installation.md#kernel-parameter-for-fury-memory)) |
| no motherboard sensors | `sudo modprobe it87 ignore_resource_conflict=1`; on older kernels install `it87-dkms-git` |
| no memory temperature | `sudo modprobe spd5118`; if the kernel lacks the driver, the warning is expected |
| no SSD SMART data | `getcap /usr/lib/lumivent/lumivent-nvme-smart` must list both capabilities; reinstall the package or run `setcap` as in [Manual installation](installation.md#manual-installation-development-no-package) |
| fans do not change speed | close competing programs; check that the temperature source has a reading (switch to CPU to test); check preset, start/stop and fan size; use groups 1–3 |
| fans stop when the app closes | expected: the hub keeps the last duty. Keep the app in the tray or enable autostart |
| RGB does not change | the device may be in Hardware mode (firmware in control), ARGB may be turned off, brightness may be zero, or "use hardware effects" may have handed the device to the firmware |
| GPU RGB refused | the subsystem ID is not `0x2429` (unsupported board, do not force it), `amdgpu` is not loaded, or the I²C rule is missing |
| HTML effect paused | a frame took over 250 ms three times in a row; pick another effect or lower the frame rate |
| no tray icon | the desktop needs system tray support (on GNOME, an AppIndicator extension); without a tray, closing the window quits |
| autostart runs another build | turn **Iniciar com o sistema** off and on again; check `systemctl --user status lumivent.service` |
| high CPU usage | lower the effect frame rate to 15; some HTML effects are heavy; fan streaming is capped at ~2 fps on purpose |

## Import errors

| Message (English / Portuguese) | Meaning |
|---|---|
| "The file is not valid JSON." / "O arquivo não é um JSON válido." | the file is damaged or not JSON |
| "The file is not an app configuration." / "O arquivo não é uma configuração do app." | valid JSON, but not a Lumivent export |
| "The file has no preferences, lighting, or fans." / "O arquivo não tem preferências, iluminação nem fans." | a Lumivent file without any known section |
| "The file came from a newer version of the app." / "O arquivo veio de uma versão mais nova do app." | created by a newer version — update Lumivent |
| "The file is larger than … MB and is not a configuration." / "O arquivo tem mais de … MB e não é uma configuração." | the file exceeds the size limit for a configuration |

## Diagnostic traces

For fan and lighting issues:

```sh
LUMIVENT_FANS_TRACE=1 lumivent
LUMIVENT_LIGHTING_TRACE=1 lumivent
```

Other variables are listed in
[Environment variables](configuration.md#environment-variables).

## Reporting a problem

When opening an [issue](https://github.com/lcsssilva/lumivent/issues), include:

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
