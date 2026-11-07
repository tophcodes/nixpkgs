#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix-update nixfmt

set -euo pipefail

packageDir=$(dirname "$(realpath "$0")")

nix-update herdr-desktop "$@"

# Ghostty commits the zon2nix expression for its Zig dependencies. deps.nix
# is that file at the commit vendor/ghostty pins.
version=$(nix-instantiate --eval --raw -A herdr-desktop.version)
ghosttyRev=$(
  curl -sSf ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} \
    "https://api.github.com/repos/herdrdev/herdr-app/contents/vendor/ghostty?ref=v$version" |
    jq -r .sha
)
curl -sSf -o "$packageDir/deps.nix" \
  "https://raw.githubusercontent.com/ghostty-org/ghostty/$ghosttyRev/build.zig.zon.nix"
nixfmt "$packageDir/deps.nix"
