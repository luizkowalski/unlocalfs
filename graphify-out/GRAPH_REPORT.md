# Graph Report - unlocalfs  (2026-11-16)

## Corpus Check
- 168 files · ~49,186 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 12 file(s) not represented in the graph (top: .xcstrings 5, (none) 3, .resolved 1)

## Summary
- 2144 nodes · 5301 edges · 117 communities (83 shown, 34 thin omitted)
- Extraction: 81% EXTRACTED · 19% INFERRED · 0% AMBIGUOUS · INFERRED: 998 edges (avg confidence: 0.85)
- Token cost: 289,731 input · 0 output

## Graph Freshness
- Built from commit: `c3009806`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Connection
- Decodable
- .s3
- GoogleToken
- .validate
- UnixConnection
- .onlyAGoogleDriveWithARevokedGrantAsksToSignInAgain
- .validate
- .s3
- steps
- MountStatus
- LocalizedError
- Credentials
- MountService
- TrafficPreset
- TrafficPreset
- AppViewModel
- ConnectionStore
- .sftp
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
- FixtureResources
- ViewModelFixture
- withRclone
- UnixConnection
- RcloneRemote
- ViewModelFactory
- ConnectionField
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
- withRclone
- ControlFailure
- GoogleToken
- ConnectionDraft
- .runBackendCommand
- SFTPTrustStore
- ServerTrustChallenge
- GoogleToken
- UploadCancellation
- AppError
- CaseIterable
- .refresh
- ServiceAccountKey
- .sample
- .remove
- .serve
- base
- Backend
- Backend
- GoogleSignInRun
- StatusIndicator
- SFTPLogin
- .connect
- ConnectionDraft
- failingStatus
- GCSConnectionFields
- TransferSummary
- project.yml
- .shareLink
- ShareLinkExpiry
- ValidationResult
- FileActionError
- State
- Traffic
- SFTPConnectionFields
- .run
- ViewModelFixture
- String
- ProviderIcon
- TrafficView
- GoogleDriveTests
- failingStatus
- .sftp
- FileActionError
- UploadCleanup
- awsFixture
- ServiceAccountKey
- README.md
- GoogleDriveTests
- UploadTally
- README.md
- GoogleSignInButton
- AppViewModel
- .quitDisconnectsEveryDriveAtTheSameTime
- ControlServers
- Darwin
- ActivityViewModel
- Command.swift
- .signInAgain
- ConnectionDraft
- RcloneRemote.swift
- Command.swift
- awsFixture
- RcloneRemote.swift

## God Nodes (most connected - your core abstractions)
1. `Connection` - 229 edges
2. `UnlocalFSDomain` - 109 edges
3. `Credentials` - 98 edges
4. `MountService` - 91 edges
5. `ViewModelFixture` - 83 edges
6. `DriveGateway` - 52 edges
7. `FileActivity` - 50 edges
8. `AppViewModel` - 49 edges
9. `ConnectionEditorViewModel` - 48 edges
10. `ConnectionField` - 46 edges

## Surprising Connections (you probably didn't know these)
- `Build from source` --references--> `ViewModelFactory`  [INFERRED]
  README.md → Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/ViewModelFactory.swift
- `.body` --references--> `Provider`  [INFERRED]
  UnlocalFS/Presentation/Provider+Logo.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `.body` --calls--> `Connection`  [INFERRED]
  UnlocalFS/Application/UnlocalFSApp.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `.selected` --references--> `Connection`  [INFERRED]
  Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/AppViewModel.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `ActivityView` --references--> `Connection`  [EXTRACTED]
  UnlocalFS/Presentation/Activity/ActivityView.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift

## Import Cycles
- None detected.

## Communities (117 total, 34 thin omitted)

### Community 0 - "Connection"
Cohesion: 0.05
Nodes (15): SaveConnectionUseCase, ConnectionStore, Keychain, CredentialStorage, SavedConnectionRepository, configURL(), ConnectionTests, KeychainTests (+7 more)

### Community 1 - "Decodable"
Cohesion: 0.06
Nodes (45): DriveAbout, User, UploadTally, BatchResult, CodingKeys, error, ControlSnapshot, CodingKeys (+37 more)

### Community 2 - ".s3"
Cohesion: 0.05
Nodes (12): Connection, .backend, .bucketPath, .exportsRcloneConfig, .folderPath, .usesGoogleSignIn, .usesUploadTimes, .driveStorage (+4 more)

