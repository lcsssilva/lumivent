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
no root service, no custom kernel module and no webview. The interface is in
English (default) and Portuguese.

> **Status:** 1.x. Support targets a specific, validated set of hardware —
> check [Supported hardware](#supported-hardware) before installing.

## Supported hardware

| Device | What the app does |
|---|---|
| Lian Li UNI FAN AL V2 hub | RPM, duty, curves and fan ARGB |
| Gigabyte B650E AORUS MASTER (ITE IT5702) | Motherboard ARGB zones, case strip and firmware effects |
| Kingston Fury DDR5 | Memory ARGB (12 LEDs per module) |
| Gigabyte RX 9060 XT GAMING OC 8G | GPU RGB and firmware effects |

Other models may partially work but are not tested. Known limitations:

- Motherboard fans and pump are **monitored only**; their curves stay in the
  BIOS.
- GPU RGB is enabled only on boards with subsystem ID `0x2429`; others are
  refused for safety.
- The AL V2 hub does not run curves on its own; with the app closed, the fans
  stay at the last duty sent.
- The SmartMonitor X28 AIO display is out of scope.

How each device is identified and which permissions it needs are described in
[Device permissions](guide/installation.md#device-permissions).

## Quick start

On Arch Linux or CachyOS (x86_64), download the latest release, verify it and
install it:

```sh
mkdir lumivent-release && cd lumivent-release
gh release download --repo lcsssilva/lumivent --pattern 'lumivent-*'
sha256sum -c lumivent-*-sha256sums.txt
sudo pacman -U lumivent-*-x86_64.pkg.tar.zst
```

Kingston Fury memory also needs the kernel parameter
`acpi_enforce_resources=lax` — see
[Kernel parameter for Fury memory](guide/installation.md#kernel-parameter-for-fury-memory).
Then open **Lumivent** from the menu and follow
[First run](guide/user-guide.md#first-run).

## Documentation

| Guide | Covers |
|---|---|
| [Installation](guide/installation.md) | release package, building with `makepkg`, installed files, uninstalling, manual installation, kernel parameter and device permissions |
| [User guide](guide/user-guide.md) | features and every page of the app: monitoring, fans, lighting, effects and settings |
| [Configuration and data](guide/configuration.md) | file locations, `config.json` handling, preference keys and environment variables |
| [Troubleshooting](guide/troubleshooting.md) | common problems, import errors, diagnostic traces and what to include in a bug report |
| [Contributing](CONTRIBUTING.md) | development environment, tests, code style and pull requests |
| [Changelog](CHANGELOG.md) | changes in each version |

## Contributing

Contributions are welcome — especially reports from other hardware, protocol
fixes and accessibility improvements. Read [`CONTRIBUTING.md`](CONTRIBUTING.md)
and the [Code of Conduct](CODE_OF_CONDUCT.md) before opening a pull request.

- Bugs and ideas: [issues](https://github.com/lcsssilva/lumivent/issues).
- Vulnerabilities: follow [`SECURITY.md`](SECURITY.md) (do not open a public
  issue).
- Versions follow [SemVer](https://semver.org/); tags are `vX.Y.Z` and each
  release ships the `.pkg.tar.zst` package with checksums.

## License and legal notice

Lumivent's code is released under the **MIT** license — see [`LICENSE`](LICENSE).
The Inter font is distributed under the SIL Open Font License 1.1, and the
QuickJS engine (bundled by `flutter_js`) under the MIT license. All license
texts are available in **Settings → About → Licenses…** and in
`/usr/share/licenses/lumivent/`.

This is an independent project, **not affiliated** with Lian Li, Gigabyte,
Kingston or AORUS. Trademarks belong to their owners.

Lumivent does not include or distribute any third-party proprietary effects,
files or assets. Importing only reads files the user already has on their own
machine.
