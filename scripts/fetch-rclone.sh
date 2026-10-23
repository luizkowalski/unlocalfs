#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"

setting() {
    sed -nE "s/^[[:space:]]*$1:[[:space:]]*([^[:space:]]+).*/\1/p" "$root/project.yml" | head -1
}

version="$(setting RCLONE_VERSION)"
checksum="$(setting RCLONE_SHA256_ARM64)"

name="rclone-v$version-osx-arm64"
cache="$root/.build/rclone/$version"
binary="$cache/$name/rclone"

if [ ! -x "$binary" ]; then
    mkdir -p "$cache"
    curl -fsSL --retry 3 --retry-all-errors "https://github.com/rclone/rclone/releases/download/v$version/$name.zip" -o "$cache/$name.zip"
    echo "$checksum  $cache/$name.zip" | shasum -a 256 -c --quiet - >&2
    ditto -x -k "$cache/$name.zip" "$cache"
    rm "$cache/$name.zip"
fi

echo "$binary"