### Community 3 - "GoogleToken"
Cohesion: 0.10
Nodes (4): GCSDriveTests, GoogleDriveValidationTests, AppSignInTests, GoogleSignInEditorTests

### Community 4 - ".validate"
Cohesion: 0.09
Nodes (5): Foundation, GRDB, Observation, Security, UnlocalFSDomain

### Community 5 - "UnixConnection"
Cohesion: 0.18
Nodes (5): ControlSocket, ControlUnreachable, RcloneError, UnixConnection, .timedOut

### Community 7 - ".validate"
Cohesion: 0.05
Nodes (42): runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, environment, if (+34 more)

### Community 8 - ".s3"
Cohesion: 0.10
Nodes (4): Synchronization, Testing, UnlocalFSInfrastructure, UnlocalFSTestSupport

### Community 9 - "steps"
Cohesion: 0.12
Nodes (14): ConnectionRepository, DeleteConnectionUseCase, SetAutomaticConnectUseCase, DriveGateway, ConnectDriveUseCase, Outcome, connected, ejected (+6 more)

### Community 10 - "MountStatus"
Cohesion: 0.06
Nodes (35): env, runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, DEVELOPER_DIR (+27 more)

### Community 11 - "LocalizedError"
Cohesion: 0.11
Nodes (10): AppKit, Charts, Network, SwiftUI, UniformTypeIdentifiers, ClosedRange<Date>, .formattedDays, DateInterval (+2 more)

### Community 13 - "MountService"
Cohesion: 0.11
Nodes (7): DriveTraffic, TrafficDay, TrafficRepository, TrafficStore, .migrator, .total, TrafficStoreTests

### Community 14 - "TrafficPreset"
Cohesion: 0.10
Nodes (12): ConnectionEditorViewModel, .connection, .credentials, .fieldErrors, .initialFocus, .isLocked, .locksRemoteFolder, .signingIn (+4 more)

### Community 15 - "TrafficPreset"
Cohesion: 0.08
Nodes (17): ClosedRange<Date>, DateInterval, TrafficPeriod, custom, last12Months, last30Days, last90Days, TrafficPreset (+9 more)

### Community 16 - "AppViewModel"
Cohesion: 0.12
Nodes (4): Notification, AppDelegate, .model, .viewModels

### Community 17 - "ConnectionStore"
Cohesion: 0.07
Nodes (29): env, runs-on, steps, timeout-minutes, APPLE_ID, DEVELOPER_DIR, GH_TOKEN, GOOGLE_CLIENT_ID (+21 more)

### Community 18 - ".sftp"
Cohesion: 0.16
Nodes (9): .unsaved, TrafficBar, .id, TrafficViewModel, .custom, .period, .recentTotal, .unit (+1 more)

### Community 19 - "ServerTrustChallenge"
Cohesion: 0.10
Nodes (7): Credentials, .encryptionPassword, .googleSignIn, .keyPassphrase, .password, ConnectionRulesTests, ConnectionEditorViewModelTests

### Community 21 - "TrafficViewModelTests"
Cohesion: 0.13
Nodes (9): AppPaths, .knownHosts, .sockets, .traffic, MountCommand, .arguments, .environment, .mountParameters (+1 more)

### Community 22 - "MacOSDesktopServices"
Cohesion: 0.17
Nodes (6): mark(), MountSafetyTests, shutdown(), withControl(), withFixture(), statusBatch()

### Community 23 - "Equatable"
Cohesion: 0.09
Nodes (15): ConnectionBucketFields, .body, ConnectionEditorField, .body, ConnectionIdentityFields, .body, .providerPicker, .serviceAccountField (+7 more)

### Community 24 - "withControl"
Cohesion: 0.12
Nodes (4): DesktopServices, RcloneConfigDestination, MacOSDesktopServices, .opensAtLogin

### Community 27 - "withRclone"
Cohesion: 0.14
Nodes (16): ConnectionDetail, .actions, .awsDetails, .body, .bucketDetail, .disconnected, .logo, .notices (+8 more)

### Community 28 - "Decision"
Cohesion: 0.09
Nodes (14): Backend, gcs, googleDrive, .locksFolderAfterSave, s3Compatible, sftp, .supportsMultiThreadUploads, .supportsServerCopy (+6 more)

### Community 29 - "ActivityView"
Cohesion: 0.20
Nodes (6): GoogleSignIn, controlCalls(), ServiceRecoveryTests, withRevokedDrive(), StubbedDrives, .rcloneCalls

