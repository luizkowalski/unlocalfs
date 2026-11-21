# Graph Report - unlocalfs  (2026-11-21)

## Corpus Check
- 170 files · ~49,582 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 12 file(s) not represented in the graph (top: .xcstrings 5, (none) 3, .resolved 1)

## Summary
- 2157 nodes · 5331 edges · 121 communities (93 shown, 28 thin omitted)
- Extraction: 81% EXTRACTED · 19% INFERRED · 0% AMBIGUOUS · INFERRED: 1005 edges (avg confidence: 0.85)
- Token cost: 289,731 input · 0 output

## Graph Freshness
- Built from commit: `364aec7c`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- withControl
- Decodable
- ConnectionStore
- .mount
- .sftp
- UnixConnection
- Connection
- .validate
- .s3
- ConnectionRepository
- ViewModelFixture
- LocalizedError
- Date
- AppViewModel
- SFTPTrustStore
- .shareLink
- AppViewModel
- .remove
- Credentials
- ServerTrustChallenge
- .gcs
- withControl
- AppDelegate
- Equatable
- withControl
- AppPaths
- .refresh
- MountService
- Decision
- Direction
- RcloneProcess
- AppError
- .update
- MountService
- Keychain
- Date
- Sendable
- AppViewModel
- .serve
- .status
- AppError
- .connect
- ServerTrustChallenge
- .connect
- AppViewModel
- Drive
- .remove
- GoogleToken
- Direction
- TransferSummary
- .refresh
- ServiceAccountKey
- .exportKeepsHostVerificationAndNeedsNoLocalFiles
- .validate
- .runBackendCommand
- ServerTrustChallenge
- .connect
- SidebarSearchField
- SFTPAuthentication
- ActivityViewModel
- TrafficViewModelTests
- LockableCredentialStorage
- MountService
- Drive.swift
- SFTPSettings
- ShareLinkExpiry
- Command.swift
- Decision
- Int64
- Keychain
- .connect
- ActivityStatus
- MenuBarIcon
- QuitUseCase
- TransferSummary
- GoogleSignIn
- GoogleToken
- FileActivity
- SpeedSample
- ConnectionEditorField
- ViewModelFactory
- AppError
- FakeDrive
- ServerTrustChallenge
- .update
- StatusIndicator
- TrafficView.swift
- SpeedChart
- statusBatch
- ConnectionEditorField
- ActivityView
- CaseIterable
- TrafficPreset
- Command.swift
- UnfinishedUpload
- TrafficView.swift
- GoogleDriveTests
- State
- UnfinishedUpload
- .reading
- MainView
- UploadCleanup
- .sample
- Credentials
- QuitUseCase
- ServiceRecoveryTests
- .signInAgain
- S3StorageClass
- MacOSDesktopServices.swift
- Activity
- Indicator
- Drive.swift
- State
- CommandTests.swift
- sftpSettings
- ClosedRange<Date>
- .serve

## God Nodes (most connected - your core abstractions)
1. `Connection` - 229 edges
2. `UnlocalFSDomain` - 109 edges
3. `Credentials` - 98 edges
4. `MountService` - 91 edges
5. `ViewModelFixture` - 84 edges
6. `DriveGateway` - 52 edges
7. `FileActivity` - 50 edges
8. `AppViewModel` - 49 edges
9. `ConnectionEditorViewModel` - 48 edges
10. `UnlocalFSPresentation` - 46 edges

## Surprising Connections (you probably didn't know these)
- `Build from source` --references--> `ViewModelFactory`  [INFERRED]
  README.md → Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/ViewModelFactory.swift
- `.body` --references--> `Provider`  [INFERRED]
  UnlocalFS/Presentation/Provider+Logo.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `.selected` --references--> `Connection`  [INFERRED]
  Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/AppViewModel.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `ActivityView` --references--> `Connection`  [EXTRACTED]
  UnlocalFS/Presentation/Activity/ActivityView.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `ConnectionDetail` --references--> `Connection`  [EXTRACTED]
  UnlocalFS/Presentation/Connections/ConnectionDetail.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift

