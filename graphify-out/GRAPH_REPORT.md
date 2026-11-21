# Graph Report - unlocalfs  (2026-11-21)

## Corpus Check
- 170 files · ~49,523 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 12 file(s) not represented in the graph (top: .xcstrings 5, (none) 3, .resolved 1)

## Summary
- 2174 nodes · 5334 edges · 127 communities (91 shown, 36 thin omitted)
- Extraction: 81% EXTRACTED · 19% INFERRED · 0% AMBIGUOUS · INFERRED: 1006 edges (avg confidence: 0.85)
- Token cost: 289,731 input · 0 output

## Graph Freshness
- Built from commit: `f1479ffc`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- withControl
- Decodable
- ConnectionStore
- .mount
- DriveGateway
- UnixConnection
- Connection
- .validate
- .s3
- ConnectionRepository
- MountStatus
- LocalizedError
- Date
- AppViewModel
- TrafficPreset
- .shareLink
- AppViewModel
- .remove
- Credentials
- ServerTrustChallenge
- .gcs
- TrafficViewModelTests
- MacOSDesktopServices
- Equatable
- withControl
- ViewModelFixture
- .refresh
- MountService
- Decision
- AppSearchTests
- Equatable
- AppError
- ConnectionIdentityFields
- .sftp
- ViewModelFixture
- Date
- GoogleToken
- AppViewModel
- .status
- AppError
- .connect
- ServerTrustChallenge
- .connect
- AppViewModel
- SFTPFixture
- .remove
- ControlServer
- ActivityViewModel
- FileActivity
- .refresh
- ServiceAccountKey
- TrafficView
- .validate
- .runBackendCommand
- ServerTrustChallenge
- ServerTrustChallenge
- FileActivity
- SFTPAuthentication
- .control
- Sendable
- TrafficViewModelTests
- .sample
- MountService
- Drive.swift
- CaseIterable
- ShareLinkExpiry
- Decision
- StatusIndicator
- Keychain
- .connect
- ConnectionDraft
- MenuBarIcon
- GCSConnectionFields
- TransferSummary
- GoogleSignIn
- .shareLink
- UnfinishedUpload
- SpeedSample
- ConnectionBucketFields
- State
- Traffic
- FakeDrive
- awsFixture
- .signInAgain
- DriveEjectError
- GoogleAccountField
- TrafficView
- statusBatch
- ConnectionEditorField
- ControlServers
- FileActionError
- UploadCleanup
- Command.swift
- sftpSettings
- TrafficPeriod
- GoogleDriveTests
- UploadTally
- .status
- MainView
- UploadCleanup
- .quitDisconnectsEveryDriveAtTheSameTime
- postBuildScripts
- QuitUseCase
- Command.swift
- .signInAgain
- S3StorageClass
- .test
- UploadCleanup
- State
- AppViewModel
- ClosedRange<Date>
- .serve

## God Nodes (most connected - your core abstractions)
1. `Connection` - 228 edges
2. `UnlocalFSDomain` - 109 edges
3. `Credentials` - 98 edges
4. `MountService` - 91 edges
5. `ViewModelFixture` - 84 edges
6. `DriveGateway` - 52 edges
7. `AppViewModel` - 49 edges
8. `ConnectionEditorViewModel` - 48 edges
9. `UnlocalFSPresentation` - 46 edges
10. `AppError` - 44 edges

## Surprising Connections (you probably didn't know these)
- `Build from source` --references--> `ViewModelFactory`  [INFERRED]
  README.md → Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/ViewModelFactory.swift
- `.body` --references--> `Provider`  [INFERRED]
  UnlocalFS/Presentation/Provider+Logo.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `ActivityView` --references--> `ActivityViewModel`  [EXTRACTED]
  UnlocalFS/Presentation/Activity/ActivityView.swift → Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/ActivityViewModel.swift
