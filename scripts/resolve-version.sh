#!/usr/bin/env bash
set -Eeuo pipefail

requested="${1:-latest}"
if [[ "$requested" != "latest" && -n "$requested" ]]; then
  printf '%s\n' "${requested#v}"
  exit 0
fi

api='https://api.github.com/repos/advplyr/audiobookshelf/releases/latest'
version="$(curl -fsSL -H 'Accept: application/vnd.github+json' "$api" \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"].lstrip("v"))')"
[[ -n "$version" ]] || { echo 'Could not resolve latest version' >&2; exit 1; }
printf '%s\n' "$version"
