# Graph Report - unlocalfs  (2026-11-21)

## Corpus Check
- 170 files · ~49,582 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 12 file(s) not represented in the graph (top: .xcstrings 5, (none) 3, .resolved 1)

## Summary
- 2181 nodes · 5339 edges · 129 communities (82 shown, 47 thin omitted)
- Extraction: 81% EXTRACTED · 19% INFERRED · 0% AMBIGUOUS · INFERRED: 1008 edges (avg confidence: 0.85)
- Token cost: 289,731 input · 0 output

## Graph Freshness
- Built from commit: `b1b561ab`
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
- ViewModelFixture
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
- UploadCleanup
- Equatable
- AppError
- .connect
- .sftp
- Date
- QuitUseCase
- AppViewModel
- MountService
- .status
- AppError
- .connect
- ServerTrustChallenge
- .connect
- AppViewModel
- SFTPFixture
- .remove
- Darwin
- ActivityViewModel
- FileActivity
- .refresh
- ServiceAccountKey
- .validate
- .runBackendCommand
- ServerTrustChallenge
- SavedConnectionRepository
- MainView
- SFTPAuthentication
- TrafficView.swift
- Sendable
- TrafficViewModelTests
- ConnectionEditorField
- MountService
- Drive.swift
- SFTPSettings
- ShareLinkExpiry
- Decision
- Keychain
- .connect
- ConnectionDraft
- MenuBarIcon
- UploadTally
- TransferSummary
- GoogleSignIn
- .shareLink
- FileActionError
- SpeedSample
- LockableCredentialStorage
- State
- Traffic
- FakeDrive
- awsFixture
- .update
- StatusIndicator
- GoogleAccountField
- Activity
- statusBatch
- ConnectionEditorField
- FileActionError
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
- State
- ClosedRange<Date>
- .serve

## God Nodes (most connected - your core abstractions)
1. `Connection` - 229 edges
2. `UnlocalFSDomain` - 109 edges
3. `Credentials` - 98 edges
4. `MountService` - 91 edges
5. `ViewModelFixture` - 84 edges
6. `DriveGateway` - 52 edges
7. `AppViewModel` - 49 edges
8. `ConnectionEditorViewModel` - 48 edges
9. `UnlocalFSPresentation` - 46 edges
10. `Traffic` - 44 edges

## Surprising Connections (you probably didn't know these)
- `Build from source` --references--> `ViewModelFactory`  [INFERRED]
  README.md → Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/ViewModelFactory.swift
- `.body` --references--> `Provider`  [INFERRED]
  UnlocalFS/Presentation/Provider+Logo.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `.selected` --references--> `Connection`  [INFERRED]
  Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/AppViewModel.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `AppDelegate` --references--> `ViewModelFactory`  [EXTRACTED]
  UnlocalFS/Application/UnlocalFSApp.swift → Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/ViewModelFactory.swift
- `ConnectionEditor` --references--> `ConnectionEditorViewModel`  [EXTRACTED]
  UnlocalFS/Presentation/Connections/ConnectionEditor.swift → Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/ConnectionEditorViewModel.swift

## Import Cycles
- None detected.

## Communities (129 total, 47 thin omitted)

### Community 0 - "withControl"
Cohesion: 0.10
Nodes (3): ActivityViewModelTests, AppViewModelTests, TestDesktopServices

### Community 1 - "Decodable"
Cohesion: 0.07
Nodes (44): DriveAbout, User, BatchResult, CodingKeys, error, ControlSnapshot, CodingKeys, results (+36 more)

### Community 2 - "ConnectionStore"
Cohesion: 0.20
Nodes (3): ConnectionStore, configURL(), ConnectionTests

### Community 3 - ".mount"
Cohesion: 0.06
Nodes (12): Connection, .backend, .bucketPath, .exportsRcloneConfig, .storageName, .usesGoogleSignIn, .usesUploadTimes, .driveStorage (+4 more)

### Community 4 - "DriveGateway"
Cohesion: 0.15
Nodes (8): ConnectionRepository, DeleteConnectionUseCase, DriveGateway, SignInAgainUseCase, DuplicateFilesUseCase, ExportRcloneConfigUseCase, ShareFilesUseCase, AppDependencies

