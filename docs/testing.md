# Test fixtures and measurements

Run `timeout 180 mise test-fast` for checks without storage servers or NFS mounts. This includes real repositories, isolated Keychain checks, and rclone command/config checks. Run `timeout 300 mise test-integration` for real storage and mount behavior. `timeout 300 mise test` still runs both.

All storage suites and parameterized cases are nested under `IntegrationTests`. Its `.serialized` trait gives them one concurrency boundary. Fast tests remain parallel. CI runs both fast checks and the full integration suite on each supported macOS/Xcode runner. Each job checks the result bundle and fails if its filter selected zero tests. Failure artifacts include the Xcode result bundle and fixture logs.

## Fixture lifetime

`FixtureResources` owns a temporary root, child processes, log handles, and the drive. It registers each process immediately after launch, before readiness checks. Teardown disconnects the drive, waits for child exit, escalates termination when needed, and closes logs. Restarts append to existing logs. Setup failures also enter teardown. Cleanup runs in a detached task so cooperative test cancellation does not cancel cleanup itself. Tests cover partial setup failure, normal completion, cancellation, forced termination, and cancellation with a mounted drive.

S3 and SFTP readiness require an authenticated listing; agent readiness requires an agent operation. Probe retries belong to the bounded fixture polling loop. A failed wait throws with its source location. Cancellation keeps its original error type, including during readiness. Readiness failures include the last probe error and server log. Fixture children use an explicit environment instead of inheriting user rclone settings.

Each SFTP fixture creates only the keys and agents its requested login modes need. Changed-host keys are generated when a test requests a restart. Password-only servers disable public-key authentication explicitly: rclone 1.75.1 loops while parsing an authorized-keys file containing only a newline. GCS command/config tests do not start S3 servers.

Thrown setup/test errors and cleanup failures retain the fixture directory. Successful scopes remove it after cleanup. Nonthrowing assertion failures remain available in the Xcode result bundle; they do not retain the fixture directory. External termination of the test runner can bypass cleanup.

## Local measurements

Measured on 2026-10-08: Apple M2 Pro, macOS 27.2 (26B5086k), Xcode 27.0 (27A266a), pinned rclone 1.75.1. Xcode test-session time excludes compilation and package resolution.

The original full suite passed 171 test functions in 50.72 seconds. A full run with the new serialization and the first five regressions passed 176 functions in 91.45 seconds. Global serialization costs local wall time; the fast lane gives short feedback without omitting integration coverage from CI. The final full run passed 179 functions in 91.99 seconds. The final fast-lane run passed 120 functions in 5.13 seconds. Under background priority, all 59 integration functions passed in 166.86 seconds, but the 180-second outer budget interrupted Xcode during finalization. A repeated full background run passed 178 functions and completed Xcode finalization in 181.45 seconds. Use a 300-second outer budget for serialized integration/full runs; the fast lane keeps 180 seconds.

### Shared S3 experiment

Compared the same 35 test functions in `MountTests`, `DriveFeatureTests`, and `DriveIOTests`, including their parameterized cases. One SFTP case stays in the selected workload. Each setup ran twice, in order: dedicated, dedicated, shared, shared. The first run of each implementation compiled it; the second used `test-without-building`. The table uses Swift Testing's test-run duration, excluding compilation. Each run passed.

| Setup | Run 1 | Run 2 | Mean | S3 server starts per run |
| --- | ---: | ---: | ---: | ---: |
| Dedicated server per fixture | 64.146 s | 62.853 s | 63.500 s | 41 |
| One suite-owned S3 server | 59.657 s | 58.884 s | 59.271 s | 1 |

Sharing saved 4.229 seconds, or 6.7%, for this workload. The prototype used a nonrecursive `TestScoping` suite trait and a task-local server reference. Every test kept a unique bucket, config, mount, cache, and RC socket. MD5 ETags stayed enabled. Both variants used the same readiness and cleanup helpers.

The sample is too small, and limited to one machine, to establish a CI speedup or flake-rate improvement. Dedicated servers remain the default. The measured benefit does not yet establish that shared-server coupling is worthwhile.