## Import Cycles
- None detected.

## Communities (121 total, 28 thin omitted)

### Community 0 - "withControl"
Cohesion: 0.15
Nodes (3): AppPollingTests, AppViewModelTests, TestDesktopServices

### Community 1 - "Decodable"
Cohesion: 0.06
Nodes (45): DriveAbout, User, UploadTally, BatchResult, CodingKeys, error, ControlSnapshot, CodingKeys (+37 more)

### Community 2 - "ConnectionStore"
Cohesion: 0.20
Nodes (3): ConnectionStore, configURL(), ConnectionTests

### Community 3 - ".mount"
Cohesion: 0.05
Nodes (13): Connection, .backend, .bucketPath, .exportsRcloneConfig, .storageName, .usesGoogleSignIn, .usesUploadTimes, .driveStorage (+5 more)

### Community 4 - ".sftp"
Cohesion: 0.20
Nodes (3): SaveConnectionUseCase, withWorkflowFixture(), WorkflowTests

### Community 5 - "UnixConnection"
Cohesion: 0.09
Nodes (4): GCSDriveTests, GoogleDriveValidationTests, AppSignInTests, GoogleSignInEditorTests

### Community 6 - "Connection"
Cohesion: 0.08
Nodes (7): Foundation, GRDB, Observation, String, .expandingTilde, Security, UnlocalFSDomain

### Community 7 - ".validate"
Cohesion: 0.08
Nodes (13): .serviceAccountEmail, ServiceAccountKey, String, .isBlank, ValidationResult, .fieldErrors, Issue, .isValid (+5 more)

### Community 8 - ".s3"
Cohesion: 0.11
Nodes (4): Synchronization, Testing, UnlocalFSInfrastructure, UnlocalFSTestSupport

### Community 9 - "ConnectionRepository"
Cohesion: 0.05
Nodes (42): runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, environment, if (+34 more)

### Community 10 - "ViewModelFixture"
Cohesion: 0.13
Nodes (8): ConnectionEditorViewModelTests, ViewModelFixture, .paths, .rcloneCalls, .root, .service, .signInEnvironment, .traffic

### Community 11 - "LocalizedError"
Cohesion: 0.14
Nodes (5): CredentialStorage, SavedConnectionRepository, MemoryCredentialStorage, RepositoryTests, UnavailableCredentialStorage

### Community 12 - "Date"
Cohesion: 0.07
Nodes (32): runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, jobs, build (+24 more)

### Community 13 - "AppViewModel"
Cohesion: 0.11
Nodes (10): AppViewModel, .busy, .isConfirmingDelete, .isShowingDisconnectFailure, .isShowingUploadsBlockingDisconnect, .selected, SidebarItem, drive (+2 more)

### Community 15 - ".shareLink"
Cohesion: 0.11
Nodes (7): DriveTraffic, TrafficDay, TrafficRepository, TrafficStore, .migrator, .total, TrafficStoreTests

### Community 16 - "AppViewModel"
Cohesion: 0.13
Nodes (9): ClosedRange<Date>, DateInterval, TrafficPeriod, custom, last12Months, last30Days, last90Days, date() (+1 more)

### Community 17 - ".remove"
Cohesion: 0.09
Nodes (4): FinderServicesTests, MenuBarActivityTests, SpeedRecordingTests, ControlServers

### Community 18 - "Credentials"
Cohesion: 0.14
Nodes (5): AppKit, Network, SwiftUI, UniformTypeIdentifiers, UnlocalFSPresentation

### Community 19 - "ServerTrustChallenge"
Cohesion: 0.07
Nodes (28): env, runs-on, steps, timeout-minutes, APPLE_ID, GH_TOKEN, GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET (+20 more)

### Community 20 - ".gcs"
Cohesion: 0.11
Nodes (4): DesktopServices, RcloneConfigDestination, MacOSDesktopServices, .opensAtLogin