- `.selected` --references--> `Connection`  [INFERRED]
  Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/AppViewModel.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `AppDelegate` --references--> `ViewModelFactory`  [EXTRACTED]
  UnlocalFS/Application/UnlocalFSApp.swift → Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/ViewModelFactory.swift

## Import Cycles
- None detected.

## Communities (127 total, 36 thin omitted)

### Community 0 - "withControl"
Cohesion: 0.10
Nodes (3): ActivityViewModelTests, AppViewModelTests, TestDesktopServices

### Community 1 - "Decodable"
Cohesion: 0.06
Nodes (45): DriveAbout, User, UploadTally, BatchResult, CodingKeys, error, ControlSnapshot, CodingKeys (+37 more)

### Community 2 - "ConnectionStore"
Cohesion: 0.12
Nodes (6): ExportRcloneConfigUseCase, ConnectionStore, SavedConnectionRepository, configURL(), ConnectionTests, RepositoryTests

### Community 3 - ".mount"
Cohesion: 0.05
Nodes (12): Connection, .backend, .bucketPath, .exportsRcloneConfig, .storageName, .usesGoogleSignIn, .usesUploadTimes, .driveStorage (+4 more)

### Community 4 - "DriveGateway"
Cohesion: 0.11
Nodes (10): ConnectionRepository, DeleteConnectionUseCase, DriveGateway, ConnectDriveUseCase, Outcome, connected, ejected, SignInAgainUseCase (+2 more)

### Community 5 - "UnixConnection"
Cohesion: 0.07
Nodes (12): GCSDriveTests, GoogleDriveValidationTests, AppSignInTests, FinderServicesTests, GoogleSignInEditorTests, ViewModelFixture, .paths, .rcloneCalls (+4 more)

### Community 6 - "Connection"
Cohesion: 0.07
Nodes (9): Darwin, Foundation, GRDB, Observation, MountService, .baseEnvironment, TrafficTracker, Security (+1 more)

### Community 7 - ".validate"
Cohesion: 0.08
Nodes (13): .serviceAccountEmail, ServiceAccountKey, String, .isBlank, ValidationResult, .fieldErrors, Issue, .isValid (+5 more)

### Community 8 - ".s3"
Cohesion: 0.10
Nodes (4): Synchronization, Testing, UnlocalFSInfrastructure, UnlocalFSTestSupport

### Community 9 - "ConnectionRepository"
Cohesion: 0.05
Nodes (42): runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, environment, if (+34 more)

### Community 10 - "MountStatus"
Cohesion: 0.12
Nodes (7): Credentials, .encryptionPassword, .googleSignIn, .keyPassphrase, .password, ConnectionRulesTests, ConnectionEditorViewModelTests

### Community 11 - "LocalizedError"
Cohesion: 0.15
Nodes (4): CredentialStorage, MemoryCredentialStorage, UnavailableCredentialStorage, LockableCredentialStorage

### Community 12 - "Date"
Cohesion: 0.06
Nodes (35): env, runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, DEVELOPER_DIR (+27 more)

### Community 13 - "AppViewModel"
Cohesion: 0.08
Nodes (17): AppViewModel, Activity, connected, downloading, idle, uploading, .busy, Indicator (+9 more)

### Community 14 - "TrafficPreset"
Cohesion: 0.21
Nodes (5): SFTPSettings, .agentSocketPath, .keyPath, SFTPTrustStore, Pending

### Community 15 - ".shareLink"
Cohesion: 0.16
Nodes (3): TrafficStore, .migrator, TrafficStoreTests

### Community 16 - "AppViewModel"
Cohesion: 0.09
Nodes (16): ClosedRange<Date>, DateInterval, TrafficPeriod, custom, last12Months, last30Days, last90Days, TrafficPreset (+8 more)

### Community 17 - ".remove"
Cohesion: 0.09
Nodes (4): AppPollingTests, AppSearchTests, CancelUploadTests, MenuBarActivityTests

### Community 18 - "Credentials"
Cohesion: 0.11
Nodes (10): AppKit, Charts, Network, SwiftUI, UniformTypeIdentifiers, ClosedRange<Date>, .formattedDays, DateInterval (+2 more)

