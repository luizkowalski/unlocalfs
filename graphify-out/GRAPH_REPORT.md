# Graph Report - unlocalfs  (2026-11-17)

## Corpus Check
- 168 files · ~49,217 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 12 file(s) not represented in the graph (top: .xcstrings 5, (none) 3, .resolved 1)

## Summary
- 2147 nodes · 5305 edges · 113 communities (85 shown, 28 thin omitted)
- Extraction: 81% EXTRACTED · 19% INFERRED · 0% AMBIGUOUS · INFERRED: 994 edges (avg confidence: 0.85)
- Token cost: 289,731 input · 0 output

## Graph Freshness
- Built from commit: `0ba2bc9e`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Connection
- Decodable
- ValidationResult
- GoogleToken
- .remove
- UnixConnection
- .onlyAGoogleDriveWithARevokedGrantAsksToSignInAgain
- .validate
- .s3
- ConnectionRepository
- MountStatus
- LocalizedError
- SFTPTrustStore
- MountService
- TrafficPreset
- TrafficPreset
- AppViewModel
- ConnectionStore
- Credentials
- ServerTrustChallenge
- .gcs
- TrafficViewModelTests
- MacOSDesktopServices
- Equatable
- withControl
- .s3
- .refresh
- withRclone
- Decision
- ActivityView
- LocalizedError
- DeleteConnectionUseCase
- StubbedDrives
- ViewModelFixture
- DriveGateway
- UnixConnection
- RcloneRemote
- .validate
- MountService
- AppViewModel
- .connect
- ServiceAccountKey
- ValidationResult
- AppViewModel
- SFTPFixture
- .remove
- ControlServer
- ActivityViewModel
- ViewModelFactory
- AppViewModel
- .refresh
- ServiceAccountKey
- GoogleToken
- ConnectionDraft
- .runBackendCommand
- SFTPTrustStore
- ServerTrustChallenge
- Sendable
- UploadCancellation
- AppError
- StatusIndicator
- .refresh
- AppSearchTests
- .sample
- .remove
- .serve
- base
- Backend
- Backend
- FileActionError
- StatusIndicator
- SFTPLogin
- .connect
- ConnectionDraft
- failingStatus
- GCSConnectionFields
- TransferSummary
- ExportRcloneConfigUseCase
- .shareLink
- ShareLinkExpiry
- ValidationResult
- FileActionError
- State
- Traffic
- SFTPConnectionFields
- awsFixture
- ViewModelFixture
- String
- ProviderIcon
- TrafficView
- ControlServers
- failingStatus
- SFTPSettings
- FileActionError
- UploadCleanup
- Command.swift
- ServiceAccountKey
- GoogleDriveTests
- UploadTally
- GoogleSignInButton
- AppViewModel
- .quitDisconnectsEveryDriveAtTheSameTime
- ControlServers
- QuitUseCase
- .signInAgain
- GoogleAccountField
- .test
- ServerTrustChallenge
- Command.swift
- FileActionError
- RcloneRemote.swift

## God Nodes (most connected - your core abstractions)
1. `Connection` - 230 edges
2. `UnlocalFSDomain` - 109 edges
3. `Credentials` - 98 edges
4. `MountService` - 91 edges
5. `ViewModelFixture` - 84 edges
6. `DriveGateway` - 52 edges
7. `FileActivity` - 50 edges
8. `AppViewModel` - 49 edges
9. `ConnectionEditorViewModel` - 48 edges
10. `ConnectionField` - 46 edges

## Surprising Connections (you probably didn't know these)
- `Build from source` --references--> `ViewModelFactory`  [INFERRED]
  README.md → Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/ViewModelFactory.swift
- `.body` --calls--> `Connection`  [INFERRED]
  UnlocalFS/Application/UnlocalFSApp.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `.body` --references--> `Provider`  [INFERRED]
  UnlocalFS/Presentation/Provider+Logo.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `.selected` --references--> `Connection`  [INFERRED]
  Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/AppViewModel.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `ActivityView` --references--> `Connection`  [EXTRACTED]
  UnlocalFS/Presentation/Activity/ActivityView.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift

