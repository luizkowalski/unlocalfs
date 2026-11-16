# Graph Report - unlocalfs  (2026-11-16)

## Corpus Check
- 168 files · ~49,217 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 12 file(s) not represented in the graph (top: .xcstrings 5, (none) 3, .resolved 1)

## Summary
- 2150 nodes · 5308 edges · 122 communities (89 shown, 33 thin omitted)
- Extraction: 81% EXTRACTED · 19% INFERRED · 0% AMBIGUOUS · INFERRED: 997 edges (avg confidence: 0.85)
- Token cost: 289,731 input · 0 output

## Graph Freshness
- Built from commit: `fbba0bf5`
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
- .test
- RcloneRemote.swift
- Command.swift
- FileActionError
- awsFixture
- RcloneRemote.swift
- test
- Command.swift
- ByteCountFormatStyle+Size.swift
- PackageDescription

## God Nodes (most connected - your core abstractions)
1. `Connection` - 230 edges
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

## Communities (122 total, 33 thin omitted)

### Community 0 - "Connection"
Cohesion: 0.06
Nodes (45): DriveAbout, User, UploadTally, BatchResult, CodingKeys, error, ControlSnapshot, CodingKeys (+37 more)

### Community 1 - "Decodable"
Cohesion: 0.05
Nodes (13): Connection, .backend, .bucketPath, .exportsRcloneConfig, .folderPath, .storageName, .usesGoogleSignIn, .usesUploadTimes (+5 more)

### Community 2 - ".s3"
Cohesion: 0.08
Nodes (8): Darwin, Foundation, GRDB, Observation, String, .expandingTilde, Security, UnlocalFSDomain

### Community 3 - "GoogleToken"
Cohesion: 0.05
Nodes (42): runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, environment, if (+34 more)

### Community 4 - ".validate"
Cohesion: 0.10
Nodes (4): Synchronization, Testing, UnlocalFSInfrastructure, UnlocalFSTestSupport

### Community 5 - "UnixConnection"
Cohesion: 0.10
Nodes (11): ConnectionRepository, DeleteConnectionUseCase, SetAutomaticConnectUseCase, DriveGateway, ConnectDriveUseCase, QuitUseCase, SignInAgainUseCase, DuplicateFilesUseCase (+3 more)

### Community 7 - ".validate"
Cohesion: 0.06
Nodes (35): env, runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, DEVELOPER_DIR (+27 more)

### Community 8 - ".s3"
Cohesion: 0.17
Nodes (4): SaveConnectionUseCase, withWorkflowFixture(), WorkflowTests, sftpSettings()

### Community 9 - "steps"
Cohesion: 0.11
Nodes (4): GCSDriveTests, GoogleDriveValidationTests, AppSignInTests, GoogleSignInEditorTests

### Community 10 - "MountStatus"
Cohesion: 0.07
Nodes (18): AppViewModel, Activity, connected, downloading, idle, uploading, .busy, Indicator (+10 more)

### Community 11 - "LocalizedError"
Cohesion: 0.11
Nodes (7): Credentials, .encryptionPassword, .googleSignIn, .keyPassphrase, .password, ConnectionRulesTests, ConnectionEditorViewModelTests

### Community 12 - "Credentials"
Cohesion: 0.09
Nodes (17): ClosedRange<Date>, DateInterval, TrafficPeriod, custom, last12Months, last30Days, last90Days, TrafficPreset (+9 more)

### Community 13 - "MountService"
Cohesion: 0.13
Nodes (3): AppViewModel, .activity, AppViewModel

### Community 14 - "TrafficPreset"
Cohesion: 0.12
Nodes (5): ServerTrustChallenge, .errorDescription, .server, SFTPTrustStore, Pending

### Community 15 - "TrafficPreset"
Cohesion: 0.14
Nodes (14): ConnectionDetail, .awsDetails, .body, .bucketDetail, .disconnected, .logo, .notices, .sftpDetails (+6 more)

