# Versionamento e release

O Lumivent usa [Versionamento Semântico](https://semver.org/lang/pt-BR/) e publica
um pacote Arch Linux (`.pkg.tar.zst`) em cada release.

## Versões

| Lugar | Formato | Exemplo |
|---|---|---|
| `pubspec.yaml` → `version` | `X.Y.Z+build` | `1.2.0+3` |
| `PKGBUILD` → `pkgver` | `X.Y.Z` | `1.2.0` |
| `PKGBUILD` → `pkgrel` | inteiro | `1` |
| Tag do Git | `vX.Y.Z` | `v1.2.0` |
| Artefato | `lumivent-X.Y.Z-R-x86_64.pkg.tar.zst` | `lumivent-1.2.0-1-x86_64.pkg.tar.zst` |

Regras:

- `X.Y.Z` é idêntico nos três arquivos. `scripts/check-version.sh` valida isso.
- `+build` é o build number do Flutter; não entra no `pkgver`.
- `pkgrel` começa em `1` em toda versão nova.
- Uma reconstrução só de empacotamento (sem mudança de código) incrementa
  `pkgrel` e republica o artefato do **mesmo** release, via
  `workflow_dispatch`. Não crie uma tag nova para isso.
  Faça o commit do `pkgrel` em `main` e rode o workflow com a tag existente e
  `ref=main`; o `check-version.sh` confirma que a versão do ref bate com a tag.
- Pré-releases (`1.1.0-rc.1`) não são suportadas pelo `pkgver` do Arch (que não
  aceita `-`). Se precisar, use `1.1.0rc1` no `PKGBUILD` e marque o release como
  pré-release; o caminho normal é publicar apenas estáveis.

### Quando subir cada número

| Mudança | Versão |
|---|---|
| correção compatível | PATCH (`1.0.1`) |
| funcionalidade compatível | MINOR (`1.1.0`) |
| quebra de configuração, CLI ou comportamento | MAJOR (`2.0.0`) |

Mudanças que só afetam documentação, CI ou empacotamento não exigem versão nova
— exceto quando o pacote instalado muda (aí vale um PATCH ou uma reconstrução
com `pkgrel`).

## Checklist do release

1. Atualize `CHANGELOG.md` com a data e a versão.
2. Rode a suíte:

   ```sh
   flutter analyze
   flutter test
   dart format lib test tool
   ```

3. Suba a versão nos dois arquivos:

   ```sh
   scripts/bump-version.sh 1.2.0
   ```

   O script ajusta `pubspec.yaml` (`1.2.0+1`), `PKGBUILD` (`pkgver=1.2.0`,
   `pkgrel=1`) e imprime os próximos passos.

4. Valide localmente:

   ```sh
   scripts/check-version.sh v1.2.0
   makepkg --nodeps
   ```

5. Teste o pacote gerado:

   ```sh
   sudo pacman -U lumivent-1.2.0-1-x86_64.pkg.tar.zst
   lumivent
   ```

6. Faça commit e crie a tag anotada:

   ```sh
   git add pubspec.yaml PKGBUILD CHANGELOG.md
   git commit -m "chore(release): 1.2.0"
   git tag -a v1.2.0 -m "Lumivent 1.2.0"
   git push origin main --follow-tags
   ```

7. O workflow **Release** compila, valida a versão, gera o checksum e publica o
   pacote no GitHub Releases.

## O workflow de release

Arquivo: `.github/workflows/release.yml`.

Gatilhos:

- push de uma tag `v*`;
- `workflow_dispatch` com a tag existente (para reconstruir um pacote). O ref de
  build é a própria tag por padrão; informe `ref=main` para uma reconstrução só
  de empacotamento.

Passos:

1. checkout do código na tag ou no ref informado;
2. instalação das dependências de build e do Flutter no container Arch;
3. `scripts/check-version.sh` (tag × pubspec × PKGBUILD × CHANGELOG);
4. `makepkg --nodeps --noconfirm` como usuário sem privilégios;
5. coleta do `.pkg.tar.zst` e geração de `lumivent-X.Y.Z-sha256sums.txt`;
6. criação (ou atualização) do release com notas geradas pelo GitHub.

O runner é `x86_64`; o `PKGBUILD` declara `aarch64`, mas não há build
automatizado para ARM. Para publicar ARM, compile manualmente na máquina e
anexe o artefato com o sufixo `-aarch64`.

## O que o release publica

| Arquivo | Conteúdo |
|---|---|
| `lumivent-X.Y.Z-R-x86_64.pkg.tar.zst` | pacote Arch com app, helper, udev, módulos, ícone, atalho, licença e docs |
| `lumivent-X.Y.Z-sha256sums.txt` | SHA-256 do pacote |

O usuário instala com:

```sh
sha256sum -c lumivent-1.2.0-sha256sums.txt
sudo pacman -U lumivent-1.2.0-1-x86_64.pkg.tar.zst
```

O `post_install` recarrega o udev. O `post_upgrade` faz o mesmo. A remoção não
apaga a configuração do usuário.

## Build manual

```sh
flutter config --enable-linux-desktop
makepkg --nodeps          # gera o pacote
makepkg -si --nodeps      # gera e instala
sha256sum lumivent-*.pkg.tar.zst > lumivent-<versão>-sha256sums.txt
```

`--nodeps` só é necessário quando o Flutter vem de um SDK manual que não declara
`provides=flutter`. Com o `flutter-bin` do AUR, `makepkg -si` funciona com as
dependências normais.

## Publicação no AUR (opcional)

O projeto ainda não mantém um pacote oficial no AUR. Se isso mudar:

- o `PKGBUILD` do AUR deve usar `source=()` apontando para o tarball do release
  (`https://github.com/lcsssilva/lumivent/archive/refs/tags/vX.Y.Z.tar.gz`) e
  `sha256sums` do tarball;
- o `pkgver` acompanha a tag;
- mudanças no `PKGBUILD` do repositório principal devem ser refletidas no AUR no
  mesmo release;
- não publique em nome do projeto sem combinar com o mantenedor.

## Segurança do release

- Releases são gerados pelo CI a partir de uma tag; não envie artefatos
  compilados na sua máquina para o release oficial.
- O checksum é publicado junto; o usuário deve conferi-lo.
- Se uma credencial ou chave for exposta, siga [`SECURITY.md`](../SECURITY.md) e
  revogue o segredo antes de qualquer nova publicação.

## Histórico

Consulte [`CHANGELOG.md`](../CHANGELOG.md) e a página de
[releases](https://github.com/lcsssilva/lumivent/releases).