## Import Cycles
- None detected.

## Communities (113 total, 28 thin omitted)

### Community 0 - "Connection"
Cohesion: 0.05
Nodes (46): RcloneError, DriveAbout, User, UploadTally, BatchResult, CodingKeys, error, ControlSnapshot (+38 more)

### Community 1 - "Decodable"
Cohesion: 0.05
Nodes (13): AppViewModel, mark(), MountSafetyTests, shutdown(), withControl(), withFixture(), failingStatus(), revokedDrive() (+5 more)

### Community 2 - "ValidationResult"
Cohesion: 0.21
Nodes (6): String, .isBlank, ValidationResult, .fieldErrors, Issue, .isValid

### Community 3 - "GoogleToken"
Cohesion: 0.11
Nodes (4): AppViewModelTests, TrafficViewModelTests, .yesterday, TestDesktopServices

### Community 4 - ".remove"
Cohesion: 0.07
Nodes (5): AppPollingTests, CancelUploadTests, FinderServicesTests, MenuBarActivityTests, SpeedRecordingTests

### Community 5 - "UnixConnection"
Cohesion: 0.08
Nodes (5): Foundation, GRDB, Observation, Security, UnlocalFSDomain

### Community 6 - ".onlyAGoogleDriveWithARevokedGrantAsksToSignInAgain"
Cohesion: 0.05
Nodes (42): runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, environment, if (+34 more)

### Community 7 - ".validate"
Cohesion: 0.14
Nodes (4): Synchronization, Testing, UnlocalFSInfrastructure, UnlocalFSTestSupport

### Community 8 - ".s3"
Cohesion: 0.08
Nodes (11): ConnectionRulesTests, GoogleDriveValidationTests, AppSignInTests, GoogleSignInEditorTests, ViewModelFixture, .paths, .rcloneCalls, .root (+3 more)

### Community 9 - "ConnectionRepository"
Cohesion: 0.10
Nodes (9): ConnectionRepository, DeleteConnectionUseCase, SetAutomaticConnectUseCase, ConnectDriveUseCase, Outcome, connected, ejected, SignInAgainUseCase (+1 more)

### Community 10 - "MountStatus"
Cohesion: 0.28
Nodes (4): Traffic, .total, TrafficMeter, TrafficMeterTests

### Community 11 - "LocalizedError"
Cohesion: 0.06
Nodes (14): Connection, .backend, .bucketPath, .exportsRcloneConfig, .folderPath, .storageName, .usesGoogleSignIn, .usesUploadTimes (+6 more)

### Community 13 - "MountService"
Cohesion: 0.09
Nodes (19): State, downloaded, downloading, failed, queued, uploaded, uploading, UnfinishedUpload (+11 more)

### Community 14 - "TrafficPreset"
Cohesion: 0.06
Nodes (35): env, runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, DEVELOPER_DIR (+27 more)

### Community 15 - "TrafficPreset"
Cohesion: 0.14
Nodes (9): .unsaved, TrafficBar, .id, TrafficViewModel, .custom, .period, .recentTotal, .unit (+1 more)

### Community 16 - "AppViewModel"
Cohesion: 0.10
Nodes (12): AppKit, Charts, Network, ServiceManagement, SwiftUI, UniformTypeIdentifiers, ClosedRange<Date>, .formattedDays (+4 more)

### Community 17 - "ConnectionStore"
Cohesion: 0.11
Nodes (7): DriveTraffic, TrafficDay, TrafficRepository, TrafficStore, .migrator, .total, TrafficStoreTests

### Community 18 - "Credentials"
Cohesion: 0.07
Nodes (8): Credentials, .encryptionPassword, .googleSignIn, .keyPassphrase, .password, GCSDriveTests, withOfflineDrive(), ConnectionEditorViewModelTests