### Community 5 - "UnixConnection"
Cohesion: 0.09
Nodes (4): GCSDriveTests, GoogleDriveValidationTests, AppSignInTests, GoogleSignInEditorTests

### Community 6 - "Connection"
Cohesion: 0.09
Nodes (7): Foundation, GRDB, Observation, String, .expandingTilde, Security, UnlocalFSDomain

### Community 7 - ".validate"
Cohesion: 0.07
Nodes (13): .serviceAccountEmail, ServiceAccountKey, String, .isBlank, ValidationResult, .fieldErrors, Issue, .isValid (+5 more)

### Community 8 - ".s3"
Cohesion: 0.10
Nodes (4): Synchronization, Testing, UnlocalFSInfrastructure, UnlocalFSTestSupport

### Community 9 - "ConnectionRepository"
Cohesion: 0.05
Nodes (42): runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, environment, if (+34 more)

### Community 10 - "MountStatus"
Cohesion: 0.13
Nodes (6): Credentials, .encryptionPassword, .googleSignIn, .keyPassphrase, .password, ConnectionEditorViewModelTests

### Community 11 - "LocalizedError"
Cohesion: 0.21
Nodes (3): CredentialStorage, MemoryCredentialStorage, UnavailableCredentialStorage

### Community 12 - "Date"
Cohesion: 0.06
Nodes (35): env, runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, DEVELOPER_DIR (+27 more)

### Community 13 - "AppViewModel"
Cohesion: 0.08
Nodes (15): AppViewModel, .busy, Indicator, attention, connected, idle, working, .isConfirmingDelete (+7 more)

### Community 15 - ".shareLink"
Cohesion: 0.11
Nodes (7): DriveTraffic, TrafficDay, TrafficRepository, TrafficStore, .migrator, .total, TrafficStoreTests

### Community 16 - "AppViewModel"
Cohesion: 0.09
Nodes (16): ClosedRange<Date>, DateInterval, TrafficPeriod, custom, last12Months, last30Days, last90Days, TrafficPreset (+8 more)

### Community 17 - "ViewModelFixture"
Cohesion: 0.05
Nodes (14): AppPollingTests, AppSearchTests, CancelUploadTests, FinderServicesTests, MenuBarActivityTests, SpeedRecordingTests, ControlServers, ViewModelFixture (+6 more)

### Community 18 - "Credentials"
Cohesion: 0.12
Nodes (8): AppKit, Network, OSLog, ServiceManagement, SwiftUI, UniformTypeIdentifiers, UnlocalFSPresentation, UserNotifications

### Community 19 - "ServerTrustChallenge"
Cohesion: 0.07
Nodes (29): env, runs-on, steps, timeout-minutes, APPLE_ID, DEVELOPER_DIR, GH_TOKEN, GOOGLE_CLIENT_ID (+21 more)

### Community 20 - ".gcs"
Cohesion: 0.13
Nodes (4): DesktopServices, RcloneConfigDestination, MacOSDesktopServices, .opensAtLogin

### Community 21 - "TrafficViewModelTests"
Cohesion: 0.08
Nodes (11): mark(), MountSafetyTests, shutdown(), withControl(), withFixture(), failingStatus(), revokedDrive(), ControlFailure (+3 more)

### Community 22 - "MacOSDesktopServices"
Cohesion: 0.05
Nodes (17): Notification, AppDelegate, .model, .viewModels, UnlocalFSApp, .body, .driveCommands, .model (+9 more)

### Community 23 - "Equatable"
Cohesion: 0.28
Nodes (4): Traffic, .total, TrafficMeter, TrafficMeterTests

### Community 24 - "withControl"
Cohesion: 0.13
Nodes (17): ActivityView, .activity, .idle, ConnectionDetail, .actions, .awsDetails, .body, .bucketDetail (+9 more)

### Community 25 - "ViewModelFixture"
Cohesion: 0.13
Nodes (10): AppPaths, .knownHosts, .sockets, .traffic, MountCommand, .arguments, .environment, .mountParameters (+2 more)

