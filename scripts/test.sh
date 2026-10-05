#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"

cd "$root/Packages/UnlocalFSCore"
xcodebuild \
    -scheme UnlocalFSCore-Package \
    -configuration Debug \
    -destination "platform=macOS" \
    -derivedDataPath .build/xcode \
    -disableAutomaticPackageResolution \
    test "$@" | xcbeautify