### Community 19 - "ServerTrustChallenge"
Cohesion: 0.20
Nodes (4): SaveConnectionUseCase, withWorkflowFixture(), WorkflowTests, sftpSettings()

### Community 20 - ".gcs"
Cohesion: 0.07
Nodes (20): SidebarItem, drive, traffic, ClosedRange<Date>, DateInterval, TrafficPeriod, custom, last12Months (+12 more)

### Community 21 - "TrafficViewModelTests"
Cohesion: 0.12
Nodes (4): Notification, AppDelegate, .model, .viewModels

### Community 22 - "MacOSDesktopServices"
Cohesion: 0.17
Nodes (12): ConnectionDetail, .awsDetails, .body, .bucketDetail, .disconnected, .logo, .notices, .sftpDetails (+4 more)

### Community 23 - "Equatable"
Cohesion: 0.07
Nodes (29): env, runs-on, steps, timeout-minutes, APPLE_ID, DEVELOPER_DIR, GH_TOKEN, GOOGLE_CLIENT_ID (+21 more)

### Community 24 - "withControl"
Cohesion: 0.07
Nodes (18): AppViewModel, Activity, connected, downloading, idle, uploading, .busy, Indicator (+10 more)

### Community 25 - ".s3"
Cohesion: 0.09
Nodes (20): ConnectionField, accessKey, bucket, confirmation, .displayName, encryptionPassword, endpoint, folder (+12 more)

### Community 26 - ".refresh"
Cohesion: 0.12
Nodes (4): DesktopServices, RcloneConfigDestination, MacOSDesktopServices, .opensAtLogin

### Community 27 - "withRclone"
Cohesion: 0.11
Nodes (10): AppPaths, .knownHosts, .sockets, .traffic, MountCommand, .arguments, .environment, .mountParameters (+2 more)

### Community 28 - "Decision"
Cohesion: 0.06
Nodes (19): UnlocalFSApp, .body, Direction, .color, download, .fill, .label, .symbol (+11 more)

### Community 29 - "ActivityView"
Cohesion: 0.15
Nodes (10): FileActivity, .finishedAt, .id, .isUpload, Sequence<FileActivity>, .folder, .isCancellable, .name (+2 more)

### Community 30 - "LocalizedError"
Cohesion: 0.10
Nodes (19): Provider, aws, .backend, cloudflare, digitalOcean, googleCloudStorage, googleDrive, .group (+11 more)

### Community 31 - "DeleteConnectionUseCase"
Cohesion: 0.11
Nodes (11): ConnectionEditorViewModel, .connection, .credentials, .initialFocus, .isLocked, .locksRemoteFolder, .signingIn, .title (+3 more)

### Community 32 - "StubbedDrives"
Cohesion: 0.11
Nodes (6): Keychain, CredentialStorage, KeychainTests, MemoryCredentialStorage, UnavailableCredentialStorage, LockableCredentialStorage

### Community 34 - "ViewModelFixture"
Cohesion: 0.15
Nodes (9): .isSignedInToGoogle, .secrets, GoogleAccountChanged, .errorDescription, GoogleSignIn, GoogleSignInRequired, .errorDescription, GoogleToken (+1 more)

### Community 35 - "DriveGateway"
Cohesion: 0.14
Nodes (3): DriveGateway, DuplicateFilesUseCase, ShareFilesUseCase

### Community 36 - "UnixConnection"
Cohesion: 0.21
Nodes (7): BatchReply, .current, counters(), finished(), reply(), TrafficTests, withRclone()

### Community 37 - "RcloneRemote"
Cohesion: 0.10
Nodes (11): ConnectionRow, .icon, MainView, .body, .detail, .sidebar, FocusedValues, SidebarSearchField (+3 more)

### Community 38 - ".validate"
Cohesion: 0.21
Nodes (3): .fieldErrors, ConnectionValidationTests, SFTPValidationTests

