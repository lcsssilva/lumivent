# Contributing to Lumivent

Thanks for your interest. This guide covers the environment and what we expect
from a pull request. Please also read the
[`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).

## Ways to contribute

- Report a bug with as much hardware context and logs as possible.
- Try the app on a different motherboard, memory kit or GPU and tell us what
  worked.
- Fix documentation, translations or interface messages.
- Implement or fix a driver, an effect or a test.
- Improve accessibility, keyboard navigation and screen reader support.

Use the issue templates for bugs and feature requests. For vulnerabilities,
**do not open a public issue**: follow [`SECURITY.md`](SECURITY.md).

## Environment

Requirements:

- Linux (Arch Linux or CachyOS for the package; any distro for development);
- Flutter 3.47+ and Dart 3.13+;
- GTK 3, `hidapi`, `libcap`, `clang`, `cmake`, `ninja`, `pkgconf` and `gcc`;
- compatible hardware to exercise the real paths (without it, rely on the
  tests).

```sh
git clone https://github.com/lcsssilva/lumivent.git
cd lumivent
flutter config --enable-linux-desktop
flutter pub get
flutter run -d linux
```

`flutter run -d linux -- --minimized` starts in the tray. The release bundle is
built with `flutter build linux --release` into
`build/linux/x64/release/bundle/`.

Without the udev rules installed, devices show as "Sem permissão" (no
permission). To install the rules and the SMART helper without building the
package, see
[Manual installation](guide/installation.md#manual-installation-development-no-package).
To use the SMART helper without installing it:

```sh
cc -O2 -Wall -Wextra -Werror -o build/lumivent-nvme-smart tool/lumivent-nvme-smart/lumivent-nvme-smart.c
LUMIVENT_NVME_SMART=$PWD/build/lumivent-nvme-smart \
  build/linux/x64/release/bundle/lumivent
```

Diagnostic variables (`LUMIVENT_FANS_TRACE`, `LUMIVENT_LIGHTING_TRACE` and
others) are listed in
[Environment variables](guide/configuration.md#environment-variables).

## Before opening a pull request

From the repository root:

```sh
dart run build_runner build
dart format lib test tool
flutter analyze
flutter test
```

CI runs the generated-code check, the format check, `flutter analyze` and
`flutter test` on every push and pull request. A pull request with failing
tests or analyzer warnings is not merged.

### Generated code

Some domain models use [freezed](https://pub.dev/packages/freezed). The generated
`*.freezed.dart` files are committed: run `dart run build_runner build` after
changing a `@freezed` class and include the regenerated file in the same commit.
Never edit `*.freezed.dart` by hand, and do not ignore those files in Git.

### Tests

- Every behavior fix comes with a test that fails without it.
- A new driver needs tests for the exact bytes it sends, for its safety checks
  and for missing devices and permissions — using a fake transport, never real
  hardware.
- Widget tests match the Portuguese catalog (`find.text`): wrap the tree with
  `withPortuguese` from `test/support/app_harness.dart` (without it, widgets use
  the default English catalog). New pages also get an English smoke test.
- Tests must not depend on the network, real `/dev` nodes or global state shared
  between tests.
- The bench tools in `tool/` drive real hardware and require the app to be
  closed.

## Code style

- Code, comments, identifiers and test names in **English**.
- Interface text and user-facing messages go in the English and Portuguese
  catalogs under `lib/core/i18n/catalogs/`; English is the default. Never write
  UI text directly in a widget.
- Documentation (the root `.md` files) in **English**.
- Follow `dart format` and the lints in `analysis_options.yaml`.
- Prefer explicit types at public boundaries.
- Hardware errors must not crash the app: log them, return `false` and show the
  reason in the interface.
- Do not add a new dependency without justifying it in the pull request (size,
  license, maintenance and Linux desktop support).

## What not to submit

- decompiled source code of third-party programs;
- third-party proprietary assets, fonts or effects;
- captures or dumps that contain personal data;
- commands that can persist settings to, or permanently change, a device's
  firmware without an explicit safety check and a test.

## Commits and pull requests

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/):

```text
feat(fans): add smooth response per group
fix(lighting): fix breathing phase after resume
docs(readme): document package checksums
test(devices): cover the GPU subsystem ID check
```

A pull request should:

- have a single clear goal and a title in the same format;
- explain **why** the change exists and how it was tested;
- list the hardware used for testing, when relevant;
- update the documentation and `CHANGELOG.md` when behavior changes;
- not mix broad refactoring with functional fixes.

## Documentation

- `README.md` is a short overview: what the app does, supported hardware, a
  quick start and links. Detailed material goes in the guides under `guide/`
  (installation, user guide, configuration, troubleshooting); keep commands,
  paths and key names copyable and faithful to the code.
- When you change `config.json`, the `PKGBUILD`, the udev rules or the release
  flow, update the matching guide in the same pull request.
- `test/docs_test.dart` fails if a relative link or anchor in a published
  Markdown file does not resolve.

## License of contributions

By submitting a pull request, you agree that your contribution is licensed
under the MIT license, the same as the project. Do not submit code under an
incompatible license.
