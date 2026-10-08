# Test fixtures and measurements

Run these commands in `Packages/UnlocalFSCore`. Fast checks need no storage servers or NFS mounts. They cover real repositories, isolated Keychain checks, and rclone command/config checks:

```sh
timeout 180 xcodebuild test -scheme UnlocalFSCore-Package -destination platform=macOS -skip-testing:UnlocalFSCoreTests/IntegrationTests
```

Integration checks cover real storage and mount behavior:

```sh
timeout 300 xcodebuild test -scheme UnlocalFSCore-Package -destination platform=macOS -only-testing:UnlocalFSCoreTests/IntegrationTests
```

Leave out both filters to run everything.

All storage suites and parameterized cases are nested under `IntegrationTests`. CI runs the fast checks and the integration suite on each supported macOS/Xcode runner. Each job checks the result bundle and fails if its filter selected zero tests. Failure artifacts include the Xcode result bundle and fixture logs.

## Test shape

Tests that need the same drive check several outcomes in one scenario. A test stays separate when it needs another connection setup, covers another failure mode, or waits long enough that overlapping it with other tests saves time. Merged waits add up; separate waits overlap.

## Fixture lifetime

`FixtureResources` owns a temporary root, child processes, log handles, and the drive. It registers each process immediately after launch, before readiness checks. Teardown disconnects the drive, waits for child exit, escalates termination when needed, and closes logs. Restarts append to existing logs. Setup failures also enter teardown. Cleanup runs in a detached task so cooperative test cancellation does not cancel cleanup itself. Tests cover partial setup failure, normal completion, cancellation, forced termination, cancellation with a mounted drive, a body that outlives its deadline, and the slot limit.

`withFixture` holds one of three slots from setup until cleanup ends. At most three servers and mounts run at once, and other fixtures wait for a slot. The body must finish within 180 seconds or the fixture fails and cleans up. The deadline lives inside the slot because a suite time limit also counts the time a test waits for a slot.

Servers listen on port 0. Ready means the process logged its address: `Starting s3 server on [http://…]` for S3, `SFTP server listening on …` for SFTP, and `Agent pid …` for ssh-agent. `FixtureResources.output(of:)` returns what a process logged since it launched, so log lines of an earlier run of a restarted server never count. A failed wait throws with its source location. Cancellation keeps its original error type, including during readiness. Readiness failures include the last probe error and the process log. Fixture children use an explicit environment instead of inheriting user rclone settings.

Each SFTP fixture creates only the keys and agents its requested login modes need. Changed-host keys are generated when a test requests a restart. Password-only servers disable public-key authentication explicitly: rclone 1.75.1 loops while parsing an authorized-keys file containing only a newline. GCS command/config tests do not start S3 servers.

Thrown setup/test errors and cleanup failures retain the fixture directory. Successful scopes remove it after cleanup. Nonthrowing assertion failures remain available in the Xcode result bundle; they do not retain the fixture directory. External termination of the test runner can bypass cleanup.

## Local measurements

Measured on 2026-10-08 and 2026-10-09: Apple M2 Pro, macOS 27.2, Xcode 27.0 (27A266a), pinned rclone 1.75.1. Xcode test-session time excludes compilation and package resolution. "Throttled" runs use `taskpolicy -b`, which pins the test runner and its children to efficiency cores with throttled I/O and reproduces CI-only timeouts.

| Lane | Serialized suite | Three slots, merged tests |
| --- | ---: | ---: |
| Integration, idle | 59 tests, 90.3 s | 29 tests, 25.6 s to 27.1 s (3 runs) |
| Integration, throttled | 59 tests, 179.0 s | 29 tests, 58.8 s and 60.2 s |
| Fast lane, idle | 120 tests, 5.1 s | 114 tests, 6.3 s |

Every run passed. Three runs per lane cannot show a flake rate.

The slot width came from the 59-test suite before merging tests. One run per width, idle: 1 slot 97 s, 2 slots 46 s, 3 slots 29 s, 4 slots 26 s, 5 slots 21 s. Throttled: 1 slot 179 s, 2 slots 103 s, 3 slots 84 s twice, 5 slots 81 s. Three slots keep most of the gain and leave room on the 3-vCPU CI runners. Three tests made 44% of the summed test time: a failing upload (rclone waits 5 seconds before it uploads, then retries with backoff), a full upload scenario, and a reconnect after a killed service (not profiled). They wait on rclone and the NFS client, so overlapping them matters more than starting servers faster.

### Shared S3 experiment

Compared the same 35 test functions in `MountTests`, `DriveFeatureTests`, and `DriveIOTests`, including their parameterized cases, before tests were merged. One SFTP case stays in the selected workload. Each setup ran twice, in order: dedicated, dedicated, shared, shared. The first run of each implementation compiled it; the second used `test-without-building`. The table uses Swift Testing's test-run duration, excluding compilation. Each run passed.

| Setup | Run 1 | Run 2 | Mean | S3 server starts per run |
| --- | ---: | ---: | ---: | ---: |
| Dedicated server per fixture | 64.146 s | 62.853 s | 63.500 s | 41 |
| One suite-owned S3 server | 59.657 s | 58.884 s | 59.271 s | 1 |

Sharing saved 4.229 seconds, or 6.7%, for this workload. The prototype used a nonrecursive `TestScoping` suite trait and a task-local server reference. Every test kept a unique bucket, config, mount, cache, and RC socket. MD5 ETags stayed enabled. Both variants used the same readiness and cleanup helpers.

The sample is too small, and limited to one machine, to establish a CI speedup or flake-rate improvement. Dedicated servers remain the default. The measured benefit does not yet establish that shared-server coupling is worthwhile.