### Community 39 - "MountService"
Cohesion: 0.14
Nodes (5): Darwin, OSLog, MountService, .baseEnvironment, TrafficTracker

### Community 40 - "AppViewModel"
Cohesion: 0.15
Nodes (4): RcloneState, running, stopped, untracked

### Community 42 - "ServiceAccountKey"
Cohesion: 0.22
Nodes (5): Drive, dump(), rclone(), verifyRoundTrip(), waitUntil()

### Community 43 - "ValidationResult"
Cohesion: 0.16
Nodes (5): makeDrive(), FixtureResources, Launch, requireOutput(), withFixture()

### Community 44 - "AppViewModel"
Cohesion: 0.18
Nodes (3): FakeStorage, .uploadCount, UploadCleanupTests

### Community 45 - "SFTPFixture"
Cohesion: 0.15
Nodes (5): ConnectionStore, SavedConnectionRepository, configURL(), ConnectionTests, RepositoryTests

### Community 46 - ".remove"
Cohesion: 0.11
Nodes (14): DriveCondition, checking, connected, disconnected, ejected, .indicator, needsAttention, needsReconnect (+6 more)

### Community 47 - "ControlServer"
Cohesion: 0.19
Nodes (9): SFTPFixture, .agentSocket, .connection, .credentials, .key, .protectedKey, .served, SFTPServer (+1 more)

### Community 48 - "ActivityViewModel"
Cohesion: 0.17
Nodes (6): ActivityViewModel, .refreshInterval, UploadCancellation, .message, .title, .body

### Community 49 - "ViewModelFactory"
Cohesion: 0.20
Nodes (5): controlCalls(), ServiceRecoveryTests, withRevokedDrive(), StubbedDrives, .rcloneCalls

### Community 52 - "ServiceAccountKey"
Cohesion: 0.27
Nodes (3): .serviceAccountEmail, ServiceAccountKey, GCSValidationTests

### Community 53 - "GoogleToken"
Cohesion: 0.19
Nodes (12): NamedRemote, Options, RcloneRemote, .cryptOptions, .driveOptions, .environment, .gcsOptions, .namedRemotes (+4 more)

### Community 54 - "ConnectionDraft"
Cohesion: 0.14
Nodes (3): AppViewModel, AppViewModel, .visibleConnections

### Community 55 - ".runBackendCommand"
Cohesion: 0.20
Nodes (3): S3DriveTests, S3Server, withS3Drive()

### Community 56 - "SFTPTrustStore"
Cohesion: 0.14
Nodes (12): Backend, gcs, googleDrive, .locksFolderAfterSave, s3Compatible, sftp, .supportsMultiThreadUploads, .supportsServerCopy (+4 more)

### Community 58 - "Sendable"
Cohesion: 0.22
Nodes (4): RcloneProcess, TrafficCheckpoint, TrafficReading, TrafficSave

### Community 59 - "UploadCancellation"
Cohesion: 0.22
Nodes (6): GCSAuthentication, googleAccount, .id, serviceAccount, .title, GCSSettings

### Community 60 - "AppError"
Cohesion: 0.11
Nodes (16): AWSSettings, .customKMSKey, S3StorageClass, glacierInstantRetrieval, .id, intelligentTiering, oneZoneInfrequentAccess, standard (+8 more)

### Community 61 - "StatusIndicator"
Cohesion: 0.22
Nodes (7): .actions, .header, DriveManagementItems, .body, .body, StatusIndicator, .body

### Community 62 - ".refresh"
Cohesion: 0.15
Nodes (13): ARCHS, ASSETCATALOG_COMPILER_APPICON_NAME, CODE_SIGN_STYLE, CURRENT_PROJECT_VERSION, ENABLE_HARDENED_RUNTIME, ENABLE_USER_SCRIPT_SANDBOXING, INFOPLIST_FILE, MARKETING_VERSION (+5 more)