### Community 19 - "ServerTrustChallenge"
Cohesion: 0.07
Nodes (29): env, runs-on, steps, timeout-minutes, APPLE_ID, DEVELOPER_DIR, GH_TOKEN, GOOGLE_CLIENT_ID (+21 more)

### Community 20 - ".gcs"
Cohesion: 0.12
Nodes (4): DesktopServices, RcloneConfigDestination, MacOSDesktopServices, .opensAtLogin

### Community 21 - "TrafficViewModelTests"
Cohesion: 0.13
Nodes (7): mark(), MountSafetyTests, shutdown(), withControl(), withFixture(), failingStatus(), statusBatch()

### Community 22 - "MacOSDesktopServices"
Cohesion: 0.09
Nodes (7): Notification, AppDelegate, .model, .viewModels, UnlocalFSApp, .driveCommands, .model

### Community 23 - "Equatable"
Cohesion: 0.20
Nodes (7): Traffic, .total, TrafficMeter, .unsaved, TrafficReading, TrafficSave, TrafficMeterTests

### Community 24 - "withControl"
Cohesion: 0.17
Nodes (12): ConnectionDetail, .awsDetails, .bucketDetail, .disconnected, .logo, .notices, .sftpDetails, .toggleSymbol (+4 more)

### Community 25 - "ViewModelFixture"
Cohesion: 0.10
Nodes (10): AppPaths, .knownHosts, .sockets, .traffic, MountCommand, .arguments, .environment, .mountParameters (+2 more)

### Community 26 - ".refresh"
Cohesion: 0.10
Nodes (16): TrafficBar, .id, TrafficViewModel, .custom, .period, .recentTotal, .unit, .body (+8 more)

### Community 27 - "MountService"
Cohesion: 0.20
Nodes (6): GoogleSignIn, controlCalls(), ServiceRecoveryTests, withRevokedDrive(), StubbedDrives, .rcloneCalls

### Community 28 - "Decision"
Cohesion: 0.13
Nodes (6): FileActionError, ControlSocket, ControlUnreachable, RcloneError, UnixConnection, .timedOut

### Community 29 - "AppSearchTests"
Cohesion: 0.13
Nodes (10): Direction, .color, download, .fill, .label, .symbol, upload, SpeedChart (+2 more)

### Community 30 - "Equatable"
Cohesion: 0.15
Nodes (6): Decision, disconnect, quit, wait, RcloneProcess, TrafficCheckpoint

### Community 31 - "AppError"
Cohesion: 0.10
Nodes (19): Provider, aws, .backend, cloudflare, digitalOcean, googleCloudStorage, googleDrive, .group (+11 more)

### Community 33 - ".sftp"
Cohesion: 0.26
Nodes (3): SaveConnectionUseCase, withWorkflowFixture(), WorkflowTests

### Community 34 - "ViewModelFixture"
Cohesion: 0.15
Nodes (4): RcloneState, running, stopped, untracked

### Community 35 - "Date"
Cohesion: 0.10
Nodes (20): State, downloaded, downloading, failed, queued, uploaded, uploading, SpeedSample (+12 more)

### Community 36 - "GoogleToken"
Cohesion: 0.15
Nodes (4): revokedDrive(), ControlFailure, ControlRequest, ControlServer

### Community 37 - "AppViewModel"
Cohesion: 0.18
Nodes (4): FixtureResources, Launch, requireOutput(), withFixture()

### Community 39 - ".status"
Cohesion: 0.15
Nodes (10): ConnectionEditorViewModel, .connection, .credentials, .fieldErrors, .firstInvalidField, .initialFocus, .isLocked, .locksRemoteFolder (+2 more)

### Community 40 - "AppError"
Cohesion: 0.19
Nodes (3): AppViewModel, .activity, .canDisconnectAll

