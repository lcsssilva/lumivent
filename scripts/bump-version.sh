#!/usr/bin/env bash
# Bump the application version in pubspec.yaml and PKGBUILD.
#
# Usage: scripts/bump-version.sh X.Y.Z
set -euo pipefail

cd "$(dirname "$0")/.."

fail() {
  printf 'erro: %s\n' "$*" >&2
  exit 1
}

new_version="${1:-}"
[[ "$new_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
  fail "uso: scripts/bump-version.sh X.Y.Z"

current_line="$(grep -E '^version:' pubspec.yaml | head -n1 || true)"
[[ -n "$current_line" ]] || fail 'version: não encontrado em pubspec.yaml'
current_version="${current_line#version:}"
current_version="${current_version//[[:space:]]/}"
current_base="${current_version%%+*}"

[[ "$new_version" != "$current_base" ]] ||
  fail "a versão atual já é $current_base"

# Only allow forward moves, so a typo cannot silently downgrade the project.
highest="$(printf '%s\n%s\n' "$current_base" "$new_version" | sort -V | tail -n1)"
[[ "$highest" == "$new_version" ]] ||
  fail "a nova versão ($new_version) deve ser maior que a atual ($current_base)"

sed -i -E "s/^version:.*/version: ${new_version}+1/" pubspec.yaml
sed -i -E "s/^pkgver=.*/pkgver=${new_version}/" PKGBUILD
sed -i -E "s/^pkgrel=.*/pkgrel=1/" PKGBUILD

cat <<EOF
versão atualizada:
  pubspec.yaml  version: ${new_version}+1
  PKGBUILD      pkgver=${new_version}
  PKGBUILD      pkgrel=1

Próximos passos:
  1. Atualize CHANGELOG.md com a seção '## [${new_version}]'.
  2. Rode: flutter analyze && flutter test && dart format lib test tool
  3. Valide:    scripts/check-version.sh v${new_version}
  4. Gere:      makepkg --nodeps
  5. Commit, tag e push:
       git add pubspec.yaml PKGBUILD CHANGELOG.md
       git commit -m "chore(release): ${new_version}"
       git tag -a v${new_version} -m "Lumivent ${new_version}"
       git push origin main --follow-tags
EOF