### Community 21 - "withControl"
Cohesion: 0.08
Nodes (11): mark(), MountSafetyTests, shutdown(), withControl(), withFixture(), failingStatus(), revokedDrive(), ControlFailure (+3 more)

### Community 22 - "AppDelegate"
Cohesion: 0.05
Nodes (17): Notification, AppDelegate, .model, .viewModels, UnlocalFSApp, .body, .driveCommands, .model (+9 more)

### Community 23 - "Equatable"
Cohesion: 0.28
Nodes (4): Traffic, .total, TrafficMeter, TrafficMeterTests

### Community 24 - "withControl"
Cohesion: 0.16
Nodes (13): ConnectionDetail, .actions, .awsDetails, .bucketDetail, .disconnected, .logo, .notices, .sftpDetails (+5 more)

### Community 25 - "AppPaths"
Cohesion: 0.14
Nodes (8): AppPaths, .knownHosts, .sockets, .traffic, MountCommand, .arguments, .environment, .mountParameters

### Community 26 - ".refresh"
Cohesion: 0.16
Nodes (8): TrafficBar, .id, TrafficViewModel, .custom, .period, .recentTotal, .unit, .body

### Community 27 - "MountService"
Cohesion: 0.22
Nodes (6): GoogleSignIn, controlCalls(), ServiceRecoveryTests, withRevokedDrive(), StubbedDrives, .rcloneCalls

### Community 28 - "Decision"
Cohesion: 0.18
Nodes (5): ControlSocket, ControlUnreachable, RcloneError, UnixConnection, .timedOut

### Community 29 - "Direction"
Cohesion: 0.17
Nodes (7): Direction, .color, download, .fill, .label, .symbol, upload

### Community 30 - "RcloneProcess"
Cohesion: 0.17
Nodes (5): RcloneProcess, TrafficCheckpoint, .unsaved, TrafficReading, TrafficSave

### Community 31 - "AppError"
Cohesion: 0.10
Nodes (20): Provider, aws, .backend, cloudflare, digitalOcean, googleCloudStorage, googleDrive, .group (+12 more)

### Community 33 - "MountService"
Cohesion: 0.11
Nodes (3): MountService, .baseEnvironment, TrafficTracker

### Community 35 - "Date"
Cohesion: 0.29
Nodes (7): Date, DayCell, .body, MonthGrid, .body, TrafficRangePicker, .body

### Community 36 - "Sendable"
Cohesion: 0.13
Nodes (11): ConnectionRepository, DeleteConnectionUseCase, ConnectDriveUseCase, Outcome, connected, ejected, SignInAgainUseCase, DuplicateFilesUseCase (+3 more)

### Community 37 - "AppViewModel"
Cohesion: 0.20
Nodes (3): Launch, requireOutput(), S3Server

### Community 38 - ".serve"
Cohesion: 0.09
Nodes (4): ActivityViewModelTests, AppQuitTests, Overlap, .peak

### Community 39 - ".status"
Cohesion: 0.09
Nodes (14): ConnectionEditorViewModel, .connection, .credentials, .fieldErrors, .firstInvalidField, .initialFocus, .isLocked, .locksRemoteFolder (+6 more)

### Community 40 - "AppError"
Cohesion: 0.24
Nodes (3): AppViewModel, .activity, .canDisconnectAll

### Community 41 - ".connect"
Cohesion: 0.11
Nodes (19): ConnectionField, accessKey, bucket, confirmation, .displayName, encryptionPassword, endpoint, folder (+11 more)

### Community 42 - "ServerTrustChallenge"
Cohesion: 0.13
Nodes (10): FileActivity, .finishedAt, .id, .isUpload, Sequence<FileActivity>, .folder, .isCancellable, .name (+2 more)

### Community 43 - ".connect"
Cohesion: 0.11
Nodes (14): DriveCondition, checking, connected, disconnected, ejected, .indicator, needsAttention, needsReconnect (+6 more)

### Community 44 - "AppViewModel"
Cohesion: 0.25
Nodes (7): BatchReply, .current, counters(), finished(), reply(), TrafficTests, withRclone()