### Community 41 - ".connect"
Cohesion: 0.11
Nodes (19): ConnectionField, accessKey, bucket, confirmation, .displayName, encryptionPassword, endpoint, folder (+11 more)

### Community 42 - "ServerTrustChallenge"
Cohesion: 0.12
Nodes (6): ServerTrustChallenge, .errorDescription, .server, .body, ServerTrustView, .body

### Community 43 - ".connect"
Cohesion: 0.11
Nodes (14): DriveCondition, checking, connected, disconnected, ejected, .indicator, needsAttention, needsReconnect (+6 more)

### Community 44 - "AppViewModel"
Cohesion: 0.25
Nodes (7): BatchReply, .current, counters(), finished(), reply(), TrafficTests, withRclone()

### Community 45 - "SFTPFixture"
Cohesion: 0.23
Nodes (6): Drive, dump(), makeDrive(), rclone(), verifyRoundTrip(), withOfflineDrive()

### Community 46 - ".remove"
Cohesion: 0.18
Nodes (9): SFTPFixture, .agentSocket, .connection, .credentials, .key, .protectedKey, .served, SFTPServer (+1 more)

### Community 47 - "ControlServer"
Cohesion: 0.15
Nodes (8): .isSignedInToGoogle, .secrets, GoogleAccountChanged, .errorDescription, GoogleSignInRequired, .errorDescription, GoogleToken, Fields

### Community 48 - "ActivityViewModel"
Cohesion: 0.06
Nodes (16): ActivityViewModel, .refreshInterval, FileActivity, .folder, .isCancellable, .name, AppAlert, AppViewModel (+8 more)

### Community 50 - "FileActivity"
Cohesion: 0.07
Nodes (17): FileActivity, .finishedAt, .id, .isUpload, Sequence<FileActivity>, ActivitySnapshot, checking, .files (+9 more)

### Community 51 - ".refresh"
Cohesion: 0.23
Nodes (12): NamedRemote, Options, RcloneRemote, .cryptOptions, .driveOptions, .environment, .gcsOptions, .namedRemotes (+4 more)

### Community 52 - "ServiceAccountKey"
Cohesion: 0.16
Nodes (7): AWSSettings, .customKMSKey, ServerSideEncryption, .id, kms, s3Managed, .title

### Community 53 - "TrafficView"
Cohesion: 0.20
Nodes (3): GCSConnectionFields, .body, .serviceAccountField

### Community 54 - ".validate"
Cohesion: 0.22
Nodes (3): S3DriveTests, S3Server, withS3Drive()

### Community 55 - ".runBackendCommand"
Cohesion: 0.09
Nodes (14): Backend, gcs, googleDrive, .locksFolderAfterSave, s3Compatible, sftp, .supportsMultiThreadUploads, .supportsServerCopy (+6 more)

### Community 56 - "ServerTrustChallenge"
Cohesion: 0.16
Nodes (3): SpeedRecordingTests, TrafficViewModelTests, .yesterday

### Community 57 - "ServerTrustChallenge"
Cohesion: 0.22
Nodes (8): ActivityFileName, .body, ActivityTable, .body, ActivityView, .activity, .idle, .body

### Community 58 - "FileActivity"
Cohesion: 0.20
Nodes (6): .sidebar, FocusedValues, SidebarSearchField, .body, TrafficRow, .body

### Community 59 - "SFTPAuthentication"
Cohesion: 0.19
Nodes (7): GCSAuthentication, googleAccount, .id, serviceAccount, .title, GCSSettings, Config

### Community 61 - ".control"
Cohesion: 0.17
Nodes (5): MenuBarIcon, .accessibilityValue, .animatesUploads, .body, .image

### Community 62 - "Sendable"
Cohesion: 0.16
Nodes (7): DriveTraffic, TrafficDay, TrafficRepository, SidebarItem, drive, traffic, .total

