#!/usr/bin/env bash
set -Eeuo pipefail

VERSION="${1:?Usage: build-arm64.sh VERSION}"
VERSION="${VERSION#v}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/build"
DIST="$ROOT/dist"
SRC="$BUILD/audiobookshelf"
IMAGE="${BUILD_IMAGE:-node:20-bullseye}"
PKG_VERSION="${PKG_VERSION:-5.12.0}"

rm -rf "$BUILD" "$DIST"
mkdir -p "$BUILD" "$DIST"

echo "Cloning Audiobookshelf v$VERSION"
git clone --depth 1 --branch "v$VERSION" \
  https://github.com/advplyr/audiobookshelf.git "$SRC"

# Run all npm operations inside an emulated ARM64 container. This ensures
# sqlite3 and every other native dependency are ARM64, not x86_64.
docker run --rm --platform linux/arm64 \
  -e HOME=/tmp/home \
  -e npm_config_audit=false \
  -e npm_config_fund=false \
  -e npm_config_update_notifier=false \
  -e PKG_VERSION="$PKG_VERSION" \
  -v "$SRC:/src" \
  -v "$DIST:/out" \
  -w /src \
  "$IMAGE" bash -Eeuo pipefail -c '
    apt-get update
    apt-get install -y --no-install-recommends python3 make g++ git file binutils ca-certificates
    rm -rf /var/lib/apt/lists/*

    cd /src/client
    npm ci --unsafe-perm=true
    npm run generate
    rm -rf node_modules

    cd /src
    npm ci --omit=dev --unsafe-perm=true
    npm install --no-save "@yao-pkg/pkg@${PKG_VERSION}"

    ./node_modules/.bin/pkg \
      --targets node20-linux-arm64 \
      --output /out/audiobookshelf \
      --compress GZip \
      .

    chmod 0755 /out/audiobookshelf
    file /out/audiobookshelf
    readelf -h /out/audiobookshelf | grep -E "Class:|Machine:"
  '

file "$DIST/audiobookshelf" | grep -Eq 'ARM aarch64|ARM64|aarch64' || {
  echo 'Output is not an ARM64 executable' >&2
  file "$DIST/audiobookshelf" >&2
  exit 1
}

mv "$DIST/audiobookshelf" "$DIST/audiobookshelf-${VERSION}-linux-arm64"
