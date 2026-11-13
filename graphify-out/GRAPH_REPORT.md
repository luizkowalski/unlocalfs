# Graph Report - unlocalfs  (2026-11-13)

## Corpus Check
- 164 files · ~47,140 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 12 file(s) not represented in the graph (top: .xcstrings 5, (none) 3, .resolved 1)

## Summary
- 2075 nodes · 5167 edges · 117 communities (84 shown, 33 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 916 edges (avg confidence: 0.85)
- Token cost: 289,731 input · 0 output

## Graph Freshness
- Built from commit: `dc0d80ab`
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
- .shareLink
- .sftp
- TrafficViewModel
- .gcs
- steps
- MacOSDesktopServices
- AppDelegate
- ConnectionStore
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
- TrafficView
- RcloneRemote
- Equatable
- ConnectionField
- FileActivity
- DriveCondition
- .serve
- ConnectionEditorField
- CredentialStorage
- SFTPFixture
- .remove
- Provider
- ViewModelFixture
- AppError
- ActivityViewModel
- TransferSummary
- .update
- View
- State
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
- GoogleSignInRun
- SFTPLogin
- StatusIndicator
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
- AppSearchTests
- Darwin
- GoogleToken
- UnlocalFS
- .body
- SFTPSettings
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
- GoogleSignInButton
- waitUntil
- postBuildScripts
- ClosedRange<Date>
- test
- Command.swift
- RcloneRemote.swift
- ByteCountFormatStyle+Size.swift
- PackageDescription
- sftpSettings

## God Nodes (most connected - your core abstractions)
1. `Connection` - 225 edges
2. `UnlocalFSDomain` - 106 edges
3. `Credentials` - 90 edges
4. `MountService` - 90 edges
5. `ViewModelFixture` - 80 edges
6. `DriveGateway` - 52 edges
7. `FileActivity` - 50 edges
8. `AppViewModel` - 49 edges
9. `ConnectionEditorViewModel` - 45 edges
10. `Traffic` - 44 edges

## Surprising Connections (you probably didn't know these)
- `Build from source` --references--> `ViewModelFactory`  [INFERRED]
  README.md → Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/ViewModelFactory.swift
- `.body` --references--> `Provider`  [INFERRED]
  UnlocalFS/Presentation/Provider+Logo.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `.body` --calls--> `Connection`  [INFERRED]
  UnlocalFS/Application/UnlocalFSApp.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `.providerPicker` --references--> `Provider`  [INFERRED]
  UnlocalFS/Presentation/Connections/ConnectionIdentityFields.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `.selected` --references--> `Connection`  [INFERRED]
  Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/AppViewModel.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift

## Import Cycles
- None detected.

## Communities (117 total, 33 thin omitted)

### Community 0 - "withControl"
Cohesion: 0.05
Nodes (17): ControlSocket, ControlUnreachable, RcloneError, UnixConnection, .timedOut, mark(), MountSafetyTests, shutdown() (+9 more)

### Community 1 - "Decodable"
Cohesion: 0.08
Nodes (37): BatchResult, CodingKeys, bytes, completedAt, dstFs, error, initiated, key (+29 more)

### Community 2 - "Connection"
Cohesion: 0.06
Nodes (12): Connection, .backend, .bucketPath, .exportsRcloneConfig, .folderPath, .usesGoogleSignIn, .usesUploadTimes, .driveStorage (+4 more)

### Community 3 - "Foundation"
Cohesion: 0.08
Nodes (5): Foundation, GRDB, Observation, Security, UnlocalFSDomain

### Community 4 - ".validate"
Cohesion: 0.07
Nodes (13): .serviceAccountEmail, ServiceAccountKey, Issue, String, .isBlank, ValidationResult, .fieldErrors, .isValid (+5 more)

### Community 5 - "deploy"
Cohesion: 0.05
Nodes (42): runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, environment, if (+34 more)

### Community 6 - "Sendable"
Cohesion: 0.11
Nodes (19): ConnectionRepository, DeleteConnectionUseCase, SetAutomaticConnectUseCase, DriveGateway, ConnectDriveUseCase, Decision, disconnect, quit (+11 more)

### Community 7 - "Testing"
Cohesion: 0.13
Nodes (4): Synchronization, Testing, UnlocalFSInfrastructure, UnlocalFSTestSupport

### Community 9 - "steps"
Cohesion: 0.06
Nodes (35): env, runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, DEVELOPER_DIR (+27 more)

### Community 10 - "AppViewModel"
Cohesion: 0.06
Nodes (21): Activity, connected, downloading, idle, uploading, AppViewModel, .busy, .isConfirmingDelete (+13 more)

### Community 11 - "UnlocalFSPresentation"
Cohesion: 0.11
Nodes (8): AppKit, Charts, Network, ServiceManagement, SwiftUI, UniformTypeIdentifiers, UnlocalFSPresentation, UserNotifications

### Community 12 - "Credentials"
Cohesion: 0.11
Nodes (6): Credentials, .encryptionPassword, .keyPassphrase, .password, ConnectionRulesTests, ConnectionEditorViewModelTests

### Community 14 - "TrafficPreset"
Cohesion: 0.09
Nodes (17): ClosedRange<Date>, DateInterval, TrafficPeriod, custom, last12Months, last30Days, last90Days, TrafficPreset (+9 more)

### Community 15 - "AppPaths"
Cohesion: 0.10
Nodes (10): AppPaths, .knownHosts, .sockets, .traffic, MountCommand, .arguments, .environment, .mountParameters (+2 more)

### Community 16 - "AppViewModel"
Cohesion: 0.13
Nodes (3): AppViewModel, .activity, AppViewModel

### Community 17 - ".shareLink"
Cohesion: 0.09
Nodes (7): FileActionError, ShareLinkExpiry, day, hour, .title, week, AppViewModel

### Community 18 - ".sftp"
Cohesion: 0.20
Nodes (3): SaveConnectionUseCase, withWorkflowFixture(), WorkflowTests

### Community 19 - "TrafficViewModel"
Cohesion: 0.12
Nodes (11): DriveTraffic, TrafficRepository, TrafficBar, .id, TrafficViewModel, .custom, .period, .recentTotal (+3 more)

### Community 21 - "steps"
Cohesion: 0.07
Nodes (29): env, runs-on, steps, timeout-minutes, APPLE_ID, DEVELOPER_DIR, GH_TOKEN, GOOGLE_CLIENT_ID (+21 more)

### Community 22 - "MacOSDesktopServices"
Cohesion: 0.12
Nodes (4): DesktopServices, RcloneConfigDestination, MacOSDesktopServices, .opensAtLogin

### Community 23 - "AppDelegate"
Cohesion: 0.13
Nodes (3): AppDelegate, .model, .viewModels

### Community 24 - "ConnectionStore"
Cohesion: 0.17
Nodes (5): ConnectionStore, SavedConnectionRepository, MemoryCredentialStorage, RepositoryTests, UnavailableCredentialStorage

### Community 25 - "TrafficStore"
Cohesion: 0.14
Nodes (4): TrafficDay, TrafficStore, .migrator, TrafficStoreTests

### Community 26 - "ConnectionDetail"
Cohesion: 0.17
Nodes (11): ConnectionDetail, .awsDetails, .body, .bucketDetail, .disconnected, .logo, .notices, .sftpDetails (+3 more)

### Community 27 - "Direction"
Cohesion: 0.13
Nodes (10): Direction, .color, download, .fill, .label, .symbol, upload, SpeedChart (+2 more)

### Community 28 - "Date"
Cohesion: 0.15
Nodes (8): UnfinishedUpload, Date, DayCell, .body, MonthGrid, .body, TrafficRangePicker, .body

### Community 29 - "Traffic"
Cohesion: 0.28
Nodes (4): Traffic, .total, TrafficMeter, TrafficMeterTests

### Community 30 - "ConnectionEditorViewModel"
Cohesion: 0.14
Nodes (11): ConnectionEditorViewModel, .connection, .credentials, .fieldErrors, .firstInvalidField, .initialFocus, .isLocked, .locksRemoteFolder (+3 more)

### Community 31 - "Drive"
Cohesion: 0.20
Nodes (7): Drive, dump(), makeDrive(), rclone(), verifyRoundTrip(), GCSDriveTests, withOfflineDrive()

### Community 32 - "StubbedDrives"
Cohesion: 0.15
Nodes (5): controlCalls(), LockableCredentialStorage, withRevokedDrive(), StubbedDrives, .rcloneCalls

### Community 33 - "FixtureResources"
Cohesion: 0.17
Nodes (4): FixtureResources, Launch, requireOutput(), withFixture()

### Community 34 - "S3StorageClass"
Cohesion: 0.12
Nodes (14): AWSSettings, S3StorageClass, glacierInstantRetrieval, .id, intelligentTiering, oneZoneInfrequentAccess, standard, standardInfrequentAccess (+6 more)

### Community 35 - "withRclone"
Cohesion: 0.25
Nodes (7): BatchReply, .current, counters(), finished(), reply(), TrafficTests, withRclone()

### Community 36 - "TrafficView"
Cohesion: 0.12
Nodes (15): .detail, ProviderIcon, .body, ShareBar, .body, TrafficChart, TrafficList, .body (+7 more)

### Community 37 - "RcloneRemote"
Cohesion: 0.18
Nodes (11): NamedRemote, Options, RcloneRemote, .cryptOptions, .environment, .gcsOptions, .namedRemotes, .options (+3 more)

### Community 38 - "Equatable"
Cohesion: 0.19
Nodes (5): RcloneProcess, TrafficCheckpoint, .unsaved, TrafficReading, TrafficSave

### Community 39 - "ConnectionField"
Cohesion: 0.11
Nodes (19): ConnectionField, accessKey, bucket, confirmation, .displayName, encryptionPassword, endpoint, folder (+11 more)

### Community 40 - "FileActivity"
Cohesion: 0.14
Nodes (10): FileActivity, .finishedAt, .id, .isUpload, Sequence<FileActivity>, .folder, .isCancellable, .name (+2 more)

### Community 41 - "DriveCondition"
Cohesion: 0.11
Nodes (14): DriveCondition, checking, connected, disconnected, ejected, .indicator, needsAttention, needsReconnect (+6 more)

### Community 42 - ".serve"
Cohesion: 0.18
Nodes (3): FakeStorage, .uploadCount, UploadCleanupTests

### Community 43 - "ConnectionEditorField"
Cohesion: 0.13
Nodes (10): ConnectionBucketFields, .body, ConnectionEditorField, .body, ConnectionIdentityFields, .body, .providerPicker, S3ConnectionFields (+2 more)

### Community 44 - "CredentialStorage"
Cohesion: 0.24
Nodes (3): Keychain, CredentialStorage, KeychainTests

### Community 45 - "SFTPFixture"
Cohesion: 0.21
Nodes (9): SFTPFixture, .agentSocket, .connection, .credentials, .key, .protectedKey, .served, SFTPServer (+1 more)

### Community 46 - ".remove"
Cohesion: 0.11
Nodes (3): AppPollingTests, MenuBarActivityTests, SpeedRecordingTests

### Community 47 - "Provider"
Cohesion: 0.12
Nodes (15): Provider, aws, .backend, cloudflare, digitalOcean, googleCloudStorage, .id, .isGeneric (+7 more)

### Community 49 - "ViewModelFixture"
Cohesion: 0.15
Nodes (9): FinderServicesTests, Notification, ViewModelFixture, .paths, .rcloneCalls, .root, .service, .signInEnvironment (+1 more)

### Community 51 - "ActivityViewModel"
Cohesion: 0.17
Nodes (6): ActivityViewModel, .refreshInterval, UploadCancellation, .message, .title, .body

### Community 54 - "View"
Cohesion: 0.16
Nodes (11): ActivityFileName, .body, ActivityTable, .body, ActivityView, .activity, .idle, FittedScrollView (+3 more)

### Community 55 - "State"
Cohesion: 0.15
Nodes (9): State, downloaded, downloading, failed, queued, uploaded, uploading, ConnectionEditor (+1 more)

### Community 57 - "ServerTrustChallenge"
Cohesion: 0.22
Nodes (3): ServerTrustChallenge, .errorDescription, .server

### Community 58 - "withS3Drive"
Cohesion: 0.22
Nodes (3): S3DriveTests, S3Server, withS3Drive()

### Community 59 - "MainView"
Cohesion: 0.14
Nodes (7): MainView, .sidebar, FocusedValues, SidebarSearchField, .body, TrafficCard, .body

### Community 60 - "GCSAuthentication"
Cohesion: 0.19
Nodes (7): GCSAuthentication, googleAccount, .id, serviceAccount, .title, GCSSettings, Config

### Community 61 - "GoogleSignInRequired"
Cohesion: 0.18
Nodes (6): GoogleSignInRequired, .errorDescription, DriveEjectError, .errorDescription, UploadsPendingError, .errorDescription

### Community 62 - "MenuBarIcon"
Cohesion: 0.21
Nodes (5): MenuBarIcon, .accessibilityValue, .animatesUploads, .body, .image

### Community 63 - "MountStatus"
Cohesion: 0.19
Nodes (4): MountStatus, .isActive, .isServing, .needsReconnect

### Community 67 - "base"
Cohesion: 0.15
Nodes (13): ARCHS, ASSETCATALOG_COMPILER_APPICON_NAME, CODE_SIGN_STYLE, CURRENT_PROJECT_VERSION, ENABLE_HARDENED_RUNTIME, ENABLE_USER_SCRIPT_SANDBOXING, INFOPLIST_FILE, MARKETING_VERSION (+5 more)

### Community 68 - "SFTPAuthentication"
Cohesion: 0.17
Nodes (10): SFTPAuthentication, agent, .id, password, privateKey, .title, Pane, connection (+2 more)

### Community 69 - "Backend"
Cohesion: 0.17
Nodes (10): Backend, gcs, .locksFolderAfterSave, s3Compatible, sftp, .supportsMultiThreadUploads, .supportsServerCopy, .supportsShareLinks (+2 more)

### Community 72 - "SFTPLogin"
Cohesion: 0.21
Nodes (7): SFTPDriveTests, SFTPLogin, agent, key, password, protectedKey, withSFTPDrive()

### Community 73 - "StatusIndicator"
Cohesion: 0.18
Nodes (9): .actions, .header, DriveManagementItems, .body, ConnectionRow, .body, .icon, StatusIndicator (+1 more)

### Community 74 - "ConnectionDraft"
Cohesion: 0.18
Nodes (4): ConnectionDraft, .id, .isDuplicate, .body

### Community 76 - "GCSConnectionFields"
Cohesion: 0.20
Nodes (3): GCSConnectionFields, .body, .serviceAccountField

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

### Community 84 - "UnlocalFS"
Cohesion: 0.20
Nodes (10): Debug, Release, package, product, UnlocalFS, configFiles, dependencies, platform (+2 more)

### Community 85 - "SFTPConnectionFields"
Cohesion: 0.29
Nodes (4): SFTPConnectionFields, .authenticationHelp, .authenticationSection, .body

### Community 86 - ".recordTraffic"
Cohesion: 0.33
Nodes (3): OSLog, TrafficTracker, UploadTally

### Community 88 - ".quitDisconnectsEveryDriveAtTheSameTime"
Cohesion: 0.28
Nodes (3): AppQuitTests, Overlap, .peak

### Community 90 - "Darwin"
Cohesion: 0.25
Nodes (5): Darwin, RcloneState, running, stopped, untracked

### Community 91 - "GoogleToken"
Cohesion: 0.36
Nodes (4): .isSignedInToGoogle, .secrets, Fields, GoogleToken

### Community 92 - "UnlocalFS"
Cohesion: 0.25
Nodes (8): config, targets, config, schemes, UnlocalFS, archive, build, run

### Community 93 - ".body"
Cohesion: 0.33
Nodes (4): UnlocalFSApp, .body, MenuContent, .body

### Community 94 - "SFTPSettings"
Cohesion: 0.33
Nodes (3): SFTPSettings, .agentSocketPath, .keyPath

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

### Community 106 - "GoogleSignInButton"
Cohesion: 0.33
Nodes (4): .signInAgainButton, .googleAccountField, GoogleSignInButton, .body

### Community 108 - "postBuildScripts"
Cohesion: 0.40
Nodes (5): basedOnDependencyAnalysis, name, script, shell, postBuildScripts

### Community 109 - "ClosedRange<Date>"
Cohesion: 0.40
Nodes (4): ClosedRange<Date>, .formattedDays, DateInterval, .formattedDays

### Community 110 - "test"
Cohesion: 0.50
Nodes (4): package, config, targets, test

## Knowledge Gaps
- **266 isolated node(s):** `PackageDescription`, `standard`, `intelligentTiering`, `standardInfrequentAccess`, `oneZoneInfrequentAccess` (+261 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 618 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **33 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Connection` connect `Connection` to `withControl`, `.validate`, `Sendable`, `.s3`, `AppViewModel`, `Credentials`, `MountService`, `AppPaths`, `AppViewModel`, `.shareLink`, `.sftp`, `TrafficViewModel`, `.gcs`, `MacOSDesktopServices`, `ConnectionStore`, `ConnectionDetail`, `Date`, `ConnectionEditorViewModel`, `Drive`, `StubbedDrives`, `S3StorageClass`, `withRclone`, `RcloneRemote`, `Equatable`, `FileActivity`, `.serve`, `SFTPFixture`, `Provider`, `.status`, `AppError`, `ActivityViewModel`, `.update`, `View`, `GCSAuthentication`, `MountStatus`, `.write`, `.control`, `Backend`, `.execute`, `StatusIndicator`, `ConnectionDraft`, `.refresh`, `UploadCleanup`, `TrafficViewModelTests`, `.recordTraffic`, `.body`, `SFTPSettings`, `AppViewModel`, `AppViewModel`, `ControlServers`, `RcloneRemote.swift`?**
  _High betweenness centrality (0.265) - this node is a cross-community bridge._
- **Are the 10 inferred relationships involving `Connection` (e.g. with `AWSSettings` and `GCSSettings`) actually correct?**
  _`Connection` has 10 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `standard`, `intelligentTiering` to the rest of the system?**
  _266 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `withControl` be split into smaller, more focused modules?**
  _Cohesion score 0.05493827160493827 - nodes in this community are weakly interconnected._
- **Why does `UnlocalFSDomain` connect `Foundation` to `withControl`, `Decodable`, `Connection`, `withRclone`, `AppPathsTests.swift`, `Testing`, `UnlocalFSPresentation`, `TrafficPreset`, `Command.swift`, `RcloneRemote.swift`, `TransferSummary`, `.recordTraffic`, `Darwin`, `Drive`?**
  _High betweenness centrality (0.071) - this node is a cross-community bridge._
- **Are the 29 inferred relationships involving `Credentials` (e.g. with `ConnectionEditorViewModel` and `.credentialsSavedBeforeEncryptionHaveNoPassword()`) actually correct?**
  _`Credentials` has 29 INFERRED edges - model-reasoned connections that need verification._
- **Should `Decodable` be split into smaller, more focused modules?**
  _Cohesion score 0.08235294117647059 - nodes in this community are weakly interconnected._