### Community 16 - "AppViewModel"
Cohesion: 0.07
Nodes (29): env, runs-on, steps, timeout-minutes, APPLE_ID, DEVELOPER_DIR, GH_TOKEN, GOOGLE_CLIENT_ID (+21 more)

### Community 18 - ".sftp"
Cohesion: 0.14
Nodes (6): AppKit, Charts, Network, SwiftUI, UniformTypeIdentifiers, UnlocalFSPresentation

### Community 19 - "ServerTrustChallenge"
Cohesion: 0.10
Nodes (10): AppPaths, .knownHosts, .sockets, .traffic, MountCommand, .arguments, .environment, .mountParameters (+2 more)

### Community 20 - ".gcs"
Cohesion: 0.12
Nodes (15): State, downloaded, downloading, failed, queued, uploaded, uploading, UnfinishedUpload (+7 more)

### Community 21 - "TrafficViewModelTests"
Cohesion: 0.11
Nodes (4): DesktopServices, RcloneConfigDestination, MacOSDesktopServices, .opensAtLogin

### Community 22 - "MacOSDesktopServices"
Cohesion: 0.17
Nodes (6): mark(), MountSafetyTests, shutdown(), withControl(), withFixture(), statusBatch()

### Community 23 - "Equatable"
Cohesion: 0.13
Nodes (3): AppDelegate, .model, .viewModels

### Community 24 - "withControl"
Cohesion: 0.12
Nodes (18): GoogleClient, Backend, .rcloneType, NamedRemote, Options, RcloneRemote, .cryptOptions, .driveOptions (+10 more)

### Community 25 - ".s3"
Cohesion: 0.14
Nodes (8): GoogleSignIn, controlCalls(), failingStatus(), revokedDrive(), ServiceRecoveryTests, withRevokedDrive(), StubbedDrives, .rcloneCalls

### Community 26 - ".refresh"
Cohesion: 0.08
Nodes (22): Provider, aws, .backend, cloudflare, digitalOcean, googleCloudStorage, googleDrive, .group (+14 more)

### Community 28 - "Decision"
Cohesion: 0.16
Nodes (8): Decision, disconnect, quit, wait, RcloneProcess, TrafficCheckpoint, TrafficReading, TrafficSave

### Community 29 - "ActivityView"
Cohesion: 0.16
Nodes (5): ConnectionStore, SavedConnectionRepository, configURL(), ConnectionTests, RepositoryTests

### Community 30 - "LocalizedError"
Cohesion: 0.16
Nodes (7): Drive, dump(), makeDrive(), rclone(), verifyRoundTrip(), withOfflineDrive(), waitUntil()

### Community 31 - "DeleteConnectionUseCase"
Cohesion: 0.08
Nodes (4): AppPollingTests, MenuBarActivityTests, SpeedRecordingTests, ControlServers

### Community 32 - "StubbedDrives"
Cohesion: 0.13
Nodes (10): Direction, .color, download, .fill, .label, .symbol, upload, SpeedChart (+2 more)

### Community 33 - "FixtureResources"
Cohesion: 0.15
Nodes (4): RcloneState, running, stopped, untracked

### Community 34 - "ViewModelFixture"
Cohesion: 0.22
Nodes (7): BatchReply, .current, counters(), finished(), reply(), TrafficTests, withRclone()

### Community 35 - "withRclone"
Cohesion: 0.13
Nodes (16): ClosedRange<Date>, .formattedDays, DateInterval, .formattedDays, ShareBar, .body, TrafficChart, TrafficList (+8 more)

### Community 36 - "UnixConnection"
Cohesion: 0.15
Nodes (8): DriveTraffic, TrafficDay, TrafficRepository, .unsaved, SidebarItem, drive, traffic, .total

### Community 37 - "RcloneRemote"
Cohesion: 0.16
Nodes (8): TrafficBar, .id, TrafficViewModel, .custom, .period, .recentTotal, .unit, .body

### Community 38 - "ViewModelFactory"
Cohesion: 0.17
Nodes (3): TrafficStore, .migrator, TrafficStoreTests