### Community 30 - "LocalizedError"
Cohesion: 0.13
Nodes (10): Direction, .color, download, .fill, .label, .symbol, upload, SpeedChart (+2 more)

### Community 31 - "DeleteConnectionUseCase"
Cohesion: 0.10
Nodes (11): AppViewModel, .busy, .isConfirmingDelete, .isShowingAlert, .isShowingDisconnectFailure, .isShowingUploadsBlockingDisconnect, .selected, SidebarItem (+3 more)

### Community 32 - "StubbedDrives"
Cohesion: 0.28
Nodes (4): Traffic, .total, TrafficMeter, TrafficMeterTests

### Community 33 - "FixtureResources"
Cohesion: 0.19
Nodes (4): MountStatus, .isActive, .isServing, .needsReconnect

### Community 34 - "ViewModelFixture"
Cohesion: 0.09
Nodes (20): ConnectionField, accessKey, bucket, confirmation, .displayName, encryptionPassword, endpoint, folder (+12 more)

### Community 35 - "withRclone"
Cohesion: 0.09
Nodes (4): AppPollingTests, CancelUploadTests, MenuBarActivityTests, SpeedRecordingTests

### Community 36 - "UnixConnection"
Cohesion: 0.16
Nodes (3): ControlFailure, ControlRequest, ControlServer

### Community 37 - "RcloneRemote"
Cohesion: 0.16
Nodes (13): GoogleClient, NamedRemote, Options, RcloneRemote, .cryptOptions, .driveOptions, .environment, .gcsOptions (+5 more)

### Community 38 - "ViewModelFactory"
Cohesion: 0.17
Nodes (8): UnfinishedUpload, Date, DayCell, .body, MonthGrid, .body, TrafficRangePicker, .body

### Community 39 - "ConnectionField"
Cohesion: 0.12
Nodes (14): AWSSettings, S3StorageClass, glacierInstantRetrieval, .id, intelligentTiering, oneZoneInfrequentAccess, standard, standardInfrequentAccess (+6 more)

### Community 40 - "AppViewModel"
Cohesion: 0.25
Nodes (7): BatchReply, .current, counters(), finished(), reply(), TrafficTests, withRclone()

### Community 42 - "ServiceAccountKey"
Cohesion: 0.22
Nodes (4): RcloneProcess, TrafficCheckpoint, TrafficReading, TrafficSave

### Community 43 - "ValidationResult"
Cohesion: 0.19
Nodes (5): FixtureResources, Launch, requireOutput(), withFixture(), startAgent()

### Community 44 - "AppViewModel"
Cohesion: 0.05
Nodes (17): Activity, connected, downloading, idle, uploading, Indicator, attention, connected (+9 more)

### Community 45 - "SFTPFixture"
Cohesion: 0.11
Nodes (14): DriveCondition, checking, connected, disconnected, ejected, .indicator, needsAttention, needsReconnect (+6 more)

### Community 46 - ".remove"
Cohesion: 0.20
Nodes (7): Drive, .mounted, dump(), makeDrive(), rclone(), verifyRoundTrip(), withOfflineDrive()

### Community 47 - "ControlServer"
Cohesion: 0.18
Nodes (3): FakeStorage, .uploadCount, UploadCleanupTests

### Community 48 - "ActivityViewModel"
Cohesion: 0.22
Nodes (6): String, .isBlank, ValidationResult, .fieldErrors, Issue, .isValid

### Community 50 - "AppViewModel"
Cohesion: 0.13
Nodes (10): FileActivity, .finishedAt, .id, .isUpload, Sequence<FileActivity>, .folder, .isCancellable, .name (+2 more)

### Community 51 - "withRclone"
Cohesion: 0.12
Nodes (16): Provider, aws, .backend, cloudflare, digitalOcean, googleCloudStorage, googleDrive, .group (+8 more)

### Community 52 - "ControlFailure"
Cohesion: 0.20
Nodes (8): SFTPFixture, .agentSocket, .connection, .credentials, .key, .protectedKey, .served, SFTPServer

### Community 53 - "GoogleToken"
Cohesion: 0.16
Nodes (6): ActivityViewModel, .refreshInterval, SpeedSample, .axisLimit, .fastestDownload, .fastestUpload

### Community 54 - "ConnectionDraft"
Cohesion: 0.12
Nodes (10): DriveManagementItems, .body, ConnectionRow, .body, .sidebar, FocusedValues, SidebarSearchField, .body (+2 more)

### Community 57 - "ServerTrustChallenge"
Cohesion: 0.20
Nodes (3): S3DriveTests, S3Server, withS3Drive()