### Community 45 - "Drive"
Cohesion: 0.16
Nodes (9): Drive, .knownHosts, .mounted, dump(), makeDrive(), rclone(), FixtureResources, withFixture() (+1 more)

### Community 46 - ".remove"
Cohesion: 0.19
Nodes (9): SFTPFixture, .agentSocket, .connection, .credentials, .key, .protectedKey, .served, SFTPServer (+1 more)

### Community 47 - "GoogleToken"
Cohesion: 0.08
Nodes (13): .isSignedInToGoogle, .secrets, FileActionError, GoogleAccountChanged, .errorDescription, GoogleSignInRequired, .errorDescription, GoogleToken (+5 more)

### Community 48 - "Direction"
Cohesion: 0.17
Nodes (7): ActivityViewModel, .refreshInterval, UploadCancellation, .fileName, .message, .title, .body

### Community 51 - ".refresh"
Cohesion: 0.16
Nodes (13): GoogleClient, NamedRemote, Options, RcloneRemote, .cryptOptions, .driveOptions, .environment, .gcsOptions (+5 more)

### Community 52 - "ServiceAccountKey"
Cohesion: 0.12
Nodes (15): AWSSettings, .customKMSKey, S3StorageClass, glacierInstantRetrieval, .id, intelligentTiering, oneZoneInfrequentAccess, standard (+7 more)

### Community 53 - ".exportKeepsHostVerificationAndNeedsNoLocalFiles"
Cohesion: 0.11
Nodes (8): .signInAgainButton, GCSConnectionFields, .body, .serviceAccountField, GoogleAccountField, .body, GoogleSignInButton, .body

### Community 55 - ".runBackendCommand"
Cohesion: 0.14
Nodes (12): Backend, gcs, googleDrive, .locksFolderAfterSave, s3Compatible, sftp, .supportsMultiThreadUploads, .supportsServerCopy (+4 more)

### Community 56 - "ServerTrustChallenge"
Cohesion: 0.16
Nodes (3): CancelUploadTests, TrafficViewModelTests, .yesterday

### Community 58 - "SidebarSearchField"
Cohesion: 0.15
Nodes (8): MainView, .detail, .sidebar, FocusedValues, SidebarSearchField, .body, TrafficRow, .body

### Community 59 - "SFTPAuthentication"
Cohesion: 0.27
Nodes (7): GCSAuthentication, googleAccount, .id, serviceAccount, .title, GCSSettings, Config

### Community 62 - "ActivityViewModel"
Cohesion: 0.18
Nodes (3): DriveGateway, GoogleSignInRun, .isRunning

### Community 63 - "TrafficViewModelTests"
Cohesion: 0.15
Nodes (13): ARCHS, ASSETCATALOG_COMPILER_APPICON_NAME, CODE_SIGN_STYLE, CURRENT_PROJECT_VERSION, ENABLE_HARDENED_RUNTIME, ENABLE_USER_SCRIPT_SANDBOXING, INFOPLIST_FILE, MARKETING_VERSION (+5 more)

### Community 65 - "MountService"
Cohesion: 0.21
Nodes (7): SFTPDriveTests, SFTPLogin, agent, key, password, protectedKey, withSFTPDrive()

### Community 66 - "Drive.swift"
Cohesion: 0.18
Nodes (3): FakeStorage, .uploadCount, UploadCleanupTests

### Community 67 - "SFTPSettings"
Cohesion: 0.20
Nodes (9): ProviderGroup, generic, google, s3Services, .providerSections, Pane, connection, .displayName (+1 more)

### Community 68 - "ShareLinkExpiry"
Cohesion: 0.29
Nodes (3): ConnectionDraft, .id, .isDuplicate

### Community 70 - "Decision"
Cohesion: 0.13
Nodes (5): MountStatus, .isActive, .isServing, .needsReconnect, ConnectionRulesTests

### Community 71 - "Int64"
Cohesion: 0.33
Nodes (3): ConnectionEditor, .advancedSection, .editor