### Community 39 - "ConnectionField"
Cohesion: 0.18
Nodes (5): FixtureResources, Launch, requireOutput(), withFixture(), startAgent()

### Community 40 - "AppViewModel"
Cohesion: 0.11
Nodes (6): OSLog, MountService, .baseEnvironment, TrafficTracker, ServiceManagement, UserNotifications

### Community 41 - ".connect"
Cohesion: 0.14
Nodes (3): Outcome, connected, ejected

### Community 42 - "ServiceAccountKey"
Cohesion: 0.17
Nodes (4): CredentialStorage, MemoryCredentialStorage, UnavailableCredentialStorage, LockableCredentialStorage

### Community 43 - "ValidationResult"
Cohesion: 0.12
Nodes (11): ConnectionBucketFields, .body, ConnectionEditorField, .body, ConnectionIdentityFields, .body, .providerPicker, .serviceAccountField (+3 more)

### Community 44 - "AppViewModel"
Cohesion: 0.16
Nodes (3): ControlFailure, ControlRequest, ControlServer

### Community 45 - "SFTPFixture"
Cohesion: 0.11
Nodes (19): ConnectionField, accessKey, bucket, confirmation, .displayName, encryptionPassword, endpoint, folder (+11 more)

### Community 46 - ".remove"
Cohesion: 0.11
Nodes (14): DriveCondition, checking, connected, disconnected, ejected, .indicator, needsAttention, needsReconnect (+6 more)

### Community 47 - "ControlServer"
Cohesion: 0.17
Nodes (8): FinderServicesTests, ViewModelFixture, .paths, .rcloneCalls, .root, .service, .signInEnvironment, .traffic

### Community 48 - "ActivityViewModel"
Cohesion: 0.18
Nodes (3): FakeStorage, .uploadCount, UploadCleanupTests

### Community 49 - "ViewModelFactory"
Cohesion: 0.16
Nodes (3): .fieldErrors, ConnectionValidationTests, SFTPValidationTests

### Community 51 - "withRclone"
Cohesion: 0.15
Nodes (8): .isSignedInToGoogle, .secrets, GoogleAccountChanged, .errorDescription, GoogleSignInRequired, .errorDescription, GoogleToken, Fields

### Community 52 - "ControlFailure"
Cohesion: 0.16
Nodes (9): ConnectionEditorViewModel, .connection, .credentials, .firstInvalidField, .initialFocus, .isLocked, .locksRemoteFolder, .signingIn (+1 more)

### Community 53 - "GoogleToken"
Cohesion: 0.15
Nodes (10): FileActivity, .finishedAt, .id, .isUpload, Sequence<FileActivity>, .folder, .isCancellable, .name (+2 more)

### Community 54 - "ConnectionDraft"
Cohesion: 0.24
Nodes (4): Traffic, .total, TrafficViewModelTests, .yesterday

### Community 55 - ".runBackendCommand"
Cohesion: 0.20
Nodes (8): SFTPFixture, .agentSocket, .connection, .credentials, .key, .protectedKey, .served, SFTPServer

### Community 56 - "SFTPTrustStore"
Cohesion: 0.12
Nodes (10): ConnectionRow, .icon, .sidebar, FocusedValues, SidebarSearchField, .body, ProviderIcon, .body (+2 more)

### Community 57 - "ServerTrustChallenge"
Cohesion: 0.13
Nodes (11): Backend, gcs, googleDrive, .locksFolderAfterSave, s3Compatible, sftp, .supportsMultiThreadUploads, .supportsServerCopy (+3 more)

### Community 58 - "GoogleToken"
Cohesion: 0.16
Nodes (6): ActivityViewModel, .refreshInterval, SpeedSample, .axisLimit, .fastestDownload, .fastestUpload

### Community 60 - "AppError"
Cohesion: 0.18
Nodes (7): ConnectionEditor, .advancedSection, .body, Pane, connection, .displayName, settings

### Community 63 - "ServiceAccountKey"
Cohesion: 0.20
Nodes (3): S3DriveTests, S3Server, withS3Drive()

