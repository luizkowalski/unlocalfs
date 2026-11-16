# Graph Report - unlocalfs  (2026-11-16)

## Corpus Check
- 168 files · ~48,938 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 12 file(s) not represented in the graph (top: .xcstrings 5, (none) 3, .resolved 1)

## Summary
- 2162 nodes · 5275 edges · 144 communities (91 shown, 53 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 945 edges (avg confidence: 0.85)
- Token cost: 289,731 input · 0 output

## Graph Freshness
- Built from commit: `20d6b07d`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- withControl
- Decodable
- Connection
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
- .recordTraffic
- .execute
- ActivityView
- .post
- AppSearchTests
- StubbedDrives
- FixtureResources
- ViewModelFixture
- withRclone
- ShareBar
- RcloneRemote
- ViewModelFactory
- ConnectionField
- ConnectionDraft
- .connect
- ServiceAccountKey
- .validate
- CredentialStorage
- SFTPFixture
- .remove
- ActivityViewModel
- ActivityViewModel
- AppViewModel
- AppSearchTests
- MountService
- .connect
- .control
- Decision
- SFTPTrustStore
- ServerTrustChallenge
- withS3Drive
- S3StorageClass
- GoogleSignInRequired
- MenuBarIcon
- ControlServer
- SpeedSample
- .remove
- .serve
- base
- Date
- Backend
- GoogleSignInRun
- GoogleSignInRun
- SFTPLogin
- .connect
- ConnectionDraft
- .refresh
- GCSConnectionFields
- withRclone
- project.yml
- .mount
- updates
- .copyShareLinks
- SFTPAuthentication
- SFTPSettings
- Traffic
- SFTPConnectionFields
- .recordTraffic
- .run
- ServerTrustChallenge
- ProviderIcon
- TrafficView
- DriveGateway
- GCSAuthentication
- MountCommand
- DriveAboutProtocol
- GoogleSignInButton
- SpeedSample
- waitUntil
- README.md
- GoogleDriveTests
- RcloneRemote
- README.md
- .body
- AppViewModel
- .execute
- UploadCleanup
- RcloneState
- ServiceRecoveryTests
- .deleteFileToStopUpload
- Activity
- GoogleToken
- Indicator
- PackageDescription
- RcloneRemote.swift
- ConnectionValidationTests.swift
- .interval
- .gcs
- TrafficPeriod
- TrafficView
- State
- UnfinishedUpload
- MainView
- MacOSDesktopServices.swift
- Notification
- Command.swift

## God Nodes (most connected - your core abstractions)
1. `Connection` - 151 edges
2. `UnlocalFSDomain` - 109 edges
3. `Credentials` - 94 edges
4. `MountService` - 91 edges
5. `ViewModelFixture` - 81 edges
6. `DriveGateway` - 52 edges
7. `FileActivity` - 50 edges
8. `AppViewModel` - 49 edges
9. `ConnectionEditorViewModel` - 47 edges
10. `ConnectionField` - 46 edges

## Surprising Connections (you probably didn't know these)
- `Build from source` --references--> `ViewModelFactory`  [INFERRED]
  README.md → Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/ViewModelFactory.swift
- `.body` --calls--> `Connection`  [INFERRED]
  UnlocalFS/Application/UnlocalFSApp.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `ConnectionBucketFields` --references--> `ConnectionEditorViewModel`  [EXTRACTED]
  UnlocalFS/Presentation/Connections/ConnectionBucketFields.swift → Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/ConnectionEditorViewModel.swift
- `ConnectionEditor` --references--> `ConnectionEditorViewModel`  [EXTRACTED]
  UnlocalFS/Presentation/Connections/ConnectionEditor.swift → Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/ConnectionEditorViewModel.swift
- `ConnectionIdentityFields` --references--> `ConnectionEditorViewModel`  [EXTRACTED]
  UnlocalFS/Presentation/Connections/ConnectionIdentityFields.swift → Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/ConnectionEditorViewModel.swift

## Import Cycles
- None detected.

## Communities (144 total, 53 thin omitted)

### Community 0 - "withControl"
Cohesion: 0.17
Nodes (6): mark(), MountSafetyTests, shutdown(), withControl(), withFixture(), statusBatch()

### Community 1 - "Decodable"
Cohesion: 0.08
Nodes (39): DriveAbout, User, BatchResult, CodingKeys, bytes, completedAt, dstFs, error (+31 more)

### Community 3 - "Connection"
Cohesion: 0.12
Nodes (7): Connection, .backend, .bucketPath, .exportsRcloneConfig, .folderPath, .usesGoogleSignIn, .usesUploadTimes

### Community 4 - ".validate"
Cohesion: 0.08
Nodes (5): Foundation, GRDB, Observation, Security, UnlocalFSDomain

### Community 5 - "MountService"
Cohesion: 0.05
Nodes (42): runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, environment, if (+34 more)

### Community 6 - "Sendable"
Cohesion: 0.10
Nodes (9): AppSignInTests, GoogleSignInEditorTests, ViewModelFixture, .paths, .rcloneCalls, .root, .service, .signInEnvironment (+1 more)

### Community 7 - "TrafficViewModel"
Cohesion: 0.19
Nodes (7): TrafficBar, .id, TrafficViewModel, .custom, .period, .recentTotal, .unit

### Community 8 - ".s3"
Cohesion: 0.10
Nodes (10): AppKit, Charts, Network, SwiftUI, UniformTypeIdentifiers, ClosedRange<Date>, .formattedDays, DateInterval (+2 more)

### Community 9 - "steps"
Cohesion: 0.06
Nodes (35): env, runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, DEVELOPER_DIR (+27 more)

### Community 10 - "MountStatus"
Cohesion: 0.11
Nodes (5): MountStatus, .isActive, .isServing, .needsReconnect, ConnectionRulesTests

### Community 11 - "LocalizedError"
Cohesion: 0.14
Nodes (4): Synchronization, Testing, UnlocalFSInfrastructure, UnlocalFSTestSupport

### Community 12 - "Credentials"
Cohesion: 0.11
Nodes (11): ConnectionRepository, DeleteConnectionUseCase, SetAutomaticConnectUseCase, ConnectDriveUseCase, Outcome, connected, ejected, SignInAgainUseCase (+3 more)

### Community 13 - "MountService"
Cohesion: 0.15
Nodes (6): AppPaths, .knownHosts, .sockets, .traffic, .knownHosts, .mounted

### Community 14 - "TrafficPreset"
Cohesion: 0.12
Nodes (15): Backend, .rcloneType, Connection, .driveStorage, .driveTarget, .rclonePath, .rcloneType, .storageRemoteName (+7 more)

### Community 15 - "TrafficPreset"
Cohesion: 0.15
Nodes (10): TrafficPreset, last7Days, lastMonth, thisMonth, thisYear, today, yesterday, date() (+2 more)

### Community 16 - "AppViewModel"
Cohesion: 0.20
Nodes (3): SaveConnectionUseCase, withWorkflowFixture(), WorkflowTests

### Community 17 - "ConnectionStore"
Cohesion: 0.07
Nodes (29): env, runs-on, steps, timeout-minutes, APPLE_ID, DEVELOPER_DIR, GH_TOKEN, GOOGLE_CLIENT_ID (+21 more)

### Community 18 - ".sftp"
Cohesion: 0.10
Nodes (8): AppViewModel, .busy, .isConfirmingDelete, .isShowingAlert, .isShowingDisconnectFailure, .isShowingUploadsBlockingDisconnect, .selected, .unsavedTraffic

### Community 20 - ".gcs"
Cohesion: 0.13
Nodes (4): DesktopServices, RcloneConfigDestination, MacOSDesktopServices, .opensAtLogin

### Community 22 - "MacOSDesktopServices"
Cohesion: 0.14
Nodes (5): Credentials, .encryptionPassword, .keyPassphrase, .password, ConnectionEditorViewModelTests

### Community 23 - "Equatable"
Cohesion: 0.18
Nodes (5): RcloneProcess, TrafficCheckpoint, .unsaved, TrafficReading, TrafficSave

### Community 24 - "withControl"
Cohesion: 0.11
Nodes (6): ExportRcloneConfigUseCase, CredentialStorage, SavedConnectionRepository, MemoryCredentialStorage, RepositoryTests, UnavailableCredentialStorage

### Community 26 - "ConnectionDetail"
Cohesion: 0.14
Nodes (3): AppDelegate, .model, .viewModels

### Community 28 - ".execute"
Cohesion: 0.09
Nodes (15): DriveCondition, checking, connected, disconnected, ejected, .indicator, needsAttention, needsReconnect (+7 more)

### Community 29 - "ActivityView"
Cohesion: 0.20
Nodes (7): ActivityFileName, .body, ActivityTable, .body, ActivityView, .activity, .idle

### Community 30 - ".post"
Cohesion: 0.10
Nodes (10): FileActionError, DriveEjectError, .errorDescription, UploadsPendingError, .errorDescription, ControlSocket, ControlUnreachable, RcloneError (+2 more)

### Community 32 - "StubbedDrives"
Cohesion: 0.15
Nodes (14): ConnectionDetail, .actions, .awsDetails, .body, .bucketDetail, .disconnected, .logo, .notices (+6 more)

### Community 33 - "FixtureResources"
Cohesion: 0.13
Nodes (10): Direction, .color, download, .fill, .label, .symbol, upload, SpeedChart (+2 more)

### Community 34 - "ViewModelFixture"
Cohesion: 0.11
Nodes (7): DriveTraffic, TrafficDay, TrafficRepository, TrafficStore, .migrator, .total, TrafficStoreTests

### Community 35 - "withRclone"
Cohesion: 0.09
Nodes (20): ConnectionField, accessKey, bucket, confirmation, .displayName, encryptionPassword, endpoint, folder (+12 more)

### Community 36 - "ShareBar"
Cohesion: 0.22
Nodes (4): RcloneState, running, stopped, untracked

### Community 37 - "RcloneRemote"
Cohesion: 0.14
Nodes (6): GoogleSignIn, controlCalls(), LockableCredentialStorage, withRevokedDrive(), StubbedDrives, .rcloneCalls

### Community 38 - "ViewModelFactory"
Cohesion: 0.14
Nodes (11): ConnectionEditorViewModel, .availableProviders, .connection, .credentials, .fieldErrors, .firstInvalidField, .initialFocus, .isLocked (+3 more)

### Community 39 - "ConnectionField"
Cohesion: 0.17
Nodes (4): FixtureResources, Launch, requireOutput(), withFixture()

### Community 40 - "ConnectionDraft"
Cohesion: 0.29
Nodes (3): ConnectionDraft, .id, .isDuplicate

### Community 42 - "ServiceAccountKey"
Cohesion: 0.12
Nodes (15): Provider, aws, .backend, cloudflare, digitalOcean, googleCloudStorage, googleDrive, .id (+7 more)

### Community 43 - ".validate"
Cohesion: 0.06
Nodes (14): .serviceAccountEmail, ServiceAccountKey, Issue, String, .isBlank, ValidationResult, .fieldErrors, .isValid (+6 more)

### Community 44 - "CredentialStorage"
Cohesion: 0.13
Nodes (10): FileActivity, .finishedAt, .id, .isUpload, Sequence<FileActivity>, .folder, .isCancellable, .name (+2 more)

### Community 46 - ".remove"
Cohesion: 0.18
Nodes (3): FakeStorage, .uploadCount, UploadCleanupTests

### Community 48 - "ActivityViewModel"
Cohesion: 0.17
Nodes (6): ActivityViewModel, .refreshInterval, UploadCancellation, .message, .title, .body

### Community 49 - "ActivityViewModel"
Cohesion: 0.21
Nodes (4): Config, ConnectionStore, configURL(), ConnectionTests

### Community 50 - "AppViewModel"
Cohesion: 0.21
Nodes (6): Drive, dump(), makeDrive(), rclone(), verifyRoundTrip(), waitUntil()

### Community 51 - "AppSearchTests"
Cohesion: 0.21
Nodes (9): SFTPFixture, .agentSocket, .connection, .credentials, .key, .protectedKey, .served, SFTPServer (+1 more)

### Community 52 - "MountService"
Cohesion: 0.14
Nodes (3): Darwin, MountService, .baseEnvironment

### Community 53 - ".connect"
Cohesion: 0.14
Nodes (10): ConnectionBucketFields, .body, ConnectionEditorField, .body, ConnectionIdentityFields, .body, GoogleDriveConnectionFields, .body (+2 more)

### Community 54 - ".control"
Cohesion: 0.09
Nodes (14): .header, DriveManagementItems, .body, ConnectionRow, .body, .icon, .sidebar, FocusedValues (+6 more)

### Community 55 - "Decision"
Cohesion: 0.40
Nodes (4): Decision, disconnect, quit, wait

### Community 58 - "withS3Drive"
Cohesion: 0.22
Nodes (3): S3DriveTests, S3Server, withS3Drive()

### Community 60 - "S3StorageClass"
Cohesion: 0.12
Nodes (14): AWSSettings, S3StorageClass, glacierInstantRetrieval, .id, intelligentTiering, oneZoneInfrequentAccess, standard, standardInfrequentAccess (+6 more)

### Community 61 - "GoogleSignInRequired"
Cohesion: 0.13
Nodes (9): UnlocalFSApp, .body, MenuBarIcon, .accessibilityValue, .animatesUploads, .body, .image, MenuContent (+1 more)

### Community 63 - "ControlServer"
Cohesion: 0.17
Nodes (4): revokedDrive(), ControlFailure, ControlRequest, ControlServer

### Community 64 - "SpeedSample"
Cohesion: 0.18
Nodes (5): SpeedSample, .axisLimit, .fastestDownload, .fastestUpload, SpeedSampleTests

### Community 65 - ".remove"
Cohesion: 0.08
Nodes (5): AppPollingTests, FinderServicesTests, MenuBarActivityTests, SpeedRecordingTests, ControlServers

### Community 67 - "base"
Cohesion: 0.15
Nodes (13): ARCHS, ASSETCATALOG_COMPILER_APPICON_NAME, CODE_SIGN_STYLE, CURRENT_PROJECT_VERSION, ENABLE_HARDENED_RUNTIME, ENABLE_USER_SCRIPT_SANDBOXING, INFOPLIST_FILE, MARKETING_VERSION (+5 more)

### Community 68 - "Date"
Cohesion: 0.29
Nodes (7): Date, DayCell, .body, MonthGrid, .body, TrafficRangePicker, .body

### Community 69 - "Backend"
Cohesion: 0.15
Nodes (11): Backend, gcs, googleDrive, .locksFolderAfterSave, s3Compatible, sftp, .supportsMultiThreadUploads, .supportsServerCopy (+3 more)

### Community 70 - "GoogleSignInRun"
Cohesion: 0.14
Nodes (3): AppViewModel, GoogleSignInRun, .isRunning

### Community 71 - "GoogleSignInRun"
Cohesion: 0.21
Nodes (7): SFTPDriveTests, SFTPLogin, agent, key, password, protectedKey, withSFTPDrive()

### Community 72 - "SFTPLogin"
Cohesion: 0.12
Nodes (8): .signInAgainButton, GCSConnectionFields, .body, .serviceAccountField, GoogleAccountField, .body, GoogleSignInButton, .body

### Community 74 - "ConnectionDraft"
Cohesion: 0.28
Nodes (3): AppQuitTests, Overlap, .peak

### Community 75 - ".refresh"
Cohesion: 0.18
Nodes (10): macOS, name, options, deploymentTarget, postGenCommand, packages, UnlocalFSCore, settings (+2 more)

### Community 76 - "GCSConnectionFields"
Cohesion: 0.22
Nodes (7): ActivityStatus, .body, .movingText, .progress, FailedUploadButton, .body, .details

### Community 77 - "withRclone"
Cohesion: 0.22
Nodes (7): BatchReply, .current, counters(), finished(), reply(), TrafficTests, withRclone()

### Community 78 - "project.yml"
Cohesion: 0.20
Nodes (9): interval, time, timezone, updates, directory, open-pull-requests-limit, package-ecosystem, schedule (+1 more)

### Community 82 - "SFTPAuthentication"
Cohesion: 0.12
Nodes (11): SFTPAuthentication, agent, .id, password, privateKey, .title, SFTPSettings, Pane (+3 more)

### Community 83 - "SFTPSettings"
Cohesion: 0.20
Nodes (10): Debug, Release, package, product, UnlocalFS, configFiles, dependencies, platform (+2 more)

### Community 84 - "Traffic"
Cohesion: 0.32
Nodes (4): Traffic, .total, TrafficMeter, TrafficMeterTests

### Community 85 - "SFTPConnectionFields"
Cohesion: 0.29
Nodes (4): SFTPConnectionFields, .authenticationHelp, .authenticationSection, .body

### Community 86 - ".recordTraffic"
Cohesion: 0.20
Nodes (3): AppError, Command, CommandTests

### Community 88 - "ServerTrustChallenge"
Cohesion: 0.22
Nodes (3): ServerTrustChallenge, .errorDescription, .server

### Community 89 - "ProviderIcon"
Cohesion: 0.14
Nodes (10): Provider, .logo, ProviderIcon, .body, ShareBar, .body, TrafficList, .body (+2 more)

### Community 90 - "TrafficView"
Cohesion: 0.25
Nodes (8): config, targets, config, schemes, UnlocalFS, archive, build, run

### Community 91 - "DriveGateway"
Cohesion: 0.09
Nodes (7): DriveGateway, QuitUseCase, ShareLinkExpiry, day, hour, .title, week

### Community 92 - "GCSAuthentication"
Cohesion: 0.21
Nodes (6): GCSAuthentication, googleAccount, .id, serviceAccount, .title, GCSSettings

### Community 93 - "MountCommand"
Cohesion: 0.25
Nodes (3): MountCommand, .environment, .mountParameters

### Community 95 - "GoogleSignInButton"
Cohesion: 0.29
Nodes (6): ActivitySnapshot, checking, .files, idle, transfers, unavailable

### Community 98 - "README.md"
Cohesion: 0.33
Nodes (6): copyFiles, destination, subpath, buildPhase, path, sources

### Community 100 - "RcloneRemote"
Cohesion: 0.18
Nodes (11): GoogleSignInRequired, .errorDescription, GoogleClient, RcloneRemote, .cryptOptions, .driveOptions, .environment, .gcsOptions (+3 more)

### Community 101 - "README.md"
Cohesion: 0.22
Nodes (7): ViewModelFactory, Build from source, Documentation, Documentation development, Features, Install, License

### Community 102 - ".body"
Cohesion: 0.17
Nodes (5): ConnectionEditor, .advancedSection, .body, ServerTrustSheet, .body

### Community 104 - ".execute"
Cohesion: 0.33
Nodes (5): Indicator, attention, connected, idle, working

### Community 105 - "UploadCleanup"
Cohesion: 0.24
Nodes (4): AppViewModel, UploadCleanup, .message, .title

### Community 106 - "RcloneState"
Cohesion: 0.40
Nodes (5): basedOnDependencyAnalysis, name, script, shell, postBuildScripts

### Community 108 - ".deleteFileToStopUpload"
Cohesion: 0.50
Nodes (4): package, config, targets, test

### Community 109 - "Activity"
Cohesion: 0.40
Nodes (5): Activity, connected, downloading, idle, uploading

### Community 110 - "GoogleToken"
Cohesion: 0.23
Nodes (6): .isSignedInToGoogle, .secrets, Fields, GoogleAccountChanged, .errorDescription, GoogleToken

### Community 127 - "TrafficPeriod"
Cohesion: 0.20
Nodes (8): SidebarItem, drive, traffic, TrafficPeriod, custom, last12Months, last30Days, last90Days

### Community 128 - "TrafficView"
Cohesion: 0.22
Nodes (7): TrafficChart, .body, TrafficView, .body, .heading, .periodPicker, .title

### Community 129 - "State"
Cohesion: 0.25
Nodes (7): State, downloaded, downloading, failed, queued, uploaded, uploading

### Community 131 - "MainView"
Cohesion: 0.33
Nodes (3): MainView, .body, .detail

### Community 132 - "MacOSDesktopServices.swift"
Cohesion: 0.40
Nodes (3): OSLog, ServiceManagement, UserNotifications

## Knowledge Gaps
- **272 isolated node(s):** `.title`, `.locksRemoteFolder`, `.availableProviders`, `.initialFocus`, `.isLocked` (+267 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 648 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **53 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Connection` connect `Connection` to `.control`, `.deleteFileToStopUpload`, `TrafficViewModel`, `MountStatus`, `Credentials`, `MountService`, `TrafficPreset`, `AppViewModel`, `.sftp`, `.gcs`, `TrafficViewModelTests`, `MacOSDesktopServices`, `Equatable`, `withControl`, `.s3`, `.recordTraffic`, `ActivityView`, `ViewModelFixture`, `ShareBar`, `ConnectionDraft`, `.connect`, `ServiceAccountKey`, `.validate`, `SFTPFixture`, `.remove`, `.remote`, `ActivityViewModel`, `ActivityViewModel`, `AppViewModel`, `AppSearchTests`, `.control`, `ServerTrustChallenge`, `S3StorageClass`, `GoogleSignInRequired`, `Backend`, `withRclone`, `.mount`, `.recordTraffic`, `.run`, `GCSAuthentication`, `.body`, `AppViewModel`, `.execute`, `UploadCleanup`, `.gcs`?**
  _High betweenness centrality (0.154) - this node is a cross-community bridge._
- **Are the 9 inferred relationships involving `Connection` (e.g. with `AWSSettings` and `GCSSettings`) actually correct?**
  _`Connection` has 9 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.title`, `.locksRemoteFolder`, `.availableProviders` to the rest of the system?**
  _272 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Decodable` be split into smaller, more focused modules?**
  _Cohesion score 0.0783744557329463 - nodes in this community are weakly interconnected._
- **Why does `Credentials` connect `MacOSDesktopServices` to `withControl`, `Connection`, `Sendable`, `MountStatus`, `Credentials`, `AppViewModel`, `TrafficViewModelTests`, `Equatable`, `withControl`, `.s3`, `AppSearchTests`, `RcloneRemote`, `ViewModelFactory`, `ServiceAccountKey`, `.validate`, `.remote`, `ActivityViewModel`, `AppViewModel`, `AppSearchTests`, `withS3Drive`, `MenuBarIcon`, `.remove`, `.mount`, `.recordTraffic`, `DriveGateway`, `GCSAuthentication`, `waitUntil`, `GoogleDriveTests`, `RcloneRemote`, `GoogleToken`, `.gcs`?**
  _High betweenness centrality (0.073) - this node is a cross-community bridge._
- **Are the 33 inferred relationships involving `Credentials` (e.g. with `ConnectionEditorViewModel` and `.credentialsSavedBeforeEncryptionHaveNoPassword()`) actually correct?**
  _`Credentials` has 33 INFERRED edges - model-reasoned connections that need verification._
- **Should `Connection` be split into smaller, more focused modules?**
  _Cohesion score 0.12 - nodes in this community are weakly interconnected._