### Community 74 - "ActivityStatus"
Cohesion: 0.22
Nodes (7): ActivityStatus, .body, .movingText, .progress, FailedUploadButton, .body, .details

### Community 75 - "MenuBarIcon"
Cohesion: 0.27
Nodes (4): SFTPConnectionFields, .authenticationHelp, .authenticationSection, .body

### Community 76 - "QuitUseCase"
Cohesion: 0.14
Nodes (6): QuitUseCase, Decision, disconnect, quit, wait, AppViewModel

### Community 77 - "TransferSummary"
Cohesion: 0.20
Nodes (9): interval, time, timezone, updates, directory, open-pull-requests-limit, package-ecosystem, schedule (+1 more)

### Community 79 - "GoogleToken"
Cohesion: 0.22
Nodes (6): ShareLinkExpiry, day, hour, .title, week, AppViewModel

### Community 80 - "FileActivity"
Cohesion: 0.17
Nodes (5): AppAlert, AppViewModel, UploadCleanup, .message, .title

### Community 81 - "SpeedSample"
Cohesion: 0.20
Nodes (10): Debug, Release, package, product, UnlocalFS, configFiles, dependencies, platform (+2 more)

### Community 82 - "ConnectionEditorField"
Cohesion: 0.11
Nodes (12): ConnectionBucketFields, .body, ConnectionEditorField, .body, ConnectionIdentityFields, .body, .providerPicker, GoogleDriveConnectionFields (+4 more)

### Community 83 - "ViewModelFactory"
Cohesion: 0.18
Nodes (8): ViewModelFactory, Build from source, Documentation, Documentation development, Features, Install, License, .body

### Community 86 - "ServerTrustChallenge"
Cohesion: 0.26
Nodes (3): ServerTrustChallenge, .errorDescription, .server

### Community 88 - "StatusIndicator"
Cohesion: 0.22
Nodes (7): .header, DriveManagementItems, .body, ConnectionRow, .body, StatusIndicator, .body

### Community 89 - "TrafficView.swift"
Cohesion: 0.15
Nodes (12): ShareBar, .body, TrafficChart, TrafficList, .body, TrafficStats, .body, TrafficView (+4 more)

### Community 90 - "SpeedChart"
Cohesion: 0.36
Nodes (3): SpeedChart, .body, .selectedSample

### Community 92 - "ConnectionEditorField"
Cohesion: 0.25
Nodes (8): config, targets, config, schemes, UnlocalFS, archive, build, run

### Community 93 - "ActivityView"
Cohesion: 0.20
Nodes (7): ActivityFileName, .body, ActivityTable, .body, ActivityView, .activity, .idle

### Community 94 - "CaseIterable"
Cohesion: 0.15
Nodes (9): SFTPAuthentication, agent, .id, password, privateKey, .title, SFTPSettings, .agentSocketPath (+1 more)

### Community 95 - "TrafficPreset"
Cohesion: 0.22
Nodes (8): TrafficPreset, last7Days, lastMonth, thisMonth, thisYear, today, yesterday, .title

### Community 96 - "Command.swift"
Cohesion: 0.29
Nodes (6): ActivitySnapshot, checking, .files, idle, transfers, unavailable

### Community 97 - "UnfinishedUpload"
Cohesion: 0.29
Nodes (4): SpeedSample, .axisLimit, .fastestDownload, .fastestUpload

### Community 98 - "TrafficView.swift"
Cohesion: 0.33
Nodes (5): Charts, ClosedRange<Date>, .formattedDays, DateInterval, .formattedDays

### Community 99 - "GoogleDriveTests"
Cohesion: 0.29
Nodes (6): name, packages, UnlocalFSCore, settings, targets, path

### Community 100 - "State"
Cohesion: 0.29
Nodes (7): State, downloaded, downloading, failed, queued, uploaded, uploading

### Community 103 - "MainView"
Cohesion: 0.25
Nodes (3): AppViewModel, .showsTraffic, .visibleConnections

### Community 106 - "Credentials"
Cohesion: 0.15
Nodes (6): Credentials, .encryptionPassword, .googleSignIn, .keyPassphrase, .password, MemoryCredentialStorage

