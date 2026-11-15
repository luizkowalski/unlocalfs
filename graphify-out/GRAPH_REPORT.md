# Graph Report - unlocalfs  (2026-11-16)

## Corpus Check
- 163 files · ~47,288 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 12 file(s) not represented in the graph (top: .xcstrings 5, (none) 3, .resolved 1)

## Summary
- 2075 nodes · 5167 edges · 115 communities (82 shown, 33 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 916 edges (avg confidence: 0.85)
- Token cost: 289,731 input · 0 output

## Graph Freshness
- Built from commit: `a94f75a0`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Connection
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
- LocalizedError
- Credentials
- MountService
- TrafficPreset
- AppPaths
- AppViewModel
- ConnectionStore
- .sftp
- TrafficViewModel
- .gcs
- steps
- MacOSDesktopServices
- AppDelegate
- withControl
- TrafficStore
- ConnectionDetail
- .execute
- Traffic
- ConnectionEditorViewModel
- MountStatus
- StubbedDrives
- FixtureResources
- S3StorageClass
- withRclone
- ShareBar
- RcloneRemote
- ViewModelFactory
- ConnectionField
- State
- DriveCondition
- ServiceAccountKey
- ConnectionDraft
- CredentialStorage
- SFTPFixture
- .remove
- .unmount
- ActivityViewModel
- AppViewModel
- AppSearchTests
- TransferSummary
- .connect
- View
- S3StorageClass
- SFTPTrustStore
- SFTPSettings
- withS3Drive
- MainView
- AppError
- GoogleSignInRequired
- MenuBarIcon
- MountStatus
- .write
- .control
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
- TrafficView
- SpeedSample
- awsFixture
- ClosedRange<Date>
- SpeedSample
- README.md
- AppViewModel
- AppViewModel
- AppPathsTests.swift
- RcloneRemote.swift
- ControlServers
- MemoryCredentialStorage
- UploadTally
- Decision
- waitUntil
- ClosedRange<Date>
- test
- Indicator
- RcloneRemote.swift
- mount
- .deleteFileToStopUpload

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

## Communities (115 total, 33 thin omitted)

### Community 0 - "Connection"
Cohesion: 0.06
Nodes (15): Connection, .backend, .bucketPath, .exportsRcloneConfig, .folderPath, .usesGoogleSignIn, .usesUploadTimes, .driveStorage (+7 more)

### Community 1 - "Decodable"
Cohesion: 0.08
Nodes (37): BatchResult, CodingKeys, bytes, completedAt, dstFs, error, initiated, key (+29 more)

### Community 2 - "Connection"
Cohesion: 0.13
Nodes (4): Synchronization, Testing, UnlocalFSInfrastructure, UnlocalFSTestSupport

### Community 3 - "Foundation"
Cohesion: 0.13
Nodes (3): AppDelegate, .model, .viewModels

### Community 4 - ".validate"
Cohesion: 0.08
Nodes (5): Foundation, GRDB, Observation, Security, UnlocalFSDomain

### Community 5 - "deploy"
Cohesion: 0.11
Nodes (3): Darwin, MountService, .baseEnvironment

### Community 6 - "Sendable"
Cohesion: 0.05
Nodes (42): runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, environment, if (+34 more)

### Community 7 - "Testing"
Cohesion: 0.07
Nodes (13): .serviceAccountEmail, ServiceAccountKey, Issue, String, .isBlank, ValidationResult, .fieldErrors, .isValid (+5 more)

### Community 8 - ".s3"
Cohesion: 0.09
Nodes (17): ClosedRange<Date>, DateInterval, TrafficPeriod, custom, last12Months, last30Days, last90Days, TrafficPreset (+9 more)

### Community 11 - "LocalizedError"
Cohesion: 0.18
Nodes (5): FileActionError, DriveEjectError, .errorDescription, UploadsPendingError, .errorDescription

### Community 12 - "Credentials"
Cohesion: 0.06
Nodes (35): env, runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, DEVELOPER_DIR (+27 more)

### Community 13 - "MountService"
Cohesion: 0.14
Nodes (4): TrafficDay, TrafficStore, .migrator, TrafficStoreTests

### Community 14 - "TrafficPreset"
Cohesion: 0.11
Nodes (8): AppKit, Charts, Network, ServiceManagement, SwiftUI, UniformTypeIdentifiers, UnlocalFSPresentation, UserNotifications

### Community 15 - "AppPaths"
Cohesion: 0.09
Nodes (18): .isSignedInToGoogle, .secrets, Fields, GoogleSignInRequired, .errorDescription, GoogleToken, GoogleClient, NamedRemote (+10 more)

### Community 16 - "AppViewModel"
Cohesion: 0.07
Nodes (16): Activity, connected, downloading, idle, uploading, AppViewModel, .busy, .isConfirmingDelete (+8 more)

### Community 17 - "ConnectionStore"
Cohesion: 0.05
Nodes (17): SaveConnectionUseCase, ConnectionStore, CredentialStorage, SavedConnectionRepository, configURL(), ConnectionTests, MemoryCredentialStorage, RepositoryTests (+9 more)

### Community 18 - ".sftp"
Cohesion: 0.07
Nodes (29): env, runs-on, steps, timeout-minutes, APPLE_ID, DEVELOPER_DIR, GH_TOKEN, GOOGLE_CLIENT_ID (+21 more)

### Community 19 - "TrafficViewModel"
Cohesion: 0.12
Nodes (11): DriveTraffic, TrafficRepository, TrafficBar, .id, TrafficViewModel, .custom, .period, .recentTotal (+3 more)

### Community 20 - ".gcs"
Cohesion: 0.13
Nodes (13): ConnectionRepository, DeleteConnectionUseCase, SetAutomaticConnectUseCase, DriveGateway, ConnectDriveUseCase, Outcome, connected, ejected (+5 more)

### Community 21 - "steps"
Cohesion: 0.17
Nodes (11): ConnectionDetail, .awsDetails, .body, .bucketDetail, .disconnected, .logo, .notices, .sftpDetails (+3 more)

### Community 22 - "MacOSDesktopServices"
Cohesion: 0.11
Nodes (6): Credentials, .encryptionPassword, .keyPassphrase, .password, ConnectionRulesTests, ConnectionEditorViewModelTests

### Community 23 - "AppDelegate"
Cohesion: 0.12
Nodes (10): AppPaths, .knownHosts, .sockets, .traffic, MountCommand, .arguments, .environment, .mountParameters (+2 more)

### Community 24 - "withControl"
Cohesion: 0.05
Nodes (17): ControlSocket, ControlUnreachable, RcloneError, UnixConnection, .timedOut, mark(), MountSafetyTests, shutdown() (+9 more)

### Community 25 - "TrafficStore"
Cohesion: 0.19
Nodes (5): RcloneProcess, TrafficCheckpoint, .unsaved, TrafficReading, TrafficSave

### Community 26 - "ConnectionDetail"
Cohesion: 0.12
Nodes (4): DesktopServices, RcloneConfigDestination, MacOSDesktopServices, .opensAtLogin

### Community 28 - ".execute"
Cohesion: 0.08
Nodes (4): Decision, disconnect, quit, wait

### Community 29 - "Traffic"
Cohesion: 0.13
Nodes (10): Direction, .color, download, .fill, .label, .symbol, upload, SpeedChart (+2 more)

### Community 30 - "ConnectionEditorViewModel"
Cohesion: 0.28
Nodes (4): Traffic, .total, TrafficMeter, TrafficMeterTests

### Community 31 - "MountStatus"
Cohesion: 0.19
Nodes (4): MountStatus, .isActive, .isServing, .needsReconnect

### Community 32 - "StubbedDrives"
Cohesion: 0.12
Nodes (15): Provider, aws, .backend, cloudflare, digitalOcean, googleCloudStorage, .id, .isGeneric (+7 more)

### Community 33 - "FixtureResources"
Cohesion: 0.14
Nodes (11): ConnectionEditorViewModel, .connection, .credentials, .fieldErrors, .firstInvalidField, .initialFocus, .isLocked, .locksRemoteFolder (+3 more)

### Community 34 - "S3StorageClass"
Cohesion: 0.15
Nodes (9): FinderServicesTests, Notification, ViewModelFixture, .paths, .rcloneCalls, .root, .service, .signInEnvironment (+1 more)

### Community 35 - "withRclone"
Cohesion: 0.17
Nodes (4): FixtureResources, Launch, requireOutput(), withFixture()

### Community 36 - "ShareBar"
Cohesion: 0.25
Nodes (7): BatchReply, .current, counters(), finished(), reply(), TrafficTests, withRclone()

### Community 37 - "RcloneRemote"
Cohesion: 0.14
Nodes (10): FileActivity, .finishedAt, .id, .isUpload, Sequence<FileActivity>, .folder, .isCancellable, .name (+2 more)

### Community 38 - "ViewModelFactory"
Cohesion: 0.18
Nodes (8): ViewModelFactory, Build from source, Documentation, Documentation development, Features, Install, License, AppDependencies

### Community 39 - "ConnectionField"
Cohesion: 0.11
Nodes (19): ConnectionField, accessKey, bucket, confirmation, .displayName, encryptionPassword, endpoint, folder (+11 more)

### Community 41 - "DriveCondition"
Cohesion: 0.18
Nodes (3): FakeStorage, .uploadCount, UploadCleanupTests

### Community 42 - "ServiceAccountKey"
Cohesion: 0.22
Nodes (7): Drive, dump(), makeDrive(), rclone(), verifyRoundTrip(), GCSDriveTests, withOfflineDrive()

### Community 43 - "ConnectionDraft"
Cohesion: 0.18
Nodes (4): ConnectionDraft, .id, .isDuplicate, .body

### Community 44 - "CredentialStorage"
Cohesion: 0.11
Nodes (14): DriveCondition, checking, connected, disconnected, ejected, .indicator, needsAttention, needsReconnect (+6 more)

### Community 45 - "SFTPFixture"
Cohesion: 0.21
Nodes (9): SFTPFixture, .agentSocket, .connection, .credentials, .key, .protectedKey, .served, SFTPServer (+1 more)

### Community 46 - ".remove"
Cohesion: 0.13
Nodes (10): ConnectionBucketFields, .body, ConnectionEditorField, .body, ConnectionIdentityFields, .body, .providerPicker, S3ConnectionFields (+2 more)

### Community 48 - ".unmount"
Cohesion: 0.11
Nodes (3): AppPollingTests, MenuBarActivityTests, SpeedRecordingTests

### Community 49 - "ActivityViewModel"
Cohesion: 0.17
Nodes (6): ActivityViewModel, .refreshInterval, UploadCancellation, .message, .title, .body

### Community 54 - "View"
Cohesion: 0.22
Nodes (3): ServerTrustChallenge, .errorDescription, .server

### Community 55 - "S3StorageClass"
Cohesion: 0.20
Nodes (3): S3DriveTests, S3Server, withS3Drive()

### Community 56 - "SFTPTrustStore"
Cohesion: 0.14
Nodes (7): MainView, .sidebar, FocusedValues, SidebarSearchField, .body, TrafficCard, .body

### Community 57 - "SFTPSettings"
Cohesion: 0.33
Nodes (3): SFTPSettings, .agentSocketPath, .keyPath

### Community 58 - "withS3Drive"
Cohesion: 0.21
Nodes (5): MenuBarIcon, .accessibilityValue, .animatesUploads, .body, .image

### Community 61 - "GoogleSignInRequired"
Cohesion: 0.17
Nodes (10): SFTPAuthentication, agent, .id, password, privateKey, .title, Pane, connection (+2 more)

### Community 65 - ".control"
Cohesion: 0.15
Nodes (13): ARCHS, ASSETCATALOG_COMPILER_APPICON_NAME, CODE_SIGN_STYLE, CURRENT_PROJECT_VERSION, ENABLE_HARDENED_RUNTIME, ENABLE_USER_SCRIPT_SANDBOXING, INFOPLIST_FILE, MARKETING_VERSION (+5 more)

### Community 66 - ".serve"
Cohesion: 0.15
Nodes (8): UnfinishedUpload, Date, DayCell, .body, MonthGrid, .body, TrafficRangePicker, .body

### Community 67 - "base"
Cohesion: 0.12
Nodes (14): AWSSettings, S3StorageClass, glacierInstantRetrieval, .id, intelligentTiering, oneZoneInfrequentAccess, standard, standardInfrequentAccess (+6 more)

### Community 68 - "SFTPAuthentication"
Cohesion: 0.17
Nodes (10): Backend, gcs, .locksFolderAfterSave, s3Compatible, sftp, .supportsMultiThreadUploads, .supportsServerCopy, .supportsShareLinks (+2 more)

### Community 70 - "ValidationResult"
Cohesion: 0.21
Nodes (7): SFTPDriveTests, SFTPLogin, agent, key, password, protectedKey, withSFTPDrive()

### Community 71 - "GoogleSignInRun"
Cohesion: 0.16
Nodes (11): ActivityFileName, .body, ActivityTable, .body, ActivityView, .activity, .idle, FittedScrollView (+3 more)

### Community 73 - ".connect"
Cohesion: 0.18
Nodes (10): macOS, name, options, deploymentTarget, postGenCommand, packages, UnlocalFSCore, settings (+2 more)

### Community 74 - "ConnectionDraft"
Cohesion: 0.22
Nodes (7): ActivityStatus, .body, .movingText, .progress, FailedUploadButton, .body, .details

### Community 75 - ".refresh"
Cohesion: 0.33
Nodes (4): UnlocalFSApp, .body, MenuContent, .body

### Community 76 - "GCSConnectionFields"
Cohesion: 0.19
Nodes (7): GCSAuthentication, googleAccount, .id, serviceAccount, .title, GCSSettings, Config

### Community 77 - "fetchActivity"
Cohesion: 0.20
Nodes (3): GCSConnectionFields, .body, .serviceAccountField

### Community 78 - "project.yml"
Cohesion: 0.20
Nodes (9): interval, time, timezone, updates, directory, open-pull-requests-limit, package-ecosystem, schedule (+1 more)

### Community 80 - "updates"
Cohesion: 0.22
Nodes (6): ShareLinkExpiry, day, hour, .title, week, AppViewModel

### Community 82 - "UploadCleanup"
Cohesion: 0.24
Nodes (4): AppViewModel, UploadCleanup, .message, .title

### Community 83 - "TrafficViewModelTests"
Cohesion: 0.15
Nodes (9): State, downloaded, downloading, failed, queued, uploaded, uploading, ConnectionEditor (+1 more)

### Community 84 - "UnlocalFS"
Cohesion: 0.20
Nodes (10): Debug, Release, package, product, UnlocalFS, configFiles, dependencies, platform (+2 more)

### Community 85 - "SFTPConnectionFields"
Cohesion: 0.18
Nodes (9): .actions, .header, DriveManagementItems, .body, ConnectionRow, .body, .icon, StatusIndicator (+1 more)

### Community 86 - ".recordTraffic"
Cohesion: 0.29
Nodes (4): SFTPConnectionFields, .authenticationHelp, .authenticationSection, .body

### Community 88 - ".quitDisconnectsEveryDriveAtTheSameTime"
Cohesion: 0.28
Nodes (3): AppQuitTests, Overlap, .peak

### Community 89 - "ShareLinkExpiry"
Cohesion: 0.25
Nodes (8): config, targets, config, schemes, UnlocalFS, archive, build, run

### Community 90 - "TrafficView"
Cohesion: 0.12
Nodes (15): .detail, ProviderIcon, .body, ShareBar, .body, TrafficChart, TrafficList, .body (+7 more)

### Community 92 - "SpeedSample"
Cohesion: 0.29
Nodes (4): SpeedSample, .axisLimit, .fastestDownload, .fastestUpload

### Community 93 - "awsFixture"
Cohesion: 0.29
Nodes (6): ActivitySnapshot, checking, .files, idle, transfers, unavailable

### Community 94 - "ClosedRange<Date>"
Cohesion: 0.40
Nodes (4): ClosedRange<Date>, .formattedDays, DateInterval, .formattedDays

### Community 103 - "ControlServers"
Cohesion: 0.33
Nodes (6): copyFiles, destination, subpath, buildPhase, path, sources

### Community 104 - "MemoryCredentialStorage"
Cohesion: 0.33
Nodes (4): .signInAgainButton, .googleAccountField, GoogleSignInButton, .body

### Community 105 - "UploadTally"
Cohesion: 0.32
Nodes (3): OSLog, TrafficTracker, UploadTally

### Community 106 - "Decision"
Cohesion: 0.50
Nodes (4): RcloneState, running, stopped, untracked

### Community 107 - "waitUntil"
Cohesion: 0.40
Nodes (5): Indicator, attention, connected, idle, working

### Community 110 - "test"
Cohesion: 0.40
Nodes (5): basedOnDependencyAnalysis, name, script, shell, postBuildScripts

### Community 111 - "Indicator"
Cohesion: 0.50
Nodes (4): package, config, targets, test

## Knowledge Gaps
- **266 isolated node(s):** `PackageDescription`, `standard`, `intelligentTiering`, `standardInfrequentAccess`, `oneZoneInfrequentAccess` (+261 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 618 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **33 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Connection` connect `Connection` to `deploy`, `Testing`, `steps`, `AppViewModel`, `AppPaths`, `AppViewModel`, `ConnectionStore`, `TrafficViewModel`, `.gcs`, `steps`, `MacOSDesktopServices`, `AppDelegate`, `withControl`, `TrafficStore`, `ConnectionDetail`, `Direction`, `.execute`, `MountStatus`, `StubbedDrives`, `FixtureResources`, `ShareBar`, `RcloneRemote`, `State`, `DriveCondition`, `ServiceAccountKey`, `ConnectionDraft`, `SFTPFixture`, `Provider`, `ActivityViewModel`, `AppViewModel`, `.connect`, `SFTPSettings`, `AppError`, `.write`, `.serve`, `base`, `SFTPAuthentication`, `GoogleSignInRun`, `.refresh`, `GCSConnectionFields`, `CopyName`, `UploadCleanup`, `SFTPConnectionFields`, `.execute`, `.deleteFileToStopUpload`, `AppViewModel`, `RcloneRemote.swift`?**
  _High betweenness centrality (0.265) - this node is a cross-community bridge._
- **Are the 10 inferred relationships involving `Connection` (e.g. with `AWSSettings` and `GCSSettings`) actually correct?**
  _`Connection` has 10 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `standard`, `intelligentTiering` to the rest of the system?**
  _266 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Connection` be split into smaller, more focused modules?**
  _Cohesion score 0.05851063829787234 - nodes in this community are weakly interconnected._
- **Why does `UnlocalFSDomain` connect `.validate` to `Connection`, `Decodable`, `Connection`, `README.md`, `ShareBar`, `deploy`, `RcloneRemote.swift`, `Backend`, `.s3`, `UploadTally`, `ServiceAccountKey`, `TrafficPreset`, `RcloneRemote.swift`, `withControl`?**
  _High betweenness centrality (0.071) - this node is a cross-community bridge._
- **Are the 29 inferred relationships involving `Credentials` (e.g. with `ConnectionEditorViewModel` and `.credentialsSavedBeforeEncryptionHaveNoPassword()`) actually correct?**
  _`Credentials` has 29 INFERRED edges - model-reasoned connections that need verification._
- **Should `Decodable` be split into smaller, more focused modules?**
  _Cohesion score 0.08235294117647059 - nodes in this community are weakly interconnected._