### Community 64 - ".sample"
Cohesion: 0.19
Nodes (7): GCSAuthentication, googleAccount, .id, serviceAccount, .title, GCSSettings, Config

### Community 65 - ".remove"
Cohesion: 0.18
Nodes (5): MenuBarIcon, .accessibilityValue, .animatesUploads, .body, .image

### Community 66 - ".serve"
Cohesion: 0.19
Nodes (7): AWSSettings, .customKMSKey, ServerSideEncryption, .id, kms, s3Managed, .title

### Community 67 - "base"
Cohesion: 0.15
Nodes (7): SFTPAuthentication, agent, .id, password, privateKey, .title, SFTPSettings

### Community 68 - "Backend"
Cohesion: 0.26
Nodes (6): String, .isBlank, ValidationResult, .fieldErrors, Issue, .isValid

### Community 69 - "Backend"
Cohesion: 0.18
Nodes (8): ViewModelFactory, Build from source, Documentation, Documentation development, Features, Install, License, .body

### Community 70 - "GoogleSignInRun"
Cohesion: 0.15
Nodes (13): ARCHS, ASSETCATALOG_COMPILER_APPICON_NAME, CODE_SIGN_STYLE, CURRENT_PROJECT_VERSION, ENABLE_HARDENED_RUNTIME, ENABLE_USER_SCRIPT_SANDBOXING, INFOPLIST_FILE, MARKETING_VERSION (+5 more)

### Community 71 - "StatusIndicator"
Cohesion: 0.21
Nodes (7): SFTPDriveTests, SFTPLogin, agent, key, password, protectedKey, withSFTPDrive()

### Community 73 - ".connect"
Cohesion: 0.22
Nodes (6): DriveEjectError, .errorDescription, UploadsPendingError, .errorDescription, ControlUnreachable, .timedOut

### Community 74 - "ConnectionDraft"
Cohesion: 0.22
Nodes (4): MountStatus, .isActive, .isServing, .needsReconnect

### Community 75 - "failingStatus"
Cohesion: 0.20
Nodes (7): ActivityFileName, .body, ActivityTable, .body, ActivityView, .activity, .idle

### Community 79 - ".shareLink"
Cohesion: 0.18
Nodes (10): macOS, name, options, deploymentTarget, postGenCommand, packages, UnlocalFSCore, settings (+2 more)

### Community 80 - "ShareLinkExpiry"
Cohesion: 0.22
Nodes (7): ActivityStatus, .body, .movingText, .progress, FailedUploadButton, .body, .details

### Community 81 - "ValidationResult"
Cohesion: 0.22
Nodes (6): UnlocalFSApp, .body, MainView, .detail, MenuContent, .body

### Community 82 - "FileActionError"
Cohesion: 0.20
Nodes (9): interval, time, timezone, updates, directory, open-pull-requests-limit, package-ecosystem, schedule (+1 more)

### Community 83 - "State"
Cohesion: 0.27
Nodes (3): .serviceAccountEmail, ServiceAccountKey, GCSValidationTests

### Community 85 - "SFTPConnectionFields"
Cohesion: 0.22
Nodes (6): ShareLinkExpiry, day, hour, .title, week, AppViewModel

### Community 88 - "String"
Cohesion: 0.24
Nodes (4): AppViewModel, UploadCleanup, .message, .title

### Community 91 - "GoogleDriveTests"
Cohesion: 0.20
Nodes (10): Debug, Release, package, product, UnlocalFS, configFiles, dependencies, platform (+2 more)

### Community 92 - "failingStatus"
Cohesion: 0.22
Nodes (7): .actions, .header, DriveManagementItems, .body, .body, StatusIndicator, .body

### Community 93 - ".sftp"
Cohesion: 0.27
Nodes (4): SFTPConnectionFields, .authenticationHelp, .authenticationSection, .body

### Community 95 - "UploadCleanup"
Cohesion: 0.28
Nodes (3): AppQuitTests, Overlap, .peak