### Community 26 - ".refresh"
Cohesion: 0.11
Nodes (15): TrafficBar, .id, TrafficViewModel, .custom, .period, .recentTotal, .unit, TrafficChart (+7 more)

### Community 27 - "MountService"
Cohesion: 0.20
Nodes (6): GoogleSignIn, controlCalls(), ServiceRecoveryTests, withRevokedDrive(), StubbedDrives, .rcloneCalls

### Community 28 - "Decision"
Cohesion: 0.08
Nodes (13): .isSignedInToGoogle, .secrets, GoogleAccountChanged, .errorDescription, GoogleSignInRequired, .errorDescription, GoogleToken, Fields (+5 more)

### Community 29 - "UploadCleanup"
Cohesion: 0.17
Nodes (5): AppAlert, AppViewModel, UploadCleanup, .message, .title

### Community 30 - "Equatable"
Cohesion: 0.20
Nodes (5): RcloneProcess, TrafficCheckpoint, .unsaved, TrafficReading, TrafficSave

### Community 31 - "AppError"
Cohesion: 0.08
Nodes (24): Provider, aws, .backend, cloudflare, digitalOcean, googleCloudStorage, googleDrive, .group (+16 more)

### Community 33 - ".sftp"
Cohesion: 0.20
Nodes (3): SaveConnectionUseCase, withWorkflowFixture(), WorkflowTests

### Community 35 - "Date"
Cohesion: 0.10
Nodes (14): UnfinishedUpload, SpeedSample, .axisLimit, .fastestDownload, .fastestUpload, Date, DayCell, .body (+6 more)

### Community 36 - "QuitUseCase"
Cohesion: 0.16
Nodes (5): QuitUseCase, Decision, disconnect, quit, wait

### Community 37 - "AppViewModel"
Cohesion: 0.17
Nodes (4): FixtureResources, Launch, requireOutput(), withFixture()

### Community 39 - ".status"
Cohesion: 0.10
Nodes (12): ConnectionEditorViewModel, .connection, .credentials, .fieldErrors, .initialFocus, .isLocked, .locksRemoteFolder, .signingIn (+4 more)

### Community 40 - "AppError"
Cohesion: 0.20
Nodes (3): AppViewModel, .activity, .canDisconnectAll

### Community 41 - ".connect"
Cohesion: 0.08
Nodes (23): ConnectionField, accessKey, bucket, confirmation, .displayName, encryptionPassword, endpoint, folder (+15 more)

### Community 42 - "ServerTrustChallenge"
Cohesion: 0.18
Nodes (3): ServerTrustChallenge, .errorDescription, .server

### Community 43 - ".connect"
Cohesion: 0.11
Nodes (14): DriveCondition, checking, connected, disconnected, ejected, .indicator, needsAttention, needsReconnect (+6 more)

### Community 44 - "AppViewModel"
Cohesion: 0.21
Nodes (7): BatchReply, .current, counters(), finished(), reply(), TrafficTests, withRclone()

### Community 45 - "SFTPFixture"
Cohesion: 0.23
Nodes (6): Drive, dump(), makeDrive(), rclone(), verifyRoundTrip(), withOfflineDrive()

### Community 46 - ".remove"
Cohesion: 0.19
Nodes (9): SFTPFixture, .agentSocket, .connection, .credentials, .key, .protectedKey, .served, SFTPServer (+1 more)

### Community 47 - "Darwin"
Cohesion: 0.25
Nodes (5): Darwin, RcloneState, running, stopped, untracked

### Community 48 - "ActivityViewModel"
Cohesion: 0.05
Nodes (21): ActivityViewModel, .refreshInterval, FileActivity, .folder, .isCancellable, .name, UploadCancellation, .fileName (+13 more)

### Community 50 - "FileActivity"
Cohesion: 0.06
Nodes (24): FileActivity, .finishedAt, .id, .isUpload, State, downloaded, downloading, failed (+16 more)

### Community 51 - ".refresh"
Cohesion: 0.14
Nodes (13): GoogleClient, NamedRemote, Options, RcloneRemote, .cryptOptions, .driveOptions, .environment, .gcsOptions (+5 more)

