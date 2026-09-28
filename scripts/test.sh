#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"

if [ "${INTEGRATION:-0}" = "1" ]; then
    RCLONE_BINARY="${RCLONE_BINARY:-$("$root/scripts/fetch-rclone.sh")}"
    export RCLONE_BINARY
    export UNLOCALFS_TEST_KEYCHAIN="${UNLOCALFS_TEST_KEYCHAIN:-1}"
fi

exec swift test --package-path "$root/Packages/UnlocalFSCore" "$@"