### Community 64 - ".sample"
Cohesion: 0.22
Nodes (4): MountStatus, .isActive, .isServing, .needsReconnect

### Community 66 - ".serve"
Cohesion: 0.22
Nodes (7): ViewModelFactory, Build from source, Documentation, Documentation development, Features, Install, License

### Community 68 - "Backend"
Cohesion: 0.22
Nodes (6): DriveEjectError, .errorDescription, UploadsPendingError, .errorDescription, ControlUnreachable, .timedOut

### Community 69 - "Backend"
Cohesion: 0.25
Nodes (3): ConnectionDraft, .id, .isDuplicate

### Community 73 - ".connect"
Cohesion: 0.18
Nodes (10): macOS, name, options, deploymentTarget, postGenCommand, packages, UnlocalFSCore, settings (+2 more)

### Community 74 - "ConnectionDraft"
Cohesion: 0.22
Nodes (7): ActivityStatus, .body, .movingText, .progress, FailedUploadButton, .body, .details

### Community 75 - "failingStatus"
Cohesion: 0.20
Nodes (3): GCSConnectionFields, .body, .serviceAccountField

### Community 76 - "GCSConnectionFields"
Cohesion: 0.12
Nodes (10): ConnectionBucketFields, .body, ConnectionEditorField, .body, ConnectionIdentityFields, .body, .providerPicker, S3ConnectionFields (+2 more)

### Community 77 - "TransferSummary"
Cohesion: 0.20
Nodes (9): interval, time, timezone, updates, directory, open-pull-requests-limit, package-ecosystem, schedule (+1 more)

### Community 79 - ".shareLink"
Cohesion: 0.22
Nodes (6): ShareLinkExpiry, day, hour, .title, week, AppViewModel

### Community 81 - "ValidationResult"
Cohesion: 0.24
Nodes (4): AppViewModel, UploadCleanup, .message, .title

### Community 82 - "FileActionError"
Cohesion: 0.20
Nodes (10): Debug, Release, package, product, UnlocalFS, configFiles, dependencies, platform (+2 more)

### Community 83 - "State"
Cohesion: 0.27
Nodes (4): SFTPConnectionFields, .authenticationHelp, .authenticationSection, .body

### Community 84 - "Traffic"
Cohesion: 0.26
Nodes (3): AppError, Command, CommandTests

### Community 88 - "String"
Cohesion: 0.28
Nodes (3): AppQuitTests, Overlap, .peak

### Community 89 - "ProviderIcon"
Cohesion: 0.20
Nodes (7): ActivityFileName, .body, ActivityTable, .body, ActivityView, .activity, .idle

### Community 90 - "TrafficView"
Cohesion: 0.15
Nodes (12): ShareBar, .body, TrafficChart, TrafficList, .body, TrafficStats, .body, TrafficView (+4 more)

### Community 92 - "failingStatus"
Cohesion: 0.25
Nodes (8): config, targets, config, schemes, UnlocalFS, archive, build, run

### Community 93 - "SFTPSettings"
Cohesion: 0.14
Nodes (9): SFTPAuthentication, agent, .id, password, privateKey, .title, SFTPSettings, .agentSocketPath (+1 more)

### Community 94 - "FileActionError"
Cohesion: 0.29
Nodes (6): ActivitySnapshot, checking, .files, idle, transfers, unavailable

### Community 95 - "UploadCleanup"
Cohesion: 0.21
Nodes (7): SFTPDriveTests, SFTPLogin, agent, key, password, protectedKey, withSFTPDrive()

### Community 99 - "GoogleDriveTests"
Cohesion: 0.18
Nodes (9): ProviderGroup, generic, google, s3Services, .providerSections, Pane, connection, .displayName (+1 more)

### Community 105 - "ControlServers"
Cohesion: 0.33
Nodes (6): copyFiles, destination, subpath, buildPhase, path, sources

