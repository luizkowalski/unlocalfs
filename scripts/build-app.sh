#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

xcodegen generate --quiet
xcodebuild build \
    -project UnlocalFS.xcodeproj \
    -scheme UnlocalFS \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -derivedDataPath .build/xcode \
    -disableAutomaticPackageResolution \
    -quiet \
    CONFIGURATION_BUILD_DIR="$PWD/dist" \
    "$@"
codesign --verify --deep --strict dist/UnlocalFS.app
