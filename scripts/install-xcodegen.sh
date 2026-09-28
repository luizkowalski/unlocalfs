#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
version="$(sed -nE 's/^xcodegen[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' "$root/mise.toml")"
prefix="${1:-$root/.build/xcodegen/$version}"

if [ ! -x "$prefix/bin/xcodegen" ]; then
    tmp="$(mktemp -d)"
    curl -fsSL --retry 3 --retry-all-errors "https://github.com/yonaskolb/XcodeGen/releases/download/$version/xcodegen.zip" -o "$tmp/xcodegen.zip"
    ditto -x -k "$tmp/xcodegen.zip" "$tmp"
    rm -rf "$prefix"
    mkdir -p "$(dirname "$prefix")"
    mv "$tmp/xcodegen" "$prefix"
    rm -rf "$tmp"
fi

echo "$prefix/bin"
