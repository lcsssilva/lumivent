# PKGBUILD do Lumivent (Arch/CachyOS).
#
# O pacote é montado a partir desta árvore de código (source=()); rode
# `makepkg -si` na raiz do projeto. O Flutter precisa estar no PATH (AUR
# `flutter-bin` ou `flutter`). Detalhes no README.md.

pkgname=lumivent
# Mantenha pkgver igual ao version: do pubspec.yaml (sem o +build).
pkgver=1.0.0
pkgrel=1
pkgdesc='Iluminação, controle de fans e monitoramento para Linux'
url='https://github.com/lcsssilva/lumivent'
arch=('x86_64' 'aarch64')
license=('MIT' 'OFL-1.1')
install=lumivent.install
# Nome antigo do projeto.
conflicts=('we-control')
replaces=('we-control')
depends=(
  'gtk3'
  'glib2'
  'libepoxy'
  'pango'
  'cairo'
  'gdk-pixbuf2'
  'atk'
  'harfbuzz'
  'fontconfig'
  'freetype2'
  'zlib'
  'gcc-libs'
  'libcap'
  'hidapi'
)
makedepends=(
  'flutter'
  'clang'
  'cmake'
  'ninja'
  'pkgconf'
  'gcc'
)
optdepends=(
  'nvme-cli: conferir o SMART dos SSDs por fora do app'
  'udisks2: montar a partição do Windows para importar efeitos'
  'xdg-desktop-portal: diálogos de exportar/importar configuração'
)
options=(!strip)
source=()
sha256sums=()

build() {
  cd "$startdir"

  if ! command -v flutter >/dev/null 2>&1; then
    error 'flutter não está no PATH (instale flutter-bin ou flutter do AUR)'
  fi

  flutter pub get
  flutter build linux --release --build-name="$pkgver"

  # Helper de leitura do log SMART (Get Log Page 02h). As capabilities entram
  # no package(), dentro do fakeroot.
  cc -O2 -Wall -Wextra -Werror \
    -o "$srcdir/lumivent-nvme-smart" \
    tool/lumivent-nvme-smart/lumivent-nvme-smart.c
}

package() {
  cd "$startdir"

  local bundle
  case "$CARCH" in
    x86_64) bundle='build/linux/x64/release/bundle' ;;
    aarch64) bundle='build/linux/arm64/release/bundle' ;;
    *) error "arquitetura não suportada: $CARCH" ;;
  esac

  # Bundle do Flutter: binário, data/ e lib/ têm de ficar juntos.
  install -d "$pkgdir/usr/lib/lumivent"
  cp -a "$bundle/." "$pkgdir/usr/lib/lumivent/"
  chown -R root:root "$pkgdir/usr/lib/lumivent"

  install -d "$pkgdir/usr/bin"
  ln -s /usr/lib/lumivent/lumivent "$pkgdir/usr/bin/lumivent"

  # O app procura o helper em /usr/lib/lumivent/lumivent-nvme-smart.
  install -Dm755 "$srcdir/lumivent-nvme-smart" \
    "$pkgdir/usr/lib/lumivent/lumivent-nvme-smart"
  setcap cap_sys_admin,cap_dac_read_search+ep \
    "$pkgdir/usr/lib/lumivent/lumivent-nvme-smart"

  # Regras e módulos. O pacote não mexe no bootloader: o
  # acpi_enforce_resources=lax é documentado no README.
  install -Dm644 "$startdir/packaging/99-lumivent.rules" \
    "$pkgdir/usr/lib/udev/rules.d/99-lumivent.rules"
  install -Dm644 "$startdir/packaging/modprobe-lumivent.conf" \
    "$pkgdir/usr/lib/modprobe.d/lumivent.conf"
  install -Dm644 "$startdir/packaging/modules-load-lumivent.conf" \
    "$pkgdir/usr/lib/modules-load.d/lumivent.conf"

  # Menu e ícones. O nome do .desktop acompanha o APPLICATION_ID do runner
  # (io.github.lcsssilva.lumivent), para o ícone agrupar com a janela no Wayland/X11.
  install -Dm644 "$startdir/packaging/io.github.lcsssilva.lumivent.desktop" \
    "$pkgdir/usr/share/applications/io.github.lcsssilva.lumivent.desktop"
  install -Dm644 "$startdir/assets/icons/lumivent-256.png" \
    "$pkgdir/usr/share/icons/hicolor/256x256/apps/lumivent.png"
  install -Dm644 "$startdir/assets/icons/lumivent.svg" \
    "$pkgdir/usr/share/icons/hicolor/scalable/apps/lumivent.svg"

  install -Dm644 "$startdir/README.md" \
    "$pkgdir/usr/share/doc/lumivent/README.md"
  install -Dm644 "$startdir/CHANGELOG.md" \
    "$pkgdir/usr/share/doc/lumivent/CHANGELOG.md"

  # Licenças: a do projeto e as dos arquivos de terceiros embutidos no bundle
  # (fonte Inter e o QuickJS da biblioteca nativa do flutter_js).
  install -Dm644 "$startdir/LICENSE" \
    "$pkgdir/usr/share/licenses/lumivent/LICENSE"
  install -Dm644 "$startdir/assets/fonts/inter/LICENSE.txt" \
    "$pkgdir/usr/share/licenses/lumivent/Inter-OFL.txt"
  install -Dm644 "$startdir/assets/licenses/quickjs.txt" \
    "$pkgdir/usr/share/licenses/lumivent/QuickJS.txt"
}