### Community 63 - "TrafficViewModelTests"
Cohesion: 0.15
Nodes (13): ARCHS, ASSETCATALOG_COMPILER_APPICON_NAME, CODE_SIGN_STYLE, CURRENT_PROJECT_VERSION, ENABLE_HARDENED_RUNTIME, ENABLE_USER_SCRIPT_SANDBOXING, INFOPLIST_FILE, MARKETING_VERSION (+5 more)

### Community 64 - ".sample"
Cohesion: 0.13
Nodes (10): ConnectionEditorField, .body, ConnectionIdentityFields, .body, .providerPicker, GoogleAccountField, .body, GoogleDriveConnectionFields (+2 more)

### Community 65 - "MountService"
Cohesion: 0.21
Nodes (7): SFTPDriveTests, SFTPLogin, agent, key, password, protectedKey, withSFTPDrive()

### Community 66 - "Drive.swift"
Cohesion: 0.19
Nodes (3): FakeStorage, .uploadCount, UploadCleanupTests

### Community 67 - "CaseIterable"
Cohesion: 0.18
Nodes (9): ProviderGroup, generic, google, s3Services, .providerSections, Pane, connection, .displayName (+1 more)

### Community 68 - "ShareLinkExpiry"
Cohesion: 0.29
Nodes (3): ConnectionDraft, .id, .isDuplicate

### Community 70 - "Decision"
Cohesion: 0.20
Nodes (4): MountStatus, .isActive, .isServing, .needsReconnect

### Community 71 - "StatusIndicator"
Cohesion: 0.33
Nodes (3): ConnectionEditor, .advancedSection, .editor

### Community 74 - "ConnectionDraft"
Cohesion: 0.22
Nodes (7): ActivityStatus, .body, .movingText, .progress, FailedUploadButton, .body, .details

### Community 75 - "MenuBarIcon"
Cohesion: 0.27
Nodes (4): SFTPConnectionFields, .authenticationHelp, .authenticationSection, .body

### Community 76 - "GCSConnectionFields"
Cohesion: 0.25
Nodes (7): .body, MainView, .detail, MenuContent, .body, SettingsView, .body

### Community 77 - "TransferSummary"
Cohesion: 0.20
Nodes (9): interval, time, timezone, updates, directory, open-pull-requests-limit, package-ecosystem, schedule (+1 more)

### Community 79 - ".shareLink"
Cohesion: 0.22
Nodes (6): ShareLinkExpiry, day, hour, .title, week, AppViewModel

### Community 81 - "SpeedSample"
Cohesion: 0.20
Nodes (10): Debug, Release, package, product, UnlocalFS, configFiles, dependencies, platform (+2 more)

### Community 82 - "ConnectionBucketFields"
Cohesion: 0.25
Nodes (4): ConnectionBucketFields, .body, S3ConnectionFields, .body

### Community 83 - "State"
Cohesion: 0.29
Nodes (4): DriveEjectError, .errorDescription, UploadsPendingError, .errorDescription

### Community 84 - "Traffic"
Cohesion: 0.26
Nodes (3): AppError, Command, CommandTests

### Community 86 - "awsFixture"
Cohesion: 0.28
Nodes (3): AppQuitTests, Overlap, .peak

### Community 88 - "DriveEjectError"
Cohesion: 0.18
Nodes (9): .actions, .header, DriveManagementItems, .body, ConnectionRow, .body, .icon, StatusIndicator (+1 more)

### Community 89 - "GoogleAccountField"
Cohesion: 0.29
Nodes (5): ShareBar, .body, .body, TrafficStats, .body

### Community 90 - "TrafficView"
Cohesion: 0.25
Nodes (8): S3StorageClass, glacierInstantRetrieval, .id, intelligentTiering, oneZoneInfrequentAccess, standard, standardInfrequentAccess, .title

### Community 92 - "ConnectionEditorField"
Cohesion: 0.25
Nodes (8): config, targets, config, schemes, UnlocalFS, archive, build, run

### Community 94 - "FileActionError"
Cohesion: 0.29
Nodes (6): SFTPAuthentication, agent, .id, password, privateKey, .title