### Community 107 - "QuitUseCase"
Cohesion: 0.20
Nodes (5): QuitUseCase, Decision, disconnect, quit, wait

### Community 109 - ".signInAgain"
Cohesion: 0.40
Nodes (5): basedOnDependencyAnalysis, name, script, shell, postBuildScripts

### Community 110 - "GoogleAccountField"
Cohesion: 0.15
Nodes (7): .signInAgainButton, GoogleAccountField, .body, GoogleDriveConnectionFields, .body, GoogleSignInButton, .body

### Community 111 - ".test"
Cohesion: 0.50
Nodes (4): package, config, targets, test

### Community 112 - "ServerTrustChallenge"
Cohesion: 0.16
Nodes (5): ServerTrustChallenge, .errorDescription, .server, ServerTrustSheet, .body

## Knowledge Gaps
- **280 isolated node(s):** `PackageDescription`, `standard`, `intelligentTiering`, `standardInfrequentAccess`, `oneZoneInfrequentAccess` (+275 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 644 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **28 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Connection` connect `LocalizedError` to `Connection`, `Decodable`, `ValidationResult`, `GoogleToken`, `UnixConnection`, `.s3`, `ConnectionRepository`, `TrafficPreset`, `ConnectionStore`, `Credentials`, `ServerTrustChallenge`, `MacOSDesktopServices`, `withControl`, `.s3`, `.refresh`, `withRclone`, `Decision`, `DeleteConnectionUseCase`, `FixtureResources`, `DriveGateway`, `UnixConnection`, `RcloneRemote`, `.validate`, `AppViewModel`, `.connect`, `ServiceAccountKey`, `ValidationResult`, `AppViewModel`, `SFTPFixture`, `ControlServer`, `ActivityViewModel`, `ViewModelFactory`, `AppViewModel`, `.refresh`, `GoogleToken`, `ConnectionDraft`, `SFTPTrustStore`, `Sendable`, `UploadCancellation`, `AppError`, `StatusIndicator`, `Backend`, `ExportRcloneConfigUseCase`, `ValidationResult`, `Traffic`, `SFTPConnectionFields`, `awsFixture`, `ViewModelFixture`, `ProviderIcon`, `ControlServers`, `SFTPSettings`, `GoogleDriveTests`, `UploadTally`, `QuitUseCase`?**
  _High betweenness centrality (0.315) - this node is a cross-community bridge._
- **Are the 10 inferred relationships involving `Connection` (e.g. with `AWSSettings` and `GCSSettings`) actually correct?**
  _`Connection` has 10 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `standard`, `intelligentTiering` to the rest of the system?**
  _280 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Connection` be split into smaller, more focused modules?**
  _Cohesion score 0.05432595573440644 - nodes in this community are weakly interconnected._
- **Why does `Foundation` connect `UnixConnection` to `Connection`, `Decodable`, `ValidationResult`, `.validate`, `ConnectionRepository`, `MountService`, `ConnectionStore`, `.gcs`, `withRclone`, `ActivityView`, `ViewModelFixture`, `DriveGateway`, `MountService`, `AppViewModel`, `ServiceAccountKey`, `ServerTrustChallenge`, `Sendable`, `UploadCancellation`, `AppError`, `Backend`, `Backend`, `FileActionError`, `SFTPLogin`, `ExportRcloneConfigUseCase`, `SFTPSettings`, `Command.swift`, `GoogleDriveTests`, `GoogleSignInButton`, `ServerTrustChallenge`, `FileActionError`?**
  _High betweenness centrality (0.092) - this node is a cross-community bridge._
- **Are the 33 inferred relationships involving `Credentials` (e.g. with `.delete()` and `ConnectionEditorViewModel`) actually correct?**
  _`Credentials` has 33 INFERRED edges - model-reasoned connections that need verification._
- **Should `Decodable` be split into smaller, more focused modules?**
  _Cohesion score 0.05441400304414003 - nodes in this community are weakly interconnected._