### Community 58 - "GoogleToken"
Cohesion: 0.15
Nodes (8): .isSignedInToGoogle, .secrets, GoogleAccountChanged, .errorDescription, GoogleSignInRequired, .errorDescription, GoogleToken, Fields

### Community 59 - "UploadCancellation"
Cohesion: 0.29
Nodes (4): UploadCancellation, .message, .title, .body

### Community 60 - "AppError"
Cohesion: 0.17
Nodes (5): Darwin, RcloneState, running, stopped, untracked

### Community 61 - "CaseIterable"
Cohesion: 0.12
Nodes (9): UnlocalFSApp, .body, MenuBarIcon, .accessibilityValue, .animatesUploads, .body, .image, MenuContent (+1 more)

### Community 62 - ".refresh"
Cohesion: 0.23
Nodes (3): ServerTrustChallenge, .errorDescription, .server

### Community 63 - "ServiceAccountKey"
Cohesion: 0.15
Nodes (9): SFTPAuthentication, agent, .id, password, privateKey, .title, SFTPSettings, .agentSocketPath (+1 more)

### Community 65 - ".remove"
Cohesion: 0.18
Nodes (8): ViewModelFactory, Build from source, Documentation, Documentation development, Features, Install, License, .body

### Community 66 - ".serve"
Cohesion: 0.15
Nodes (13): ARCHS, ASSETCATALOG_COMPILER_APPICON_NAME, CODE_SIGN_STYLE, CURRENT_PROJECT_VERSION, ENABLE_HARDENED_RUNTIME, ENABLE_USER_SCRIPT_SANDBOXING, INFOPLIST_FILE, MARKETING_VERSION (+5 more)

### Community 67 - "base"
Cohesion: 0.10
Nodes (17): .icon, MainView, .detail, ProviderIcon, .body, ShareBar, .body, TrafficChart (+9 more)

### Community 68 - "Backend"
Cohesion: 0.21
Nodes (7): SFTPDriveTests, SFTPLogin, agent, key, password, protectedKey, withSFTPDrive()

### Community 69 - "Backend"
Cohesion: 0.20
Nodes (7): ActivityFileName, .body, ActivityTable, .body, ActivityView, .activity, .idle

### Community 73 - ".connect"
Cohesion: 0.18
Nodes (10): macOS, name, options, deploymentTarget, postGenCommand, packages, UnlocalFSCore, settings (+2 more)

### Community 74 - "ConnectionDraft"
Cohesion: 0.22
Nodes (7): ActivityStatus, .body, .movingText, .progress, FailedUploadButton, .body, .details

### Community 76 - "GCSConnectionFields"
Cohesion: 0.20
Nodes (9): ProviderGroup, generic, google, s3Services, .providerSections, Pane, connection, .displayName (+1 more)

### Community 77 - "TransferSummary"
Cohesion: 0.27
Nodes (7): GCSAuthentication, googleAccount, .id, serviceAccount, .title, GCSSettings, Config

### Community 78 - "project.yml"
Cohesion: 0.20
Nodes (9): interval, time, timezone, updates, directory, open-pull-requests-limit, package-ecosystem, schedule (+1 more)

### Community 79 - ".shareLink"
Cohesion: 0.27
Nodes (3): .serviceAccountEmail, ServiceAccountKey, GCSValidationTests

### Community 81 - "ValidationResult"
Cohesion: 0.22
Nodes (6): ShareLinkExpiry, day, hour, .title, week, AppViewModel

### Community 83 - "State"
Cohesion: 0.20
Nodes (10): Debug, Release, package, product, UnlocalFS, configFiles, dependencies, platform (+2 more)

### Community 84 - "Traffic"
Cohesion: 0.27
Nodes (4): SFTPConnectionFields, .authenticationHelp, .authenticationSection, .body

### Community 87 - "ViewModelFixture"
Cohesion: 0.11
Nodes (10): AppQuitTests, AppSearchTests, FinderServicesTests, ViewModelFixture, .paths, .rcloneCalls, .root, .service (+2 more)

### Community 88 - "String"
Cohesion: 0.29
Nodes (7): State, downloaded, downloading, failed, queued, uploaded, uploading

### Community 89 - "ProviderIcon"
Cohesion: 0.29
Nodes (4): DriveEjectError, .errorDescription, UploadsPendingError, .errorDescription

### Community 90 - "TrafficView"
Cohesion: 0.25
Nodes (8): config, targets, config, schemes, UnlocalFS, archive, build, run

