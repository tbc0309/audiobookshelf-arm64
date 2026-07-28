#!/usr/bin/env bash
set -Eeuo pipefail
VERSION="${1:?Usage: package-release.sh VERSION}"
VERSION="${VERSION#v}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/dist"
BIN="audiobookshelf-${VERSION}-linux-arm64"
DEB="audiobookshelf_${VERSION}_arm64.deb"
[[ -f "$BIN" && -f "$DEB" ]] || { echo 'Build outputs missing' >&2; exit 1; }
tar -czf "${BIN}.tar.gz" "$BIN"
sha256sum "$BIN" "$DEB" "${BIN}.tar.gz" > SHA256SUMS