### Community 52 - "ServiceAccountKey"
Cohesion: 0.12
Nodes (15): AWSSettings, .customKMSKey, S3StorageClass, glacierInstantRetrieval, .id, intelligentTiering, oneZoneInfrequentAccess, standard (+7 more)

### Community 54 - ".validate"
Cohesion: 0.22
Nodes (3): S3DriveTests, S3Server, withS3Drive()

### Community 55 - ".runBackendCommand"
Cohesion: 0.09
Nodes (14): Backend, gcs, googleDrive, .locksFolderAfterSave, s3Compatible, sftp, .supportsMultiThreadUploads, .supportsServerCopy (+6 more)

### Community 58 - "MainView"
Cohesion: 0.10
Nodes (14): DriveManagementItems, .body, ConnectionRow, .body, .icon, MainView, .body, .detail (+6 more)

### Community 59 - "SFTPAuthentication"
Cohesion: 0.19
Nodes (7): GCSAuthentication, googleAccount, .id, serviceAccount, .title, GCSSettings, Config

### Community 61 - "TrafficView.swift"
Cohesion: 0.33
Nodes (5): Charts, ClosedRange<Date>, .formattedDays, DateInterval, .formattedDays

### Community 62 - "Sendable"
Cohesion: 0.24
Nodes (4): ConnectDriveUseCase, Outcome, connected, ejected

### Community 63 - "TrafficViewModelTests"
Cohesion: 0.15
Nodes (13): ARCHS, ASSETCATALOG_COMPILER_APPICON_NAME, CODE_SIGN_STYLE, CURRENT_PROJECT_VERSION, ENABLE_HARDENED_RUNTIME, ENABLE_USER_SCRIPT_SANDBOXING, INFOPLIST_FILE, MARKETING_VERSION (+5 more)

### Community 64 - "ConnectionEditorField"
Cohesion: 0.08
Nodes (15): ConnectionBucketFields, .body, ConnectionEditorField, .body, ConnectionIdentityFields, .body, .providerPicker, GCSConnectionFields (+7 more)

### Community 65 - "MountService"
Cohesion: 0.21
Nodes (7): SFTPDriveTests, SFTPLogin, agent, key, password, protectedKey, withSFTPDrive()

### Community 66 - "Drive.swift"
Cohesion: 0.18
Nodes (3): FakeStorage, .uploadCount, UploadCleanupTests

### Community 67 - "SFTPSettings"
Cohesion: 0.29
Nodes (3): SFTPSettings, .agentSocketPath, .keyPath

### Community 68 - "ShareLinkExpiry"
Cohesion: 0.18
Nodes (4): ConnectionDraft, .id, .isDuplicate, ConnectionRulesTests

### Community 70 - "Decision"
Cohesion: 0.22
Nodes (4): MountStatus, .isActive, .isServing, .needsReconnect

### Community 74 - "ConnectionDraft"
Cohesion: 0.14
Nodes (11): ActivityFileName, .body, ActivityStatus, .body, .movingText, .progress, ActivityTable, .body (+3 more)

### Community 75 - "MenuBarIcon"
Cohesion: 0.27
Nodes (4): SFTPConnectionFields, .authenticationHelp, .authenticationSection, .body

### Community 77 - "TransferSummary"
Cohesion: 0.20
Nodes (9): interval, time, timezone, updates, directory, open-pull-requests-limit, package-ecosystem, schedule (+1 more)

### Community 79 - ".shareLink"
Cohesion: 0.22
Nodes (6): ShareLinkExpiry, day, hour, .title, week, AppViewModel

### Community 81 - "SpeedSample"
Cohesion: 0.20
Nodes (10): Debug, Release, package, product, UnlocalFS, configFiles, dependencies, platform (+2 more)

### Community 83 - "State"
Cohesion: 0.29
Nodes (4): DriveEjectError, .errorDescription, UploadsPendingError, .errorDescription

### Community 84 - "Traffic"
Cohesion: 0.23
Nodes (3): AppError, Command, CommandTests

### Community 86 - "awsFixture"
Cohesion: 0.28
Nodes (3): AppQuitTests, Overlap, .peak

### Community 88 - "StatusIndicator"
Cohesion: 0.40
Nodes (3): .header, StatusIndicator, .body

