#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"

export TEST_RUNNER_RCLONE_BINARY="${RCLONE_BINARY:-$("$root/scripts/fetch-rclone.sh")}"
export TEST_RUNNER_UNLOCALFS_TEST_KEYCHAIN=1
for variable in UNLOCALFS_GCS_BUCKET UNLOCALFS_GCS_KEY_FILE; do
    if [ -n "${!variable:-}" ]; then
        export "TEST_RUNNER_$variable=${!variable}"
    fi
done

cd "$root/Packages/UnlocalFSCore"
xcodebuild \
    -scheme UnlocalFSCore-Package \
    -destination "platform=macOS" \
    -derivedDataPath .build/xcode \
    -disableAutomaticPackageResolution \
    test "$@" | xcbeautify
