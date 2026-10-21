# Changelog

All notable changes to Lumivent are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- Documentation is now in English and consolidated in the root files (README,
  CONTRIBUTING, SECURITY, CODE_OF_CONDUCT); the `docs/` folder is no longer
  published or installed by the package.

### Added

- User guide for every page of the app in the README.
- `test/docs_test.dart`: relative links and anchors in the published Markdown
  files are checked by `flutter test`.

### Fixed

- README: the number of fans per group is set in Lighting, not in Fans.
- The GPU "blocked" hint no longer points to a file outside the repository.

## [1.0.0] — 2026-10-21

First public release.

### Added

- Monitoring of CPU, GPU, memory, motherboard, AL V2 fans and NVMe SSDs, with a
  5-minute history.
- Fan curves per group of the Lian Li UNI FAN AL V2 hub, with presets, custom
  curves, start/stop, temperature source and configurable response.
- ARGB lighting through a 320×200 canvas, fixed color and hardware modes for
  the fans, motherboard, case, Kingston Fury memory and Gigabyte GPU.
- Built-in effects and import of HTML/Canvas effects (file, folder, ZIP and
  Windows cache), with a compatibility check. Paid effects (subscription or
  purchase) are not imported from the Windows cache.
- "Turn off all ARGB", lights off on suspend/shutdown and a system tray icon.
- Autostart through a `systemd --user` unit.
- Configuration export and import as JSON.
- Diagnostics for udev, drivers, SMBus, the NVMe helper and competing programs.
- Arch Linux package with udev rules, modules, desktop entry, icon, a helper
  with capabilities, documentation and third-party licenses (Inter and
  QuickJS).
- **Configurações → Sobre → Licenças** (Settings → About → Licenses) page with
  the licenses of everything shipped in the app.
- User and contributor documentation.
- CI and release automation producing a `.pkg.tar.zst` package for Arch Linux.
- 498 automated tests.

### Security

- Motherboard and GPU writes go through safety checks that block commands
  capable of leaving the controller in an unrecoverable state.
- The SMART helper is read-only and uses the minimum capabilities required.
- The udev rules use `uaccess` and do not expose the monitors' DDC buses.

[Unreleased]: https://github.com/lcsssilva/lumivent/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/lcsssilva/lumivent/releases/tag/v1.0.0