### Community 89 - "GoogleAccountField"
Cohesion: 0.29
Nodes (5): ShareBar, .body, .body, TrafficStats, .body

### Community 90 - "Activity"
Cohesion: 0.40
Nodes (5): Activity, connected, downloading, idle, uploading

### Community 92 - "ConnectionEditorField"
Cohesion: 0.25
Nodes (8): config, targets, config, schemes, UnlocalFS, archive, build, run

### Community 94 - "FileActionError"
Cohesion: 0.18
Nodes (10): SFTPAuthentication, agent, .id, password, privateKey, .title, Pane, connection (+2 more)

### Community 99 - "GoogleDriveTests"
Cohesion: 0.29
Nodes (6): name, packages, UnlocalFSCore, settings, targets, path

### Community 100 - "UploadTally"
Cohesion: 0.22
Nodes (7): ViewModelFactory, Build from source, Documentation, Documentation development, Features, Install, License

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
Cohesion: 0.22
Nodes (5): .signInAgainButton, GoogleAccountField, .body, GoogleSignInButton, .body

### Community 115 - "State"
Cohesion: 0.50
Nodes (4): package, config, targets, test

## Knowledge Gaps
- **283 isolated node(s):** `.activity`, `.canDisconnectAll`, `idle`, `connected`, `uploading` (+278 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 669 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **47 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Connection` connect `.mount` to `withControl`, `ConnectionStore`, `DriveGateway`, `UnixConnection`, `Connection`, `.validate`, `MountStatus`, `AppViewModel`, `.shareLink`, `ViewModelFixture`, `.gcs`, `TrafficViewModelTests`, `MacOSDesktopServices`, `withControl`, `ViewModelFixture`, `.refresh`, `MountService`, `UploadCleanup`, `Equatable`, `AppError`, `.connect`, `.sftp`, `ViewModelFixture`, `Date`, `QuitUseCase`, `MountService`, `.status`, `AppError`, `ServerTrustChallenge`, `AppViewModel`, `SFTPFixture`, `.remove`, `ActivityViewModel`, `.control`, `.refresh`, `ServiceAccountKey`, `.execute`, `.runBackendCommand`, `ServerTrustChallenge`, `SavedConnectionRepository`, `MainView`, `SFTPAuthentication`, `ControlServer`, `Sendable`, `Drive.swift`, `SFTPSettings`, `ShareLinkExpiry`, `.execute`, `Traffic`, `FakeDrive`, `.update`, `.status`, `MainView`?**
  _High betweenness centrality (0.260) - this node is a cross-community bridge._
- **Are the 9 inferred relationships involving `Connection` (e.g. with `AWSSettings` and `GCSSettings`) actually correct?**
  _`Connection` has 9 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.activity`, `.canDisconnectAll`, `idle` to the rest of the system?**
  _283 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `withControl` be split into smaller, more focused modules?**
  _Cohesion score 0.102322206095791 - nodes in this community are weakly interconnected._
- **Why does `Foundation` connect `Connection` to `Decodable`, `DriveGateway`, `.validate`, `.s3`, `.shareLink`, `AppViewModel`, `TrafficViewModelTests`, `ViewModelFixture`, `Decision`, `Equatable`, `AppError`, `Date`, `QuitUseCase`, `ServerTrustChallenge`, `SFTPFixture`, `Darwin`, `FileActivity`, `ServiceAccountKey`, `SFTPAuthentication`, `SFTPSettings`, `ShareLinkExpiry`, `.connect`, `UploadTally`, `GoogleSignIn`, `FileActionError`, `State`, `Command.swift`, `UploadCleanup`, `ClosedRange<Date>`?**
  _High betweenness centrality (0.085) - this node is a cross-community bridge._
- **Are the 33 inferred relationships involving `Credentials` (e.g. with `.delete()` and `ConnectionEditorViewModel`) actually correct?**
  _`Credentials` has 33 INFERRED edges - model-reasoned connections that need verification._
- **Should `Decodable` be split into smaller, more focused modules?**
  _Cohesion score 0.06779661016949153 - nodes in this community are weakly interconnected._