### Community 91 - "GoogleDriveTests"
Cohesion: 0.29
Nodes (3): ConnectionDraft, .id, .isDuplicate

### Community 92 - "failingStatus"
Cohesion: 0.29
Nodes (6): ActivitySnapshot, checking, .files, idle, transfers, unavailable

### Community 100 - "UploadTally"
Cohesion: 0.33
Nodes (6): copyFiles, destination, subpath, buildPhase, path, sources

### Community 101 - "README.md"
Cohesion: 0.40
Nodes (3): .header, StatusIndicator, .body

### Community 102 - "GoogleSignInButton"
Cohesion: 0.40
Nodes (3): OSLog, ServiceManagement, UserNotifications

### Community 103 - "AppViewModel"
Cohesion: 0.40
Nodes (4): Decision, disconnect, quit, wait

### Community 107 - "ActivityViewModel"
Cohesion: 0.40
Nodes (3): UploadCleanup, .message, .title

### Community 108 - "Command.swift"
Cohesion: 0.40
Nodes (5): basedOnDependencyAnalysis, name, script, shell, postBuildScripts

### Community 109 - ".signInAgain"
Cohesion: 0.40
Nodes (3): .signInAgainButton, GoogleSignInButton, .body

### Community 110 - "ConnectionDraft"
Cohesion: 0.50
Nodes (4): package, config, targets, test

## Knowledge Gaps
- **278 isolated node(s):** `PackageDescription`, `standard`, `intelligentTiering`, `standardInfrequentAccess`, `oneZoneInfrequentAccess` (+273 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 642 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **34 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Connection` connect `.s3` to `Connection`, `GoogleToken`, `.onlyAGoogleDriveWithARevokedGrantAsksToSignInAgain`, `steps`, `Credentials`, `MountService`, `TrafficPreset`, `.sftp`, `ServerTrustChallenge`, `.gcs`, `TrafficViewModelTests`, `MacOSDesktopServices`, `withControl`, `.s3`, `.refresh`, `withRclone`, `Decision`, `ActivityView`, `DeleteConnectionUseCase`, `FixtureResources`, `ViewModelFixture`, `RcloneRemote`, `ConnectionField`, `AppViewModel`, `.connect`, `ServiceAccountKey`, `AppViewModel`, `.remove`, `ControlServer`, `ActivityViewModel`, `ViewModelFactory`, `ControlFailure`, `ConnectionDraft`, `UploadCancellation`, `CaseIterable`, `ServiceAccountKey`, `Backend`, `TransferSummary`, `.run`, `GoogleDriveTests`, `UploadCleanup`, `awsFixture`, `README.md`, `ControlServers`, `Darwin`, `ActivityViewModel`, `.test`, `RcloneRemote.swift`?**
  _High betweenness centrality (0.295) - this node is a cross-community bridge._
- **Are the 10 inferred relationships involving `Connection` (e.g. with `AWSSettings` and `GCSSettings`) actually correct?**
  _`Connection` has 10 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `standard`, `intelligentTiering` to the rest of the system?**
  _278 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Connection` be split into smaller, more focused modules?**
  _Cohesion score 0.054215625644197074 - nodes in this community are weakly interconnected._
- **Why does `Foundation` connect `.validate` to `Decodable`, `.s3`, `steps`, `MountService`, `.gcs`, `TrafficViewModelTests`, `UnixConnection`, `ViewModelFactory`, `ConnectionField`, `AppViewModel`, `ServiceAccountKey`, `ActivityViewModel`, `AppViewModel`, `SFTPTrustStore`, `GoogleToken`, `AppError`, `.refresh`, `ServiceAccountKey`, `SFTPLogin`, `TransferSummary`, `.shareLink`, `ShareLinkExpiry`, `FileActionError`, `ProviderIcon`, `GoogleDriveTests`, `ServiceAccountKey`, `GoogleSignInButton`, `RcloneRemote.swift`, `Command.swift`, `RcloneRemote.swift`?**
  _High betweenness centrality (0.079) - this node is a cross-community bridge._
- **Are the 33 inferred relationships involving `Credentials` (e.g. with `.delete()` and `ConnectionEditorViewModel`) actually correct?**
  _`Credentials` has 33 INFERRED edges - model-reasoned connections that need verification._
- **Should `Decodable` be split into smaller, more focused modules?**
  _Cohesion score 0.06101190476190476 - nodes in this community are weakly interconnected._