### Community 107 - "QuitUseCase"
Cohesion: 0.33
Nodes (6): copyFiles, destination, subpath, buildPhase, path, sources

### Community 109 - ".signInAgain"
Cohesion: 0.40
Nodes (5): macOS, options, deploymentTarget, postGenCommand, projectFileFormat

### Community 110 - "S3StorageClass"
Cohesion: 0.40
Nodes (5): basedOnDependencyAnalysis, name, script, shell, postBuildScripts

### Community 111 - "MacOSDesktopServices.swift"
Cohesion: 0.40
Nodes (3): OSLog, ServiceManagement, UserNotifications

### Community 112 - "Activity"
Cohesion: 0.40
Nodes (5): Activity, connected, downloading, idle, uploading

### Community 113 - "Indicator"
Cohesion: 0.40
Nodes (5): Indicator, attention, connected, idle, working

### Community 114 - "Drive.swift"
Cohesion: 0.17
Nodes (5): Darwin, RcloneState, running, stopped, untracked

### Community 115 - "State"
Cohesion: 0.50
Nodes (4): package, config, targets, test

## Knowledge Gaps
- **284 isolated node(s):** `PackageDescription`, `standard`, `intelligentTiering`, `standardInfrequentAccess`, `oneZoneInfrequentAccess` (+279 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 653 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **28 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Connection` connect `.mount` to `withControl`, `ConnectionStore`, `.sftp`, `UnixConnection`, `Connection`, `.validate`, `ViewModelFixture`, `AppViewModel`, `.shareLink`, `.gcs`, `withControl`, `AppDelegate`, `withControl`, `AppPaths`, `.refresh`, `MountService`, `RcloneProcess`, `.update`, `MountService`, `Sendable`, `.serve`, `.status`, `AppError`, `AppViewModel`, `Drive`, `.remove`, `Direction`, `.control`, `.refresh`, `ServiceAccountKey`, `.runBackendCommand`, `ServerTrustChallenge`, `.connect`, `SFTPAuthentication`, `AppError`, `.remote`, `Drive.swift`, `ShareLinkExpiry`, `Decision`, `QuitUseCase`, `FileActivity`, `AppError`, `FakeDrive`, `StatusIndicator`, `ActivityView`, `CaseIterable`, `MainView`?**
  _High betweenness centrality (0.307) - this node is a cross-community bridge._
- **Are the 9 inferred relationships involving `Connection` (e.g. with `AWSSettings` and `GCSSettings`) actually correct?**
  _`Connection` has 9 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `standard`, `intelligentTiering` to the rest of the system?**
  _284 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `withControl` be split into smaller, more focused modules?**
  _Cohesion score 0.14616755793226383 - nodes in this community are weakly interconnected._
- **Why does `Foundation` connect `Connection` to `Decodable`, `.validate`, `.s3`, `.shareLink`, `AppPaths`, `Decision`, `RcloneProcess`, `Sendable`, `ServerTrustChallenge`, `AppViewModel`, `GoogleToken`, `TransferSummary`, `ServiceAccountKey`, `SFTPAuthentication`, `ActivityViewModel`, `ShareLinkExpiry`, `Command.swift`, `.connect`, `QuitUseCase`, `GoogleSignIn`, `AppError`, `ServerTrustChallenge`, `CaseIterable`, `UnfinishedUpload`, `UploadCleanup`, `MacOSDesktopServices.swift`, `Drive.swift`, `CommandTests.swift`, `ClosedRange<Date>`?**
  _High betweenness centrality (0.067) - this node is a cross-community bridge._
- **Are the 33 inferred relationships involving `Credentials` (e.g. with `.delete()` and `ConnectionEditorViewModel`) actually correct?**
  _`Credentials` has 33 INFERRED edges - model-reasoned connections that need verification._
- **Should `Decodable` be split into smaller, more focused modules?**
  _Cohesion score 0.06101190476190476 - nodes in this community are weakly interconnected._