# Graph Report - unlocalfs  (2026-11-16)

## Corpus Check
- 168 files · ~49,097 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 12 file(s) not represented in the graph (top: .xcstrings 5, (none) 3, .resolved 1)

## Summary
- 2184 nodes · 5278 edges · 151 communities (87 shown, 64 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 953 edges (avg confidence: 0.85)
- Token cost: 289,731 input · 0 output

## Graph Freshness
- Built from commit: `f2615798`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- withControl
- Decodable
- .s3
- GoogleToken
- .validate
- MountService
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
- ServerTrustChallenge
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
- MountService
- RcloneRemote
- ViewModelFactory
- ConnectionField
- SFTPLogin
- .connect
- ServiceAccountKey
- ValidationResult
- MenuBarIcon
- SFTPFixture
- .remove
- ConnectionEditor
- ActivityViewModel
- ConnectionStore
- AppViewModel
- AppSearchTests
- ControlFailure
- ConnectionEditorField
- ConnectionDraft
- SFTPTrustStore
- ServerTrustChallenge
- withS3Drive
- S3StorageClass
- .validate
- MenuBarIcon
- ServiceAccountKey
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
- TransferSummary
- project.yml
- .shareLink
- updates
- .post
- SFTPAuthentication
- SFTPSettings
- Traffic
- SFTPConnectionFields
- .run
- TrafficPeriod
- ProviderIcon
- TrafficView
- DriveGateway
- GCSAuthentication
- .sftp
- DriveAboutProtocol
- GoogleSignInButton
- SpeedSample
- MemoryCredentialStorage
- README.md
- GoogleDriveTests
- UploadTally
- README.md
- AppError
- AppViewModel
- GoogleAccountChanged
- UploadCleanup
- RcloneState
- Darwin
- .deleteFileToStopUpload
- .signInAgain
- ConnectionDraft
- AppSearchTests
- PackageDescription
- FileActionError
- UnfinishedUpload
- StubbedDrives
- awsFixture
- Activity
- Indicator
- waitUntil
- RcloneRemote.swift
- ByteCountFormatStyle+Size.swift
- ClosedRange<Date>
- .copyShareLinks
- .googleDrive

## God Nodes (most connected - your core abstractions)
1. `Connection` - 140 edges
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
- `AppDelegate` --references--> `ViewModelFactory`  [EXTRACTED]
  UnlocalFS/Application/UnlocalFSApp.swift → Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/ViewModelFactory.swift
- `MacOSDesktopServices` --references--> `AppPaths`  [EXTRACTED]
  UnlocalFS/Application/MacOSDesktopServices.swift → Packages/UnlocalFSCore/Sources/UnlocalFSInfrastructure/AppPaths.swift
- `ActivityFileName` --references--> `FileActivity`  [EXTRACTED]
  UnlocalFS/Presentation/Activity/ActivityFileName.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/FileActivity.swift
- `ActivityTable` --references--> `FileActivity`  [EXTRACTED]
  UnlocalFS/Presentation/Activity/ActivityTable.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/FileActivity.swift

## Import Cycles
- None detected.

## Communities (151 total, 64 thin omitted)

### Community 0 - "withControl"
Cohesion: 0.16
Nodes (6): mark(), MountSafetyTests, shutdown(), withControl(), withFixture(), statusBatch()

### Community 1 - "Decodable"
Cohesion: 0.08
Nodes (39): DriveAbout, User, BatchResult, CodingKeys, bytes, completedAt, dstFs, error (+31 more)

### Community 3 - "GoogleToken"
Cohesion: 0.36
Nodes (4): .isSignedInToGoogle, .secrets, GoogleToken, Fields

### Community 4 - ".validate"
Cohesion: 0.08
Nodes (7): Foundation, GRDB, Observation, Security, Subprocess, System, UnlocalFSDomain

### Community 5 - "MountService"
Cohesion: 0.05
Nodes (42): runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, environment, if (+34 more)

### Community 7 - "TrafficViewModel"
Cohesion: 0.11
Nodes (15): .unsaved, TrafficBar, .id, TrafficViewModel, .custom, .period, .recentTotal, .unit (+7 more)

### Community 8 - ".s3"
Cohesion: 0.12
Nodes (8): AppKit, Charts, Network, ServiceManagement, SwiftUI, UniformTypeIdentifiers, UnlocalFSPresentation, UserNotifications

### Community 9 - "steps"
Cohesion: 0.06
Nodes (35): env, runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, DEVELOPER_DIR (+27 more)

### Community 10 - "MountStatus"
Cohesion: 0.11
Nodes (5): MountStatus, .isActive, .isServing, .needsReconnect, ConnectionRulesTests

### Community 11 - "LocalizedError"
Cohesion: 0.10
Nodes (4): Synchronization, Testing, UnlocalFSInfrastructure, UnlocalFSTestSupport

### Community 12 - "Credentials"
Cohesion: 0.09
Nodes (12): ConnectionRepository, SetAutomaticConnectUseCase, ConnectDriveUseCase, Outcome, connected, ejected, SignInAgainUseCase, DuplicateFilesUseCase (+4 more)

### Community 13 - "MountService"
Cohesion: 0.11
Nodes (10): AppPaths, .knownHosts, .sockets, .traffic, MountCommand, .arguments, .environment, .mountParameters (+2 more)

### Community 14 - "TrafficPreset"
Cohesion: 0.10
Nodes (23): Backend, .rcloneType, Connection, .driveStorage, .driveTarget, .rclonePath, .rcloneType, .storageRemoteName (+15 more)

### Community 15 - "TrafficPreset"
Cohesion: 0.10
Nodes (17): SpeedSample, .axisLimit, .fastestDownload, .fastestUpload, ClosedRange<Date>, Date, DateInterval, TrafficPreset (+9 more)

### Community 16 - "AppViewModel"
Cohesion: 0.19
Nodes (3): SaveConnectionUseCase, withWorkflowFixture(), WorkflowTests

### Community 17 - "ConnectionStore"
Cohesion: 0.07
Nodes (29): env, runs-on, steps, timeout-minutes, APPLE_ID, DEVELOPER_DIR, GH_TOKEN, GOOGLE_CLIENT_ID (+21 more)

### Community 18 - ".sftp"
Cohesion: 0.10
Nodes (8): AppViewModel, .busy, .isConfirmingDelete, .isShowingAlert, .isShowingDisconnectFailure, .isShowingUploadsBlockingDisconnect, .selected, .unsavedTraffic

### Community 19 - "ServerTrustChallenge"
Cohesion: 0.12
Nodes (6): ServerTrustChallenge, .errorDescription, .server, SFTPSettings, Pending, SFTPTrustStore

### Community 20 - ".gcs"
Cohesion: 0.14
Nodes (4): DesktopServices, RcloneConfigDestination, MacOSDesktopServices, .opensAtLogin

### Community 22 - "MacOSDesktopServices"
Cohesion: 0.07
Nodes (15): Credentials, .encryptionPassword, .googleSignIn, .keyPassphrase, .password, AppSignInTests, ConnectionEditorViewModelTests, GoogleSignInEditorTests (+7 more)

### Community 23 - "Equatable"
Cohesion: 0.16
Nodes (8): Decision, disconnect, quit, wait, RcloneProcess, TrafficCheckpoint, TrafficReading, TrafficSave

### Community 24 - "withControl"
Cohesion: 0.13
Nodes (6): ConnectionStore, CredentialStorage, SavedConnectionRepository, MemoryCredentialStorage, RepositoryTests, UnavailableCredentialStorage

### Community 25 - ".s3"
Cohesion: 0.14
Nodes (3): AppViewModelTests, FinderServicesTests, TestDesktopServices

### Community 26 - "ConnectionDetail"
Cohesion: 0.17
Nodes (4): Notification, AppDelegate, .model, .viewModels

### Community 27 - "withRclone"
Cohesion: 0.25
Nodes (7): BatchReply, .current, counters(), finished(), reply(), TrafficTests, withRclone()

### Community 28 - ".execute"
Cohesion: 0.09
Nodes (15): DriveCondition, checking, connected, disconnected, ejected, .indicator, needsAttention, needsReconnect (+7 more)

### Community 29 - "ActivityView"
Cohesion: 0.25
Nodes (7): ActivityFileName, .body, ActivityTable, .body, ActivityView, .activity, .idle

### Community 30 - "LocalizedError"
Cohesion: 0.28
Nodes (4): DriveEjectError, .errorDescription, UploadsPendingError, .errorDescription

### Community 32 - "StubbedDrives"
Cohesion: 0.16
Nodes (13): ConnectionDetail, .awsDetails, .body, .bucketDetail, .disconnected, .logo, .notices, .sftpDetails (+5 more)

### Community 33 - "FixtureResources"
Cohesion: 0.13
Nodes (10): Direction, .color, download, .fill, .label, .symbol, upload, SpeedChart (+2 more)

### Community 34 - "ViewModelFixture"
Cohesion: 0.11
Nodes (7): DriveTraffic, TrafficDay, TrafficRepository, TrafficStore, .migrator, .total, TrafficStoreTests

### Community 35 - "withRclone"
Cohesion: 0.10
Nodes (19): ConnectionField, accessKey, bucket, confirmation, .displayName, encryptionPassword, endpoint, folder (+11 more)

### Community 37 - "RcloneRemote"
Cohesion: 0.12
Nodes (6): controlCalls(), failingStatus(), LockableCredentialStorage, revokedDrive(), ServiceRecoveryTests, withRevokedDrive()

### Community 38 - "ViewModelFactory"
Cohesion: 0.10
Nodes (14): ConnectionEditorViewModel, .availableProviders, .connection, .credentials, .fieldErrors, .firstInvalidField, .initialFocus, .isLocked (+6 more)

### Community 39 - "ConnectionField"
Cohesion: 0.17
Nodes (4): FixtureResources, Launch, requireOutput(), withFixture()

### Community 40 - "SFTPLogin"
Cohesion: 0.21
Nodes (7): SFTPDriveTests, SFTPLogin, agent, key, password, protectedKey, withSFTPDrive()

### Community 42 - "ServiceAccountKey"
Cohesion: 0.10
Nodes (19): Provider, aws, .backend, cloudflare, digitalOcean, googleCloudStorage, googleDrive, .group (+11 more)

### Community 43 - "ValidationResult"
Cohesion: 0.26
Nodes (6): Issue, String, .isBlank, ValidationResult, .fieldErrors, .isValid

### Community 44 - "MenuBarIcon"
Cohesion: 0.13
Nodes (9): UnlocalFSApp, .body, MenuBarIcon, .accessibilityValue, .animatesUploads, .body, .image, MenuContent (+1 more)

### Community 45 - "SFTPFixture"
Cohesion: 0.13
Nodes (9): Connection, .backend, .bucketPath, .exportsRcloneConfig, .folderPath, .usesGoogleSignIn, .usesUploadTimes, AppViewModel (+1 more)

### Community 46 - ".remove"
Cohesion: 0.18
Nodes (3): FakeStorage, .uploadCount, UploadCleanupTests

### Community 47 - "ConnectionEditor"
Cohesion: 0.16
Nodes (5): ConnectionEditor, .advancedSection, MainView, .body, .detail

### Community 48 - "ActivityViewModel"
Cohesion: 0.15
Nodes (6): ActivityViewModel, .refreshInterval, UploadCancellation, .message, .title, .body

### Community 50 - "AppViewModel"
Cohesion: 0.20
Nodes (6): Drive, dump(), makeDrive(), rclone(), verifyRoundTrip(), withOfflineDrive()

### Community 51 - "AppSearchTests"
Cohesion: 0.21
Nodes (9): SFTPFixture, .agentSocket, .connection, .credentials, .key, .protectedKey, .served, SFTPServer (+1 more)

### Community 52 - "ControlFailure"
Cohesion: 0.17
Nodes (3): ControlFailure, ControlRequest, ControlServer

### Community 53 - "ConnectionEditorField"
Cohesion: 0.10
Nodes (12): ConnectionBucketFields, .body, ConnectionEditorField, .body, ConnectionIdentityFields, .body, .providerPicker, GoogleDriveConnectionFields (+4 more)

### Community 54 - "ConnectionDraft"
Cohesion: 0.14
Nodes (7): ConnectionRow, .sidebar, FocusedValues, SidebarSearchField, .body, TrafficCard, .body

### Community 56 - "SFTPTrustStore"
Cohesion: 0.12
Nodes (10): FileActivity, .finishedAt, .id, .isUpload, Sequence<FileActivity>, .folder, .isCancellable, .name (+2 more)

### Community 58 - "withS3Drive"
Cohesion: 0.22
Nodes (3): S3DriveTests, S3Server, withS3Drive()

### Community 60 - "S3StorageClass"
Cohesion: 0.13
Nodes (14): AWSSettings, S3StorageClass, glacierInstantRetrieval, .id, intelligentTiering, oneZoneInfrequentAccess, standard, standardInfrequentAccess (+6 more)

### Community 63 - "ServiceAccountKey"
Cohesion: 0.21
Nodes (3): .serviceAccountEmail, ServiceAccountKey, GCSValidationTests

### Community 65 - ".remove"
Cohesion: 0.11
Nodes (4): AppPollingTests, MenuBarActivityTests, SpeedRecordingTests, ControlServers

### Community 67 - "base"
Cohesion: 0.15
Nodes (13): ARCHS, ASSETCATALOG_COMPILER_APPICON_NAME, CODE_SIGN_STYLE, CURRENT_PROJECT_VERSION, ENABLE_HARDENED_RUNTIME, ENABLE_USER_SCRIPT_SANDBOXING, INFOPLIST_FILE, MARKETING_VERSION (+5 more)

### Community 68 - "Date"
Cohesion: 0.14
Nodes (13): State, downloaded, downloading, failed, queued, uploaded, uploading, DayCell (+5 more)

### Community 69 - "Backend"
Cohesion: 0.15
Nodes (11): Backend, gcs, googleDrive, .locksFolderAfterSave, s3Compatible, sftp, .supportsMultiThreadUploads, .supportsServerCopy (+3 more)

### Community 70 - "GoogleSignInRun"
Cohesion: 0.18
Nodes (3): GoogleSignIn, GoogleSignInRun, .isRunning

### Community 71 - "StatusIndicator"
Cohesion: 0.22
Nodes (7): .actions, .header, DriveManagementItems, .body, .body, StatusIndicator, .body

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

### Community 78 - "project.yml"
Cohesion: 0.20
Nodes (9): interval, time, timezone, updates, directory, open-pull-requests-limit, package-ecosystem, schedule (+1 more)

### Community 79 - ".shareLink"
Cohesion: 0.33
Nodes (5): ShareLinkExpiry, day, hour, .title, week

### Community 81 - ".post"
Cohesion: 0.21
Nodes (5): ControlSocket, ControlUnreachable, RcloneError, UnixConnection, .timedOut

### Community 82 - "SFTPAuthentication"
Cohesion: 0.17
Nodes (10): SFTPAuthentication, agent, .id, password, privateKey, .title, Pane, connection (+2 more)

### Community 83 - "SFTPSettings"
Cohesion: 0.20
Nodes (10): Debug, Release, package, product, UnlocalFS, configFiles, dependencies, platform (+2 more)

### Community 84 - "Traffic"
Cohesion: 0.28
Nodes (4): Traffic, .total, TrafficMeter, TrafficMeterTests

### Community 85 - "SFTPConnectionFields"
Cohesion: 0.29
Nodes (4): SFTPConnectionFields, .authenticationHelp, .authenticationSection, .body

### Community 87 - "TrafficPeriod"
Cohesion: 0.20
Nodes (8): SidebarItem, drive, traffic, TrafficPeriod, custom, last12Months, last30Days, last90Days

### Community 89 - "ProviderIcon"
Cohesion: 0.13
Nodes (11): .icon, Provider, .logo, ProviderIcon, .body, ShareBar, .body, TrafficList (+3 more)

### Community 90 - "TrafficView"
Cohesion: 0.25
Nodes (8): config, targets, config, schemes, UnlocalFS, archive, build, run

### Community 92 - "GCSAuthentication"
Cohesion: 0.19
Nodes (7): GCSAuthentication, googleAccount, .id, serviceAccount, .title, GCSSettings, Config

### Community 95 - "GoogleSignInButton"
Cohesion: 0.29
Nodes (6): ActivitySnapshot, checking, .files, idle, transfers, unavailable

### Community 98 - "README.md"
Cohesion: 0.33
Nodes (6): copyFiles, destination, subpath, buildPhase, path, sources

### Community 100 - "UploadTally"
Cohesion: 0.32
Nodes (3): OSLog, TrafficTracker, UploadTally

### Community 101 - "README.md"
Cohesion: 0.29
Nodes (6): Build from source, Documentation, Documentation development, Features, Install, License

### Community 104 - "GoogleAccountChanged"
Cohesion: 0.25
Nodes (4): GoogleAccountChanged, .errorDescription, GoogleSignInRequired, .errorDescription

### Community 105 - "UploadCleanup"
Cohesion: 0.24
Nodes (4): AppViewModel, UploadCleanup, .message, .title

### Community 106 - "RcloneState"
Cohesion: 0.40
Nodes (5): basedOnDependencyAnalysis, name, script, shell, postBuildScripts

### Community 107 - "Darwin"
Cohesion: 0.25
Nodes (5): Darwin, RcloneState, running, stopped, untracked

### Community 108 - ".deleteFileToStopUpload"
Cohesion: 0.50
Nodes (4): package, config, targets, test

### Community 110 - "ConnectionDraft"
Cohesion: 0.29
Nodes (3): ConnectionDraft, .id, .isDuplicate

### Community 125 - "StubbedDrives"
Cohesion: 0.23
Nodes (3): GCSDriveTests, StubbedDrives, .rcloneCalls

### Community 129 - "Activity"
Cohesion: 0.40
Nodes (5): Activity, connected, downloading, idle, uploading

### Community 130 - "Indicator"
Cohesion: 0.40
Nodes (5): Indicator, attention, connected, idle, working

### Community 144 - "ClosedRange<Date>"
Cohesion: 0.40
Nodes (4): ClosedRange<Date>, .formattedDays, DateInterval, .formattedDays

## Knowledge Gaps
- **278 isolated node(s):** `Network`, `.model`, `.viewModels`, `bytes`, `completedAt` (+273 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 664 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **64 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Connection` connect `SFTPFixture` to `awsFixture`, `.s3`, `.control`, `TrafficViewModel`, `MountStatus`, `Credentials`, `MountService`, `AppViewModel`, `.sftp`, `.googleDrive`, `.gcs`, `TrafficViewModelTests`, `Equatable`, `withControl`, `MacOSDesktopServices`, `withRclone`, `ActivityView`, `DeleteConnectionUseCase`, `ViewModelFixture`, `withRclone`, `MountService`, `.connect`, `ServiceAccountKey`, `.remove`, `ConnectionEditor`, `ActivityViewModel`, `ConnectionStore`, `AppViewModel`, `AppSearchTests`, `.runBackendCommand`, `SFTPTrustStore`, `ServerTrustChallenge`, `S3StorageClass`, `.validate`, `ServiceAccountKey`, `StatusIndicator`, `updates`, `.run`, `GCSAuthentication`, `.sftp`, `AppError`, `AppViewModel`, `UploadCleanup`, `ConnectionDraft`?**
  _High betweenness centrality (0.130) - this node is a cross-community bridge._
- **Are the 7 inferred relationships involving `Connection` (e.g. with `AWSSettings` and `GCSSettings`) actually correct?**
  _`Connection` has 7 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Network`, `.model`, `.viewModels` to the rest of the system?**
  _278 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Decodable` be split into smaller, more focused modules?**
  _Cohesion score 0.0783744557329463 - nodes in this community are weakly interconnected._
- **Why does `AppError` connect `AppError` to `Decodable`, `waitUntil`, `.serve`, `.control`, `MountStatus`, `AppViewModel`, `ServerTrustChallenge`, `MacOSDesktopServices`, `Equatable`, `withControl`, `.s3`, `LocalizedError`, `DeleteConnectionUseCase`, `MountService`, `RcloneRemote`, `ConnectionField`, `ServiceAccountKey`, `ValidationResult`, `MenuBarIcon`, `ServiceAccountKey`, `.post`, `.run`, `DriveGateway`, `FileActionError`?**
  _High betweenness centrality (0.090) - this node is a cross-community bridge._
- **Are the 32 inferred relationships involving `Credentials` (e.g. with `ConnectionEditorViewModel` and `.credentialsSavedBeforeEncryptionHaveNoPassword()`) actually correct?**
  _`Credentials` has 32 INFERRED edges - model-reasoned connections that need verification._
- **Should `.s3` be split into smaller, more focused modules?**
  _Cohesion score 0.125 - nodes in this community are weakly interconnected._