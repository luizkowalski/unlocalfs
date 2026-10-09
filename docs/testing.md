# Tests

Run every test in `Packages/UnlocalFSCore`:

```sh
timeout 180 xcodebuild test -scheme UnlocalFSCore-Package -destination platform=macOS
```

CI runs the same command on each supported macOS/Xcode runner. Failure artifacts include the Xcode result bundle and fixture logs.

## What the tests cover

Most tests check app logic: domain rules, view models, use cases, saved connections, the Keychain, and how `MountService` reads rclone output. They use real repositories and a stub `rclone` shell script.

Storage tests run the pinned rclone against a local server, one suite per storage type:

- `S3DriveTests`: a drive on `rclone serve s3` downloads, uploads, and deletes files, and refuses to disconnect while an upload is pending. An encrypted drive stores only ciphertext, and its exported rclone config reads the file back.
- `SFTPDriveTests`: the same round trip on `rclone serve sftp` for each login (password, key, protected key, agent). A new or changed server key needs approval before the drive connects.
- `GCSDriveTests`: rclone has no GCS server, so the tests do not mount a GCS drive. They check that the service-account key reaches rclone and that the exported config has the key on one line. To add a mount test, start a GCS emulator in `withGCSDrive` and call `verifyRoundTrip`.

Storage tests do not check rclone or macOS features such as read-only mounts, NFS options, or log rotation.

## Fixture lifetime

`withFixture` gives each test its own temporary root, servers, and drive, so storage tests run in parallel. `FixtureResources` registers each process immediately after launch. Teardown disconnects the drive, stops child processes (with escalation to `SIGKILL`), and closes logs. Cleanup runs in a detached task, so a cancelled or timed-out test still cleans up. Thrown errors keep the fixture directory under `/tmp/uf-*`. Successful tests remove it.

Servers listen on port 0. A server is ready when it logs its address: `Starting s3 server on [http://…]` for S3, `SFTP server listening on …` for SFTP, and `Agent pid …` for ssh-agent. If readiness fails, the error includes the last probe error and the process log. Fixture processes get an explicit environment and do not inherit user rclone settings. Password-only SFTP servers turn off public-key authentication explicitly, because rclone 1.75.1 loops while it parses an authorized-keys file that contains only a newline.

## Measurements

Measured on 2026-10-09: Apple M2 Pro, macOS 27.2, Xcode 27.0, pinned rclone 1.75.1. The table shows Xcode test-session time, without compilation. "Throttled" uses `taskpolicy -b`, which puts the test runner on efficiency cores with throttled I/O, similar to CI.

| Run | Tests | Time |
| --- | ---: | ---: |
| Idle | 110 | 5.6 s, 5.9 s, 7.5 s |
| Throttled | 110 | 15.5 s, 17.2 s |

Before this change, CI used two lanes: 114 fast tests (6.3 s) and 29 integration tests (26 s idle, 59 s throttled).
