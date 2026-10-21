#!/usr/bin/env bash
# Validate that pubspec.yaml, PKGBUILD and CHANGELOG.md agree on one version.
#
# Usage:
#   scripts/check-version.sh            # files only, or the tag at HEAD if any
#   scripts/check-version.sh v1.2.0     # files plus the expected tag
set -euo pipefail

cd "$(dirname "$0")/.."

fail() {
  printf 'erro: %s\n' "$*" >&2
  exit 1
}

tag="${1:-}"
if [[ -z "$tag" ]]; then
  # In CI, a normal commit is not tagged; validating the files alone is enough.
  tag="$(git describe --tags --exact-match 2>/dev/null || true)"
fi
tag="${tag#v}"

if [[ -n "$tag" && ! "$tag" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  fail "tag inválida: '$tag' (esperado vX.Y.Z)"
fi

pubspec_line="$(grep -E '^version:' pubspec.yaml | head -n1 || true)"
[[ -n "$pubspec_line" ]] || fail 'version: não encontrado em pubspec.yaml'
pubspec_version="${pubspec_line#version:}"
pubspec_version="${pubspec_version//[[:space:]]/}"
pubspec_base="${pubspec_version%%+*}"

[[ "$pubspec_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$ ]] ||
  fail "pubspec.yaml: version deve ser X.Y.Z+build (encontrado '$pubspec_version')"

pkgver_line="$(grep -E '^pkgver=' PKGBUILD | head -n1 || true)"
pkgrel_line="$(grep -E '^pkgrel=' PKGBUILD | head -n1 || true)"
[[ -n "$pkgver_line" ]] || fail 'pkgver= não encontrado em PKGBUILD'
[[ -n "$pkgrel_line" ]] || fail 'pkgrel= não encontrado em PKGBUILD'
pkgver="${pkgver_line#pkgver=}"
pkgrel="${pkgrel_line#pkgrel=}"

[[ "$pkgver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
  fail "PKGBUILD: pkgver inválido '$pkgver'"
[[ "$pkgrel" =~ ^[1-9][0-9]*$ ]] ||
  fail "PKGBUILD: pkgrel inválido '$pkgrel' (inteiro >= 1)"

[[ "$pubspec_base" == "$pkgver" ]] ||
  fail "versões divergentes: pubspec.yaml=$pubspec_base, PKGBUILD=$pkgver"

if [[ -n "$tag" && "$tag" != "$pkgver" ]]; then
  fail "tag divergente: tag=$tag, PKGBUILD=$pkgver"
fi

grep -Fq "## [$pkgver]" CHANGELOG.md ||
  fail "CHANGELOG.md não tem a seção '## [$pkgver]'"

printf 'versão ok: %s (pkgrel %s)\n' "$pkgver" "$pkgrel"