### Community 99 - "GoogleDriveTests"
Cohesion: 0.29
Nodes (6): name, packages, UnlocalFSCore, settings, targets, path

### Community 100 - "UploadTally"
Cohesion: 0.18
Nodes (8): ViewModelFactory, Build from source, Documentation, Documentation development, Features, Install, License, AppDependencies

### Community 103 - "MainView"
Cohesion: 0.25
Nodes (3): AppViewModel, .showsTraffic, .visibleConnections

### Community 107 - "QuitUseCase"
Cohesion: 0.33
Nodes (6): copyFiles, destination, subpath, buildPhase, path, sources

### Community 109 - ".signInAgain"
Cohesion: 0.40
Nodes (5): macOS, options, deploymentTarget, postGenCommand, projectFileFormat

### Community 110 - "S3StorageClass"
Cohesion: 0.40
Nodes (5): basedOnDependencyAnalysis, name, script, shell, postBuildScripts

### Community 111 - ".test"
Cohesion: 0.40
Nodes (3): .signInAgainButton, GoogleSignInButton, .body

### Community 113 - "UploadCleanup"
Cohesion: 0.50
Nodes (3): OSLog, ServiceManagement, UserNotifications

### Community 115 - "State"
Cohesion: 0.50
Nodes (4): package, config, targets, test

## Knowledge Gaps
- **283 isolated node(s):** `.refreshInterval`, `.isCancellable`, `.name`, `.folder`, `.activity` (+278 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 664 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **36 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Connection` connect `.mount` to `withControl`, `ConnectionStore`, `DriveGateway`, `UnixConnection`, `.validate`, `MountStatus`, `AppViewModel`, `TrafficPreset`, `.shareLink`, `.gcs`, `TrafficViewModelTests`, `MacOSDesktopServices`, `withControl`, `ViewModelFixture`, `.refresh`, `MountService`, `Equatable`, `ConnectionIdentityFields`, `.sftp`, `ViewModelFixture`, `UnixConnection`, `.status`, `AppError`, `AppViewModel`, `SFTPFixture`, `.remove`, `ActivityViewModel`, `.control`, `FileActivity`, `.refresh`, `ServiceAccountKey`, `.runBackendCommand`, `ServerTrustChallenge`, `ServerTrustChallenge`, `SFTPAuthentication`, `ControlServer`, `Sendable`, `Drive.swift`, `CaseIterable`, `ShareLinkExpiry`, `.execute`, `Decision`, `GoogleSignIn`, `UnfinishedUpload`, `Traffic`, `FakeDrive`, `.signInAgain`, `DriveEjectError`, `ControlServers`, `UploadCleanup`, `.status`, `MainView`, `AppViewModel`?**
  _High betweenness centrality (0.246) - this node is a cross-community bridge._
- **Are the 9 inferred relationships involving `Connection` (e.g. with `AWSSettings` and `GCSSettings`) actually correct?**
  _`Connection` has 9 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.refreshInterval`, `.isCancellable`, `.name` to the rest of the system?**
  _283 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `withControl` be split into smaller, more focused modules?**
  _Cohesion score 0.09523809523809523 - nodes in this community are weakly interconnected._
- **Why does `UnlocalFSDomain` connect `Connection` to `Command.swift`, `Decodable`, `.mount`, `.s3`, `UploadCleanup`, `AppViewModel`, `SFTPFixture`, `UploadCleanup`, `FileActivity`, `Credentials`, `AppViewModel`?**
  _High betweenness centrality (0.070) - this node is a cross-community bridge._
- **Are the 33 inferred relationships involving `Credentials` (e.g. with `.delete()` and `ConnectionEditorViewModel`) actually correct?**
  _`Credentials` has 33 INFERRED edges - model-reasoned connections that need verification._
- **Should `Decodable` be split into smaller, more focused modules?**
  _Cohesion score 0.06101190476190476 - nodes in this community are weakly interconnected._