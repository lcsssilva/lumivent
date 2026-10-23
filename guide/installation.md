# Installation

How to install Lumivent, set up the kernel and device permissions, and remove
it. Check [Supported hardware](../README.md#supported-hardware) first.

- [Prebuilt package](#prebuilt-package-arch-linuxcachyos-x86_64)
- [Building the package](#building-the-package)
- [What the package installs](#what-the-package-installs)
- [Uninstalling](#uninstalling)
- [Manual installation](#manual-installation-development-no-package)
- [Kernel parameter for Fury memory](#kernel-parameter-for-fury-memory)
- [Device permissions](#device-permissions)

## Prebuilt package (Arch Linux/CachyOS, x86_64)

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

After installing, set up the
[kernel parameter](#kernel-parameter-for-fury-memory) if you use Kingston Fury
memory, then open **Lumivent** from the menu or run `lumivent`.

## Building the package

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

## What the package installs

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
| `/usr/share/doc/lumivent/` | the README, these guides (`guide/`) and the CHANGELOG |

## Uninstalling

```sh
sudo pacman -Rns lumivent
```

Your configuration (`~/.config/lumivent/`) and imported effects
(`~/.local/share/lumivent/effects/`) stay in your home directory; see
[Configuration and data](configuration.md) for every path.

## Manual installation (development, no package)

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

## Kernel parameter for Fury memory

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

## Device permissions

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
