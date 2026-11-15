# Graph Report - unlocalfs  (2026-11-15)

## Corpus Check
- 163 files · ~47,288 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 12 file(s) not represented in the graph (top: .xcstrings 5, (none) 3, .resolved 1)

## Summary
- 2088 nodes · 5167 edges · 126 communities (84 shown, 42 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 916 edges (avg confidence: 0.85)
- Token cost: 289,731 input · 0 output

## Graph Freshness
- Built from commit: `b79e7fb1`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- withControl
- Decodable
- Connection
- Foundation
- .validate
- deploy
- Sendable
- Testing
- .s3
- steps
- AppViewModel
- UnlocalFSPresentation
- Credentials
- MountService
- TrafficPreset
- AppPaths
- AppViewModel
- .sftp
- TrafficViewModel
- .gcs
- steps
- MacOSDesktopServices
- AppDelegate
- .post
- TrafficStore
- ConnectionDetail
- Direction
- Date
- Traffic
- ConnectionEditorViewModel
- Drive
- StubbedDrives
- FixtureResources
- S3StorageClass
- withRclone
- ShareBar
- RcloneRemote
- ConnectionField
- State
- DriveCondition
- ServiceAccountKey
- ConnectionEditorField
- CredentialStorage
- SFTPFixture
- .remove
- Provider
- Notification
- ActivityViewModel
- TransferSummary
- .update
- View
- S3StorageClass
- SFTPTrustStore
- ServerTrustChallenge
- withS3Drive
- MainView
- GCSAuthentication
- GoogleSignInRequired
- MenuBarIcon
- MountStatus
- .write
- .serve
- base
- SFTPAuthentication
- Backend
- ValidationResult
- GoogleSignInRun
- SFTPLogin
- .connect
- ConnectionDraft
- .refresh
- GCSConnectionFields
- fetchActivity
- project.yml
- ActivityStatus
- updates
- CopyName
- UploadCleanup
- TrafficViewModelTests
- UnlocalFS
- SFTPConnectionFields
- .recordTraffic
- .run
- .quitDisconnectsEveryDriveAtTheSameTime
- ShareLinkExpiry
- UnfinishedUpload
- FileActionError
- UnlocalFS
- awsFixture
- SidebarItem
- ActivitySnapshot
- SpeedSample
- .reading
- README.md
- AppViewModel
- AppViewModel
- AppPathsTests.swift
- .sample
- ControlServers
- MemoryCredentialStorage
- copyFiles
- Decision
- waitUntil
- postBuildScripts
- ClosedRange<Date>
- test
- Indicator
- RcloneRemote.swift
- ByteCountFormatStyle+Size.swift
- PackageDescription
- sftpSettings

## God Nodes (most connected - your core abstractions)
1. `Connection` - 199 edges
2. `UnlocalFSDomain` - 106 edges
3. `MountService` - 90 edges
4. `Credentials` - 90 edges
5. `ViewModelFixture` - 80 edges
6. `DriveGateway` - 52 edges
7. `FileActivity` - 50 edges
8. `AppViewModel` - 49 edges
9. `ConnectionEditorViewModel` - 45 edges
10. `Traffic` - 44 edges

## Surprising Connections (you probably didn't know these)
- `Build from source` --references--> `ViewModelFactory`  [INFERRED]
  README.md → Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/ViewModelFactory.swift
- `.body` --calls--> `Connection`  [INFERRED]
  UnlocalFS/Application/UnlocalFSApp.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `.providerPicker` --references--> `Provider`  [INFERRED]
  UnlocalFS/Presentation/Connections/ConnectionIdentityFields.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `.body` --references--> `Provider`  [INFERRED]
  UnlocalFS/Presentation/Provider+Logo.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `MacOSDesktopServices` --references--> `AppPaths`  [EXTRACTED]
  UnlocalFS/Application/MacOSDesktopServices.swift → Packages/UnlocalFSCore/Sources/UnlocalFSInfrastructure/AppPaths.swift

## Import Cycles
- None detected.

## Communities (126 total, 42 thin omitted)

### Community 0 - "withControl"
Cohesion: 0.06
Nodes (14): mark(), MountSafetyTests, shutdown(), withControl(), withFixture(), failingStatus(), revokedDrive(), ServiceRecoveryTests (+6 more)

### Community 1 - "Decodable"
Cohesion: 0.08
Nodes (37): BatchResult, CodingKeys, bytes, completedAt, dstFs, error, initiated, key (+29 more)

### Community 2 - "Connection"
Cohesion: 0.08
Nodes (7): Connection, .backend, .bucketPath, .exportsRcloneConfig, .folderPath, .usesGoogleSignIn, .usesUploadTimes

### Community 3 - "Foundation"
Cohesion: 0.07
Nodes (8): Darwin, Foundation, GRDB, Observation, Security, Subprocess, System, UnlocalFSDomain

### Community 5 - "deploy"
Cohesion: 0.05
Nodes (42): runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, environment, if (+34 more)

### Community 6 - "Sendable"
Cohesion: 0.12
Nodes (15): ConnectionRepository, DeleteConnectionUseCase, SetAutomaticConnectUseCase, DriveGateway, ConnectDriveUseCase, Outcome, connected, ejected (+7 more)

### Community 7 - "Testing"
Cohesion: 0.10
Nodes (4): Synchronization, Testing, UnlocalFSInfrastructure, UnlocalFSTestSupport

### Community 8 - ".s3"
Cohesion: 0.13
Nodes (3): AppViewModelTests, UploadCleanupTests, TestDesktopServices

### Community 9 - "steps"
Cohesion: 0.06
Nodes (35): env, runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, DEVELOPER_DIR (+27 more)

### Community 10 - "AppViewModel"
Cohesion: 0.08
Nodes (13): Activity, connected, downloading, idle, uploading, AppViewModel, .busy, .isConfirmingDelete (+5 more)

### Community 11 - "UnlocalFSPresentation"
Cohesion: 0.13
Nodes (8): AppKit, Charts, Network, ServiceManagement, SwiftUI, UniformTypeIdentifiers, UnlocalFSPresentation, UserNotifications

### Community 12 - "Credentials"
Cohesion: 0.12
Nodes (6): Credentials, .encryptionPassword, .keyPassphrase, .password, ConnectionRulesTests, ConnectionEditorViewModelTests

### Community 14 - "TrafficPreset"
Cohesion: 0.10
Nodes (18): ClosedRange<Date>, Date, DateInterval, TrafficPeriod, custom, last12Months, last30Days, last90Days (+10 more)

### Community 15 - "AppPaths"
Cohesion: 0.11
Nodes (10): AppPaths, .knownHosts, .sockets, .traffic, MountCommand, .arguments, .environment, .mountParameters (+2 more)

### Community 18 - ".sftp"
Cohesion: 0.20
Nodes (3): SaveConnectionUseCase, withWorkflowFixture(), WorkflowTests

### Community 19 - "TrafficViewModel"
Cohesion: 0.09
Nodes (18): TrafficBar, .id, TrafficViewModel, .custom, .period, .recentTotal, .unit, MainView (+10 more)

### Community 20 - ".gcs"
Cohesion: 0.11
Nodes (10): GCSDriveTests, AppSignInTests, GoogleSignInEditorTests, ViewModelFixture, .paths, .rcloneCalls, .root, .service (+2 more)

### Community 21 - "steps"
Cohesion: 0.07
Nodes (29): env, runs-on, steps, timeout-minutes, APPLE_ID, DEVELOPER_DIR, GH_TOKEN, GOOGLE_CLIENT_ID (+21 more)

### Community 22 - "MacOSDesktopServices"
Cohesion: 0.12
Nodes (4): DesktopServices, RcloneConfigDestination, MacOSDesktopServices, .opensAtLogin

### Community 23 - "AppDelegate"
Cohesion: 0.13
Nodes (3): AppDelegate, .model, .viewModels

### Community 24 - ".post"
Cohesion: 0.21
Nodes (5): ControlSocket, ControlUnreachable, RcloneError, UnixConnection, .timedOut

### Community 25 - "TrafficStore"
Cohesion: 0.10
Nodes (10): DriveTraffic, Traffic, .total, TrafficDay, TrafficRepository, TrafficSave, TrafficStore, .migrator (+2 more)

### Community 26 - "ConnectionDetail"
Cohesion: 0.14
Nodes (16): ConnectionDetail, .actions, .awsDetails, .body, .bucketDetail, .disconnected, .logo, .notices (+8 more)

### Community 27 - "Direction"
Cohesion: 0.13
Nodes (10): Direction, .color, download, .fill, .label, .symbol, upload, SpeedChart (+2 more)

### Community 28 - "Date"
Cohesion: 0.26
Nodes (6): DayCell, .body, MonthGrid, .body, TrafficRangePicker, .body

### Community 29 - "Traffic"
Cohesion: 0.16
Nodes (6): RcloneProcess, TrafficCheckpoint, TrafficMeter, .unsaved, TrafficReading, TrafficMeterTests

### Community 30 - "ConnectionEditorViewModel"
Cohesion: 0.11
Nodes (13): ConnectionEditorViewModel, .connection, .credentials, .fieldErrors, .firstInvalidField, .initialFocus, .isLocked, .locksRemoteFolder (+5 more)

### Community 31 - "Drive"
Cohesion: 0.21
Nodes (6): Drive, dump(), makeDrive(), rclone(), verifyRoundTrip(), withOfflineDrive()

### Community 32 - "StubbedDrives"
Cohesion: 0.16
Nodes (5): controlCalls(), LockableCredentialStorage, withRevokedDrive(), StubbedDrives, .rcloneCalls

### Community 33 - "FixtureResources"
Cohesion: 0.17
Nodes (4): FixtureResources, Launch, requireOutput(), withFixture()

### Community 34 - "S3StorageClass"
Cohesion: 0.20
Nodes (6): AWSSettings, ServerSideEncryption, .id, kms, s3Managed, .title

### Community 35 - "withRclone"
Cohesion: 0.25
Nodes (7): BatchReply, .current, counters(), finished(), reply(), TrafficTests, withRclone()

### Community 36 - "ShareBar"
Cohesion: 0.29
Nodes (5): ShareBar, .body, .body, TrafficStats, .body

### Community 37 - "RcloneRemote"
Cohesion: 0.07
Nodes (26): .isSignedInToGoogle, .secrets, Fields, GoogleSignInRequired, .errorDescription, GoogleToken, Connection, .driveStorage (+18 more)

### Community 39 - "ConnectionField"
Cohesion: 0.10
Nodes (19): ConnectionField, accessKey, bucket, confirmation, .displayName, encryptionPassword, endpoint, folder (+11 more)

### Community 40 - "State"
Cohesion: 0.14
Nodes (8): Sequence<FileActivity>, State, downloaded, downloading, failed, queued, uploaded, uploading

### Community 41 - "DriveCondition"
Cohesion: 0.11
Nodes (14): DriveCondition, checking, connected, disconnected, ejected, .indicator, needsAttention, needsReconnect (+6 more)

### Community 42 - "ServiceAccountKey"
Cohesion: 0.18
Nodes (3): .serviceAccountEmail, ServiceAccountKey, GCSValidationTests

### Community 43 - "ConnectionEditorField"
Cohesion: 0.12
Nodes (10): ConnectionBucketFields, .body, ConnectionEditorField, .body, ConnectionIdentityFields, .body, .providerPicker, S3ConnectionFields (+2 more)

### Community 44 - "CredentialStorage"
Cohesion: 0.12
Nodes (6): Keychain, CredentialStorage, KeychainTests, MemoryCredentialStorage, RepositoryTests, UnavailableCredentialStorage

### Community 45 - "SFTPFixture"
Cohesion: 0.21
Nodes (9): SFTPFixture, .agentSocket, .connection, .credentials, .key, .protectedKey, .served, SFTPServer (+1 more)

### Community 46 - ".remove"
Cohesion: 0.09
Nodes (4): AppPollingTests, AppSearchTests, FinderServicesTests, MenuBarActivityTests

### Community 47 - "Provider"
Cohesion: 0.11
Nodes (17): Provider, aws, .backend, cloudflare, digitalOcean, googleCloudStorage, .id, .isGeneric (+9 more)

### Community 51 - "ActivityViewModel"
Cohesion: 0.15
Nodes (6): ActivityViewModel, .refreshInterval, UploadCancellation, .message, .title, .body

### Community 52 - "TransferSummary"
Cohesion: 0.13
Nodes (11): FileActivity, .finishedAt, .id, .isUpload, .folder, .isCancellable, .name, .hasFailed (+3 more)

### Community 54 - "View"
Cohesion: 0.20
Nodes (7): ActivityFileName, .body, ActivityTable, .body, ActivityView, .activity, .idle

### Community 55 - "S3StorageClass"
Cohesion: 0.15
Nodes (12): S3StorageClass, glacierInstantRetrieval, .id, intelligentTiering, oneZoneInfrequentAccess, standard, standardInfrequentAccess, .title (+4 more)

### Community 57 - "ServerTrustChallenge"
Cohesion: 0.22
Nodes (3): ServerTrustChallenge, .errorDescription, .server

### Community 58 - "withS3Drive"
Cohesion: 0.22
Nodes (3): S3DriveTests, S3Server, withS3Drive()

### Community 59 - "MainView"
Cohesion: 0.09
Nodes (14): .header, DriveManagementItems, .body, ConnectionRow, .body, .icon, .sidebar, FocusedValues (+6 more)

### Community 60 - "GCSAuthentication"
Cohesion: 0.19
Nodes (7): GCSAuthentication, googleAccount, .id, serviceAccount, .title, GCSSettings, Config

### Community 61 - "GoogleSignInRequired"
Cohesion: 0.28
Nodes (4): DriveEjectError, .errorDescription, UploadsPendingError, .errorDescription

### Community 62 - "MenuBarIcon"
Cohesion: 0.13
Nodes (9): UnlocalFSApp, .body, MenuBarIcon, .accessibilityValue, .animatesUploads, .body, .image, MenuContent (+1 more)

### Community 63 - "MountStatus"
Cohesion: 0.22
Nodes (4): MountStatus, .isActive, .isServing, .needsReconnect

### Community 64 - ".write"
Cohesion: 0.15
Nodes (4): ConnectionStore, SavedConnectionRepository, configURL(), ConnectionTests

### Community 67 - "base"
Cohesion: 0.15
Nodes (13): ARCHS, ASSETCATALOG_COMPILER_APPICON_NAME, CODE_SIGN_STYLE, CURRENT_PROJECT_VERSION, ENABLE_HARDENED_RUNTIME, ENABLE_USER_SCRIPT_SANDBOXING, INFOPLIST_FILE, MARKETING_VERSION (+5 more)

### Community 68 - "SFTPAuthentication"
Cohesion: 0.18
Nodes (7): SFTPAuthentication, agent, .id, password, privateKey, .title, SFTPSettings

### Community 69 - "Backend"
Cohesion: 0.17
Nodes (10): Backend, gcs, .locksFolderAfterSave, s3Compatible, sftp, .supportsMultiThreadUploads, .supportsServerCopy, .supportsShareLinks (+2 more)

### Community 70 - "ValidationResult"
Cohesion: 0.26
Nodes (6): Issue, String, .isBlank, ValidationResult, .fieldErrors, .isValid

### Community 72 - "SFTPLogin"
Cohesion: 0.21
Nodes (7): SFTPDriveTests, SFTPLogin, agent, key, password, protectedKey, withSFTPDrive()

### Community 74 - "ConnectionDraft"
Cohesion: 0.25
Nodes (3): ConnectionDraft, .id, .isDuplicate

### Community 76 - "GCSConnectionFields"
Cohesion: 0.17
Nodes (7): .signInAgainButton, GCSConnectionFields, .body, .googleAccountField, .serviceAccountField, GoogleSignInButton, .body

### Community 78 - "project.yml"
Cohesion: 0.18
Nodes (10): macOS, name, options, deploymentTarget, postGenCommand, packages, UnlocalFSCore, settings (+2 more)

### Community 79 - "ActivityStatus"
Cohesion: 0.22
Nodes (7): ActivityStatus, .body, .movingText, .progress, FailedUploadButton, .body, .details

### Community 80 - "updates"
Cohesion: 0.20
Nodes (9): interval, time, timezone, updates, directory, open-pull-requests-limit, package-ecosystem, schedule (+1 more)

### Community 82 - "UploadCleanup"
Cohesion: 0.24
Nodes (4): AppViewModel, UploadCleanup, .message, .title

### Community 83 - "TrafficViewModelTests"
Cohesion: 0.16
Nodes (3): SpeedRecordingTests, TrafficViewModelTests, .yesterday

### Community 84 - "UnlocalFS"
Cohesion: 0.20
Nodes (10): Debug, Release, package, product, UnlocalFS, configFiles, dependencies, platform (+2 more)

### Community 85 - "SFTPConnectionFields"
Cohesion: 0.29
Nodes (4): SFTPConnectionFields, .authenticationHelp, .authenticationSection, .body

### Community 86 - ".recordTraffic"
Cohesion: 0.16
Nodes (7): OSLog, RcloneState, running, stopped, untracked, TrafficTracker, UploadTally

### Community 87 - ".run"
Cohesion: 0.18
Nodes (4): AppError, Command, GoogleClient, CommandTests

### Community 88 - ".quitDisconnectsEveryDriveAtTheSameTime"
Cohesion: 0.28
Nodes (3): AppQuitTests, Overlap, .peak

### Community 89 - "ShareLinkExpiry"
Cohesion: 0.22
Nodes (6): ShareLinkExpiry, day, hour, .title, week, AppViewModel

### Community 92 - "UnlocalFS"
Cohesion: 0.25
Nodes (8): config, targets, config, schemes, UnlocalFS, archive, build, run

### Community 94 - "SidebarItem"
Cohesion: 0.40
Nodes (3): SidebarItem, drive, traffic

### Community 95 - "ActivitySnapshot"
Cohesion: 0.29
Nodes (6): ActivitySnapshot, checking, .files, idle, transfers, unavailable

### Community 96 - "SpeedSample"
Cohesion: 0.29
Nodes (4): SpeedSample, .axisLimit, .fastestDownload, .fastestUpload

### Community 98 - "README.md"
Cohesion: 0.29
Nodes (6): Build from source, Documentation, Documentation development, Features, Install, License

### Community 105 - "copyFiles"
Cohesion: 0.33
Nodes (6): copyFiles, destination, subpath, buildPhase, path, sources

### Community 106 - "Decision"
Cohesion: 0.40
Nodes (4): Decision, disconnect, quit, wait

### Community 108 - "postBuildScripts"
Cohesion: 0.40
Nodes (5): basedOnDependencyAnalysis, name, script, shell, postBuildScripts

### Community 109 - "ClosedRange<Date>"
Cohesion: 0.40
Nodes (4): ClosedRange<Date>, .formattedDays, DateInterval, .formattedDays

### Community 110 - "test"
Cohesion: 0.50
Nodes (4): package, config, targets, test

### Community 111 - "Indicator"
Cohesion: 0.40
Nodes (5): Indicator, attention, connected, idle, working

## Knowledge Gaps
- **266 isolated node(s):** `.baseEnvironment`, `.rcloneType`, `.rclonePath`, `.storageRemoteName`, `.driveStorage` (+261 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 627 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **42 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Connection` connect `Connection` to `withControl`, `.validate`, `Sendable`, `.s3`, `AppViewModel`, `Credentials`, `MountService`, `AppPaths`, `AppViewModel`, `.execute`, `.sftp`, `TrafficViewModel`, `.gcs`, `MacOSDesktopServices`, `TrafficStore`, `ConnectionDetail`, `Traffic`, `ConnectionEditorViewModel`, `Drive`, `StubbedDrives`, `S3StorageClass`, `withRclone`, `.mount`, `ConnectionField`, `SFTPFixture`, `Provider`, `.unmount`, `ActivityViewModel`, `TransferSummary`, `.update`, `View`, `MainView`, `GCSAuthentication`, `MenuBarIcon`, `.write`, `.control`, `SFTPAuthentication`, `Backend`, `.connect`, `ConnectionDraft`, `.refresh`, `UploadCleanup`, `TrafficViewModelTests`, `.recordTraffic`, `.run`, `UnfinishedUpload`, `awsFixture`, `AppViewModel`, `AppViewModel`, `ControlServers`, `.deleteFileToStopUpload`?**
  _High betweenness centrality (0.222) - this node is a cross-community bridge._
- **Are the 10 inferred relationships involving `Connection` (e.g. with `AWSSettings` and `GCSSettings`) actually correct?**
  _`Connection` has 10 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.baseEnvironment`, `.rcloneType`, `.rclonePath` to the rest of the system?**
  _266 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `withControl` be split into smaller, more focused modules?**
  _Cohesion score 0.0601404741000878 - nodes in this community are weakly interconnected._
- **Why does `UnlocalFSDomain` connect `Foundation` to `Decodable`, `Connection`, `withRclone`, `AppPathsTests.swift`, `Testing`, `UnlocalFSPresentation`, `TrafficPreset`, `RcloneRemote.swift`, `TransferSummary`, `.recordTraffic`, `.run`, `.post`?**
  _High betweenness centrality (0.068) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `MountService` (e.g. with `.brokenTrafficDatabaseNeverBlocksStatusOrDisconnect()` and `.live()`) actually correct?**
  _`MountService` has 2 INFERRED edges - model-reasoned connections that need verification._
- **Should `Decodable` be split into smaller, more focused modules?**
  _Cohesion score 0.08235294117647059 - nodes in this community are weakly interconnected._