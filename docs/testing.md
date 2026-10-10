# Tests

Run every test in `Packages/UnlocalFSCore`:

```sh
timeout 180 xcodebuild test -scheme UnlocalFSCore-Package -destination platform=macOS
```

CI runs the same command on each supported macOS/Xcode version.

## What to test

Test what the app does, not what its dependencies do. If rclone, macOS, or SwiftUI stops working, the app is broken and a test does not help. Do not test that SwiftUI shows a text, that rclone accepts a flag, or that macOS applies NFS options, read-only mounts, or log rotation.

Before you add a test, name the bug it catches. If a test already catches that bug, extend that test instead. Test what a user or caller sees, not how the code is built. A refactor that keeps the behavior must not break a test.

Put each test at the layer that owns the rule:

- Domain rules and presentation values, such as validation and `TransferSummary`: plain values.
- Use cases, view models, and `MountService` decisions: real repositories and a stub `rclone` script (`ViewModelFixture`, `withWorkflowFixture`).
- Real storage: only the smoke suites below.

Stub only at the edges: the rclone process, the Keychain, desktop services, and the clock. Do not change production code only to make a test possible.

When tests share a setup, one test checks all the outcomes. Keep a test separate when it needs a different setup or a different failure.

## Storage smoke tests

Each storage type has one suite. Each test starts its own local server and uses its own folder, so the suites run in parallel.

- `S3DriveTests`: a drive downloads, uploads, and deletes files, and does not disconnect while an upload is pending. An encrypted drive stores only ciphertext, and its exported rclone config can read it.
- `SFTPDriveTests`: the same round trip for each login, and approval of a new or changed server key.
- `GCSDriveTests`: rclone has no GCS server, so this suite checks only the exported config. To add a mount test, start a GCS emulator in `withOfflineDrive` and call `verifyRoundTrip`.

Add a storage test only for app behavior that a stub cannot show, such as what rclone writes to the server.

## When a test fails

A failed storage test keeps its folder in `/tmp/uf-*`, with the server and drive logs. On CI, the job uploads these logs and the Xcode result bundle.

## Fixture notes

- Use ASCII file names with `rclone serve s3`. Accented names make the tests flaky.
- A password-only SFTP server gets an empty `--authorized-keys`. rclone 1.75.1 loops when the authorized-keys file contains only a newline.
