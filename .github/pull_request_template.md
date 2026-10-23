## Summary

Describe the change and the problem it solves.

## Type of change

- [ ] Bug fix
- [ ] New feature
- [ ] Refactoring with no behavior change
- [ ] Documentation
- [ ] Packaging / CI
- [ ] Breaking change (explain below)

## How it was tested

Describe the automated tests and the manual checks. If hardware is involved,
list the devices and the kernel/driver versions used.

```sh
dart format lib test tool
flutter analyze
flutter test
```

## Checklist

- [ ] `dart format`, `flutter analyze` and `flutter test` pass.
- [ ] Behavior changes update the documentation (README or `guide/`) and `CHANGELOG.md`.
- [ ] I did not include third-party proprietary effects, fonts, binaries or other assets.
- [ ] I did not include decompiled third-party code or local reverse-engineering notes.
- [ ] The version was bumped with `scripts/bump-version.sh` when the package changes.

## Additional context

Related issues, screenshots, measurements or design decisions.