### Community 97 - "ServiceAccountKey"
Cohesion: 0.25
Nodes (8): S3StorageClass, glacierInstantRetrieval, .id, intelligentTiering, oneZoneInfrequentAccess, standard, standardInfrequentAccess, .title

### Community 98 - "README.md"
Cohesion: 0.25
Nodes (3): ConnectionDraft, .id, .isDuplicate

### Community 99 - "GoogleDriveTests"
Cohesion: 0.25
Nodes (8): config, targets, config, schemes, UnlocalFS, archive, build, run

### Community 100 - "UploadTally"
Cohesion: 0.25
Nodes (4): GoogleAccountField, .body, GoogleDriveConnectionFields, .body

### Community 101 - "README.md"
Cohesion: 0.29
Nodes (6): ActivitySnapshot, checking, .files, idle, transfers, unavailable

### Community 102 - "GoogleSignInButton"
Cohesion: 0.29
Nodes (4): UploadCancellation, .message, .title, .body

### Community 113 - "Command.swift"
Cohesion: 0.33
Nodes (6): copyFiles, destination, subpath, buildPhase, path, sources

### Community 115 - "awsFixture"
Cohesion: 0.40
Nodes (5): basedOnDependencyAnalysis, name, script, shell, postBuildScripts

### Community 116 - "RcloneRemote.swift"
Cohesion: 0.40
Nodes (3): .signInAgainButton, GoogleSignInButton, .body

### Community 117 - "test"
Cohesion: 0.50
Nodes (4): package, config, targets, test

## Knowledge Gaps
- **280 isolated node(s):** `standard`, `intelligentTiering`, `standardInfrequentAccess`, `oneZoneInfrequentAccess`, `glacierInstantRetrieval` (+275 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 644 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **33 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Connection` connect `Decodable` to `.s3`, `UnixConnection`, `.onlyAGoogleDriveWithARevokedGrantAsksToSignInAgain`, `.s3`, `steps`, `MountStatus`, `LocalizedError`, `MountService`, `TrafficPreset`, `ConnectionStore`, `ServerTrustChallenge`, `TrafficViewModelTests`, `MacOSDesktopServices`, `withControl`, `.s3`, `.refresh`, `withRclone`, `Decision`, `ActivityView`, `LocalizedError`, `DeleteConnectionUseCase`, `FixtureResources`, `ViewModelFixture`, `RcloneRemote`, `ViewModelFactory`, `.connect`, `ActivityViewModel`, `ViewModelFactory`, `ControlFailure`, `ConnectionDraft`, `.runBackendCommand`, `SFTPTrustStore`, `UploadCancellation`, `.sample`, `.serve`, `failingStatus`, `ValidationResult`, `ViewModelFixture`, `String`, `TrafficView`, `failingStatus`, `README.md`, `GoogleSignInButton`, `Darwin`, `ActivityViewModel`, `.signInAgain`?**
  _High betweenness centrality (0.220) - this node is a cross-community bridge._
- **Are the 10 inferred relationships involving `Connection` (e.g. with `AWSSettings` and `GCSSettings`) actually correct?**
  _`Connection` has 10 INFERRED edges - model-reasoned connections that need verification._
- **What connects `standard`, `intelligentTiering`, `standardInfrequentAccess` to the rest of the system?**
  _280 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Connection` be split into smaller, more focused modules?**
  _Cohesion score 0.06101190476190476 - nodes in this community are weakly interconnected._
- **Why does `UnlocalFSDomain` connect `.s3` to `Connection`, `Decodable`, `ViewModelFixture`, `withRclone`, `.validate`, `AppViewModel`, `Credentials`, `Command.swift`, `.sftp`, `Command.swift`, `.refresh`?**
  _High betweenness centrality (0.084) - this node is a cross-community bridge._
- **Are the 33 inferred relationships involving `Credentials` (e.g. with `.delete()` and `ConnectionEditorViewModel`) actually correct?**
  _`Credentials` has 33 INFERRED edges - model-reasoned connections that need verification._
- **Should `Decodable` be split into smaller, more focused modules?**
  _Cohesion score 0.054901960784313725 - nodes in this community are weakly interconnected._