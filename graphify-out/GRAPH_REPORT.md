# Graph Report - unlocalfs  (2026-11-16)

## Corpus Check
- 169 files · ~49,093 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 12 file(s) not represented in the graph (top: .xcstrings 5, (none) 3, .resolved 1)

## Summary
- 2183 nodes · 5282 edges · 146 communities (84 shown, 62 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 954 edges (avg confidence: 0.85)
- Token cost: 289,731 input · 0 output

## Graph Freshness
- Built from commit: `423908bb`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- withControl
- Decodable
- GoogleToken
- .validate
- MountService
- Sendable
- TrafficViewModel
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
- SFTPTrustStore
- .gcs
- TrafficViewModelTests
- MacOSDesktopServices
- Equatable
- withControl
- .s3
- ConnectionDetail
- withRclone
- .execute
- ActivityView
- LocalizedError
- DeleteConnectionUseCase
- StubbedDrives
- FixtureResources
- ViewModelFixture
- withRclone
- .status
- RcloneRemote
- ViewModelFactory
- ConnectionField
- SFTPLogin
- .connect
- ServiceAccountKey
- .validate
- .init
- SFTPFixture
- .remove
- ActivityViewModel
- ConnectionStore
- AppViewModel
- AppSearchTests
- ControlFailure
- ConnectionIdentityFields
- ConnectionDraft
- Connection
- SFTPTrustStore
- ServerTrustChallenge
- withS3Drive
- S3StorageClass
- S3StorageClass
- MenuBarIcon
- ControlFailure
- .sample
- .remove
- .serve
- base
- Date
- Backend
- GoogleSignInRun
- StatusIndicator
- SFTPLogin
- .connect
- ConnectionDraft
- .refresh
- GCSConnectionFields
- RcloneRemote
- project.yml
- .shareLink
- updates
- UnixConnection
- SFTPAuthentication
- SFTPSettings
- Traffic
- SFTPConnectionFields
- .run
- SidebarItem
- ServerTrustChallenge
- ProviderIcon
- TrafficView
- DriveGateway
- GCSAuthentication
- DriveAboutProtocol
- GoogleSignInButton
- SpeedSample
- MemoryCredentialStorage
- README.md
- GoogleDriveTests
- .post
- README.md
- GoogleClient
- AppViewModel
- QuitUseCase
- UploadCleanup
- RcloneState
- MountService
- .deleteFileToStopUpload
- .signInAgain
- ConnectionDraft
- .reading
- PackageDescription
- FileActionError
- LockableCredentialStorage
- StubbedDrives
- Activity
- Indicator
- Command.swift
- RcloneRemote.swift
- MountCommand
- ByteCountFormatStyle+Size.swift

## God Nodes (most connected - your core abstractions)
1. `Connection` - 141 edges
2. `UnlocalFSDomain` - 109 edges
3. `Credentials` - 97 edges
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
- `.body` --calls--> `Connection`  [INFERRED]
  UnlocalFS/Application/UnlocalFSApp.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `.selected` --references--> `Connection`  [INFERRED]
  Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/AppViewModel.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `ActivityView` --references--> `Connection`  [EXTRACTED]
  UnlocalFS/Presentation/Activity/ActivityView.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `DriveManagementItems` --references--> `Connection`  [EXTRACTED]
  UnlocalFS/Presentation/Connections/DriveManagementItems.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift

## Import Cycles
- None detected.

## Communities (146 total, 62 thin omitted)

### Community 0 - "withControl"
Cohesion: 0.16
Nodes (5): mark(), MountSafetyTests, shutdown(), withControl(), withFixture()

### Community 1 - "Decodable"
Cohesion: 0.07
Nodes (41): DriveAbout, User, TrafficTracker, UploadTally, BatchResult, CodingKeys, bytes, completedAt (+33 more)

### Community 3 - "GoogleToken"
Cohesion: 0.16
Nodes (9): .isSignedInToGoogle, .secrets, GoogleAccountChanged, .errorDescription, GoogleSignIn, GoogleSignInRequired, .errorDescription, GoogleToken (+1 more)

### Community 4 - ".validate"
Cohesion: 0.08
Nodes (5): Foundation, GRDB, Observation, Security, UnlocalFSDomain

### Community 5 - "MountService"
Cohesion: 0.05
Nodes (42): runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, environment, if (+34 more)

### Community 6 - "Sendable"
Cohesion: 0.10
Nodes (9): AppSignInTests, FinderServicesTests, ViewModelFixture, .paths, .rcloneCalls, .root, .service, .signInEnvironment (+1 more)

### Community 7 - "TrafficViewModel"
Cohesion: 0.11
Nodes (15): .unsaved, TrafficBar, .id, TrafficViewModel, .custom, .period, .recentTotal, .unit (+7 more)

### Community 8 - ".s3"
Cohesion: 0.10
Nodes (12): AppKit, Charts, Network, ServiceManagement, SwiftUI, UniformTypeIdentifiers, ClosedRange<Date>, .formattedDays (+4 more)

### Community 9 - "steps"
Cohesion: 0.06
Nodes (35): env, runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, DEVELOPER_DIR (+27 more)

### Community 10 - "MountStatus"
Cohesion: 0.19
Nodes (4): MountStatus, .isActive, .isServing, .needsReconnect

### Community 11 - "LocalizedError"
Cohesion: 0.16
Nodes (4): Synchronization, Testing, UnlocalFSInfrastructure, UnlocalFSTestSupport

### Community 12 - "Credentials"
Cohesion: 0.10
Nodes (12): ConnectionRepository, SetAutomaticConnectUseCase, ConnectDriveUseCase, Outcome, connected, ejected, SignInAgainUseCase, DuplicateFilesUseCase (+4 more)

### Community 13 - "MountService"
Cohesion: 0.17
Nodes (6): AppPaths, .knownHosts, .sockets, .traffic, .arguments, .mountParameters

### Community 14 - "TrafficPreset"
Cohesion: 0.12
Nodes (15): Backend, .rcloneType, Connection, .driveStorage, .driveTarget, .rclonePath, .rcloneType, .storageRemoteName (+7 more)

### Community 15 - "TrafficPreset"
Cohesion: 0.09
Nodes (17): ClosedRange<Date>, DateInterval, TrafficPeriod, custom, last12Months, last30Days, last90Days, TrafficPreset (+9 more)

### Community 16 - "AppViewModel"
Cohesion: 0.19
Nodes (3): SaveConnectionUseCase, withWorkflowFixture(), WorkflowTests

### Community 17 - "ConnectionStore"
Cohesion: 0.07
Nodes (29): env, runs-on, steps, timeout-minutes, APPLE_ID, DEVELOPER_DIR, GH_TOKEN, GOOGLE_CLIENT_ID (+21 more)

### Community 18 - ".sftp"
Cohesion: 0.10
Nodes (8): AppViewModel, .busy, .isConfirmingDelete, .isShowingAlert, .isShowingDisconnectFailure, .isShowingUploadsBlockingDisconnect, .selected, .unsavedTraffic

### Community 20 - ".gcs"
Cohesion: 0.14
Nodes (4): DesktopServices, RcloneConfigDestination, MacOSDesktopServices, .opensAtLogin

### Community 21 - "TrafficViewModelTests"
Cohesion: 0.16
Nodes (3): SpeedRecordingTests, TrafficViewModelTests, .yesterday

### Community 22 - "MacOSDesktopServices"
Cohesion: 0.09
Nodes (7): Credentials, .encryptionPassword, .googleSignIn, .keyPassphrase, .password, ConnectionEditorViewModelTests, GoogleSignInEditorTests

### Community 23 - "Equatable"
Cohesion: 0.19
Nodes (4): RcloneProcess, TrafficCheckpoint, TrafficReading, TrafficSave

### Community 24 - "withControl"
Cohesion: 0.13
Nodes (5): CredentialStorage, SavedConnectionRepository, MemoryCredentialStorage, RepositoryTests, UnavailableCredentialStorage

### Community 26 - "ConnectionDetail"
Cohesion: 0.12
Nodes (4): Notification, AppDelegate, .model, .viewModels

### Community 27 - "withRclone"
Cohesion: 0.25
Nodes (7): BatchReply, .current, counters(), finished(), reply(), TrafficTests, withRclone()

### Community 28 - ".execute"
Cohesion: 0.11
Nodes (14): DriveCondition, checking, connected, disconnected, ejected, .indicator, needsAttention, needsReconnect (+6 more)

### Community 29 - "ActivityView"
Cohesion: 0.15
Nodes (10): ActivityFileName, .body, ActivityTable, .body, ActivityView, .activity, .idle, .body (+2 more)

### Community 30 - "LocalizedError"
Cohesion: 0.22
Nodes (6): DriveEjectError, .errorDescription, UploadsPendingError, .errorDescription, ControlUnreachable, .timedOut

### Community 32 - "StubbedDrives"
Cohesion: 0.15
Nodes (15): ConnectionDetail, .actions, .awsDetails, .bucketDetail, .disconnected, .logo, .notices, .sftpDetails (+7 more)

### Community 33 - "FixtureResources"
Cohesion: 0.06
Nodes (19): UnlocalFSApp, .body, Direction, .color, download, .fill, .label, .symbol (+11 more)

### Community 34 - "ViewModelFixture"
Cohesion: 0.11
Nodes (7): DriveTraffic, TrafficDay, TrafficRepository, TrafficStore, .migrator, .total, TrafficStoreTests

### Community 35 - "withRclone"
Cohesion: 0.07
Nodes (25): ConnectionField, accessKey, bucket, confirmation, .displayName, encryptionPassword, endpoint, folder (+17 more)

### Community 36 - ".status"
Cohesion: 0.19
Nodes (4): RcloneState, running, stopped, untracked

### Community 37 - "RcloneRemote"
Cohesion: 0.16
Nodes (5): controlCalls(), ServiceRecoveryTests, withRevokedDrive(), StubbedDrives, .rcloneCalls

### Community 38 - "ViewModelFactory"
Cohesion: 0.10
Nodes (14): ConnectionEditorViewModel, .availableProviders, .connection, .credentials, .fieldErrors, .firstInvalidField, .initialFocus, .isLocked (+6 more)

### Community 39 - "ConnectionField"
Cohesion: 0.17
Nodes (5): AppError, FixtureResources, Launch, requireOutput(), withFixture()

### Community 40 - "SFTPLogin"
Cohesion: 0.21
Nodes (7): SFTPDriveTests, SFTPLogin, agent, key, password, protectedKey, withSFTPDrive()

### Community 42 - "ServiceAccountKey"
Cohesion: 0.10
Nodes (19): Provider, aws, .backend, cloudflare, digitalOcean, googleCloudStorage, googleDrive, .group (+11 more)

### Community 43 - ".validate"
Cohesion: 0.06
Nodes (16): .serviceAccountEmail, ServiceAccountKey, Issue, String, .isBlank, ValidationResult, .fieldErrors, .isValid (+8 more)

### Community 46 - ".remove"
Cohesion: 0.18
Nodes (3): FakeStorage, .uploadCount, UploadCleanupTests

### Community 48 - "ActivityViewModel"
Cohesion: 0.14
Nodes (7): ActivityViewModel, .refreshInterval, UploadCancellation, .message, .title, ActivityViewModelTests, .body

### Community 49 - "ConnectionStore"
Cohesion: 0.24
Nodes (3): ConnectionStore, configURL(), ConnectionTests

### Community 50 - "AppViewModel"
Cohesion: 0.13
Nodes (9): Drive, .knownHosts, .mounted, dump(), makeDrive(), rclone(), verifyRoundTrip(), withOfflineDrive() (+1 more)

### Community 51 - "AppSearchTests"
Cohesion: 0.23
Nodes (8): SFTPFixture, .agentSocket, .credentials, .key, .protectedKey, .served, SFTPServer, startAgent()

### Community 53 - "ConnectionIdentityFields"
Cohesion: 0.29
Nodes (4): ConnectionIdentityFields, .body, .providerPicker, .serverSection

### Community 54 - "ConnectionDraft"
Cohesion: 0.09
Nodes (12): ConnectionRow, .body, .icon, MainView, .body, .detail, .sidebar, FocusedValues (+4 more)

### Community 55 - "Connection"
Cohesion: 0.12
Nodes (7): Connection, .backend, .bucketPath, .exportsRcloneConfig, .folderPath, .usesGoogleSignIn, .usesUploadTimes

### Community 56 - "SFTPTrustStore"
Cohesion: 0.13
Nodes (11): FileActivity, .finishedAt, .id, .isUpload, .folder, .isCancellable, .name, .hasFailed (+3 more)

### Community 58 - "withS3Drive"
Cohesion: 0.22
Nodes (3): S3DriveTests, S3Server, withS3Drive()

### Community 60 - "S3StorageClass"
Cohesion: 0.20
Nodes (6): AWSSettings, ServerSideEncryption, .id, kms, s3Managed, .title

### Community 61 - "S3StorageClass"
Cohesion: 0.15
Nodes (12): S3StorageClass, glacierInstantRetrieval, .id, intelligentTiering, oneZoneInfrequentAccess, standard, standardInfrequentAccess, .title (+4 more)

### Community 63 - "ControlFailure"
Cohesion: 0.20
Nodes (3): failingStatus(), revokedDrive(), ControlFailure

### Community 65 - ".remove"
Cohesion: 0.11
Nodes (3): AppSearchTests, MenuBarActivityTests, ControlServers

### Community 67 - "base"
Cohesion: 0.15
Nodes (13): ARCHS, ASSETCATALOG_COMPILER_APPICON_NAME, CODE_SIGN_STYLE, CURRENT_PROJECT_VERSION, ENABLE_HARDENED_RUNTIME, ENABLE_USER_SCRIPT_SANDBOXING, INFOPLIST_FILE, MARKETING_VERSION (+5 more)

### Community 68 - "Date"
Cohesion: 0.09
Nodes (19): State, downloaded, downloading, failed, queued, uploaded, uploading, UnfinishedUpload (+11 more)

### Community 69 - "Backend"
Cohesion: 0.15
Nodes (11): Backend, gcs, googleDrive, .locksFolderAfterSave, s3Compatible, sftp, .supportsMultiThreadUploads, .supportsServerCopy (+3 more)

### Community 71 - "StatusIndicator"
Cohesion: 0.40
Nodes (3): .header, StatusIndicator, .body

### Community 72 - "SFTPLogin"
Cohesion: 0.12
Nodes (10): .signInAgainButton, GCSConnectionFields, .body, .serviceAccountField, GoogleAccountField, .body, GoogleDriveConnectionFields, .body (+2 more)

### Community 74 - "ConnectionDraft"
Cohesion: 0.18
Nodes (5): AppPollingTests, AppQuitTests, Overlap, .peak, statusBatch()

### Community 75 - ".refresh"
Cohesion: 0.18
Nodes (10): macOS, name, options, deploymentTarget, postGenCommand, packages, UnlocalFSCore, settings (+2 more)

### Community 76 - "GCSConnectionFields"
Cohesion: 0.22
Nodes (7): ActivityStatus, .body, .movingText, .progress, FailedUploadButton, .body, .details

### Community 77 - "RcloneRemote"
Cohesion: 0.31
Nodes (8): RcloneRemote, .cryptOptions, .driveOptions, .environment, .gcsOptions, .options, .s3Options, .sftpOptions

### Community 78 - "project.yml"
Cohesion: 0.20
Nodes (9): interval, time, timezone, updates, directory, open-pull-requests-limit, package-ecosystem, schedule (+1 more)

### Community 79 - ".shareLink"
Cohesion: 0.22
Nodes (6): ShareLinkExpiry, day, hour, .title, week, AppViewModel

### Community 82 - "SFTPAuthentication"
Cohesion: 0.18
Nodes (7): SFTPAuthentication, agent, .id, password, privateKey, .title, SFTPSettings

### Community 83 - "SFTPSettings"
Cohesion: 0.20
Nodes (10): Debug, Release, package, product, UnlocalFS, configFiles, dependencies, platform (+2 more)

### Community 84 - "Traffic"
Cohesion: 0.32
Nodes (4): Traffic, .total, TrafficMeter, TrafficMeterTests

### Community 85 - "SFTPConnectionFields"
Cohesion: 0.29
Nodes (4): SFTPConnectionFields, .authenticationHelp, .authenticationSection, .body

### Community 87 - "SidebarItem"
Cohesion: 0.40
Nodes (3): SidebarItem, drive, traffic

### Community 88 - "ServerTrustChallenge"
Cohesion: 0.20
Nodes (3): ServerTrustChallenge, .errorDescription, .server

### Community 89 - "ProviderIcon"
Cohesion: 0.14
Nodes (10): Provider, .logo, ProviderIcon, .body, ShareBar, .body, TrafficList, .body (+2 more)

### Community 90 - "TrafficView"
Cohesion: 0.25
Nodes (8): config, targets, config, schemes, UnlocalFS, archive, build, run

### Community 92 - "GCSAuthentication"
Cohesion: 0.27
Nodes (7): GCSAuthentication, googleAccount, .id, serviceAccount, .title, GCSSettings, Config

### Community 95 - "GoogleSignInButton"
Cohesion: 0.29
Nodes (6): ActivitySnapshot, checking, .files, idle, transfers, unavailable

### Community 98 - "README.md"
Cohesion: 0.33
Nodes (6): copyFiles, destination, subpath, buildPhase, path, sources

### Community 101 - "README.md"
Cohesion: 0.29
Nodes (6): Build from source, Documentation, Documentation development, Features, Install, License

### Community 104 - "QuitUseCase"
Cohesion: 0.25
Nodes (5): QuitUseCase, Decision, disconnect, quit, wait

### Community 105 - "UploadCleanup"
Cohesion: 0.24
Nodes (4): AppViewModel, UploadCleanup, .message, .title

### Community 106 - "RcloneState"
Cohesion: 0.40
Nodes (5): basedOnDependencyAnalysis, name, script, shell, postBuildScripts

### Community 107 - "MountService"
Cohesion: 0.13
Nodes (4): Darwin, OSLog, MountService, .baseEnvironment

### Community 108 - ".deleteFileToStopUpload"
Cohesion: 0.50
Nodes (4): package, config, targets, test

### Community 110 - "ConnectionDraft"
Cohesion: 0.15
Nodes (4): ConnectionDraft, .id, .isDuplicate, ConnectionRulesTests

### Community 129 - "Activity"
Cohesion: 0.40
Nodes (5): Activity, connected, downloading, idle, uploading

### Community 130 - "Indicator"
Cohesion: 0.40
Nodes (5): Indicator, attention, connected, idle, working

## Knowledge Gaps
- **278 isolated node(s):** `.backend`, `.usesUploadTimes`, `.usesGoogleSignIn`, `.exportsRcloneConfig`, `.bucketPath` (+273 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 662 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **62 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Connection` connect `Connection` to `String`, `Decodable`, `MountService`, `.shareLink`, `TrafficViewModel`, `MountStatus`, `Credentials`, `MountService`, `AppViewModel`, `.sftp`, `.gcs`, `TrafficViewModelTests`, `MacOSDesktopServices`, `Equatable`, `withControl`, `.s3`, `withRclone`, `ActivityView`, `DeleteConnectionUseCase`, `StubbedDrives`, `FixtureResources`, `ViewModelFixture`, `.status`, `ViewModelFactory`, `.connect`, `ServiceAccountKey`, `.validate`, `SFTPFixture`, `.remove`, `ActivityViewModel`, `ConnectionStore`, `AppViewModel`, `AppSearchTests`, `SFTPTrustStore`, `ServerTrustChallenge`, `S3StorageClass`, `GCSAuthentication`, `.control`, `AppViewModel`, `UploadCleanup`, `ConnectionDraft`?**
  _High betweenness centrality (0.130) - this node is a cross-community bridge._
- **Are the 8 inferred relationships involving `Connection` (e.g. with `AWSSettings` and `GCSSettings`) actually correct?**
  _`Connection` has 8 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.backend`, `.usesUploadTimes`, `.usesGoogleSignIn` to the rest of the system?**
  _278 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Decodable` be split into smaller, more focused modules?**
  _Cohesion score 0.06779661016949153 - nodes in this community are weakly interconnected._
- **Why does `Credentials` connect `MacOSDesktopServices` to `String`, `withControl`, `MountService`, `GoogleToken`, `Sendable`, `.shareLink`, `AppViewModel`, `TrafficViewModelTests`, `Equatable`, `withControl`, `.s3`, `DeleteConnectionUseCase`, `RcloneRemote`, `ViewModelFactory`, `ServiceAccountKey`, `.validate`, `ConnectionStore`, `AppViewModel`, `AppSearchTests`, `Connection`, `withS3Drive`, `MenuBarIcon`, `.remove`, `RcloneRemote`, `DriveGateway`, `GCSAuthentication`, `MemoryCredentialStorage`, `GoogleDriveTests`, `ConnectionDraft`, `LockableCredentialStorage`, `StubbedDrives`?**
  _High betweenness centrality (0.082) - this node is a cross-community bridge._
- **Are the 32 inferred relationships involving `Credentials` (e.g. with `ConnectionEditorViewModel` and `.credentialsSavedBeforeEncryptionHaveNoPassword()`) actually correct?**
  _`Credentials` has 32 INFERRED edges - model-reasoned connections that need verification._
- **Should `MountService` be split into smaller, more focused modules?**
  _Cohesion score 0.1471861471861472 - nodes in this community are weakly interconnected._