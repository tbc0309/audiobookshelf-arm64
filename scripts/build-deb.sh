#!/usr/bin/env bash
set -Eeuo pipefail

VERSION="${1:?Usage: build-deb.sh VERSION}"
VERSION="${VERSION#v}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$ROOT/dist"
PKGROOT="$ROOT/build/debroot"
BINARY="$DIST/audiobookshelf-${VERSION}-linux-arm64"
DEB="$DIST/audiobookshelf_${VERSION}_arm64.deb"

[[ -x "$BINARY" ]] || { echo "Missing binary: $BINARY" >&2; exit 1; }
rm -rf "$PKGROOT"
mkdir -p "$PKGROOT/DEBIAN" "$PKGROOT/usr/bin" \
  "$PKGROOT/lib/systemd/system" "$PKGROOT/var/lib/audiobookshelf/config" \
  "$PKGROOT/var/lib/audiobookshelf/metadata"

install -m 0755 "$BINARY" "$PKGROOT/usr/bin/audiobookshelf"
install -m 0644 "$ROOT/packaging/debian/audiobookshelf.service" \
  "$PKGROOT/lib/systemd/system/audiobookshelf.service"
install -m 0755 "$ROOT/packaging/debian/postinst" "$PKGROOT/DEBIAN/postinst"
install -m 0755 "$ROOT/packaging/debian/prerm" "$PKGROOT/DEBIAN/prerm"
install -m 0755 "$ROOT/packaging/debian/postrm" "$PKGROOT/DEBIAN/postrm"

cat > "$PKGROOT/DEBIAN/control" <<CONTROL
Package: audiobookshelf
Version: $VERSION
Section: sound
Priority: optional
Architecture: arm64
Maintainer: Community ARM64 Builder
Depends: ffmpeg, adduser
Homepage: https://www.audiobookshelf.org/
Description: Self-hosted audiobook and podcast server
 Unofficial ARM64 package generated from the upstream Audiobookshelf source.
 It installs a standalone executable and a systemd service.
CONTROL

chmod 0755 "$PKGROOT/DEBIAN"
find "$PKGROOT" -type d -exec chmod 0755 {} +

dpkg-deb --root-owner-group --build "$PKGROOT" "$DEB"
dpkg-deb --info "$DEB"
dpkg-deb --contents "$DEB"
