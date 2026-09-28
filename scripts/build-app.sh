#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

if ! command -v xcodegen >/dev/null; then
    PATH="$("$root/scripts/install-xcodegen.sh"):$PATH"
fi

xcodegen generate --quiet

resolved="UnlocalFS.xcodeproj/project.xcworkspace/xcshareddata/swiftpm"
mkdir -p "$resolved"
cp Packages/UnlocalFSCore/Package.resolved "$resolved/Package.resolved"

settings=()
if [ -n "${SIGN_IDENTITY:-}" ]; then
    settings+=(CODE_SIGN_IDENTITY="$SIGN_IDENTITY" OTHER_CODE_SIGN_FLAGS=--timestamp)
fi
if [ -n "${VERSION:-}" ]; then
    settings+=(MARKETING_VERSION="$VERSION")
fi
if [ -n "${BUILD_NUMBER:-}" ]; then
    settings+=(CURRENT_PROJECT_VERSION="$BUILD_NUMBER")
fi

xcodebuild \
    -project UnlocalFS.xcodeproj \
    -scheme UnlocalFS \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -derivedDataPath .build/xcode \
    -disableAutomaticPackageResolution \
    -quiet \
    build ${settings[@]+"${settings[@]}"}

rm -rf dist/UnlocalFS.app
mkdir -p dist
ditto .build/xcode/Build/Products/Release/UnlocalFS.app dist/UnlocalFS.app
codesign --verify --deep --strict dist/UnlocalFS.app
echo "Built $root/dist/UnlocalFS.app"
