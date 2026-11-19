# Graph Report - unlocalfs  (2026-11-19)

## Corpus Check
- 168 files · ~49,151 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 12 file(s) not represented in the graph (top: .xcstrings 5, (none) 3, .resolved 1)

## Summary
- 2142 nodes · 5294 edges · 121 communities (91 shown, 30 thin omitted)
- Extraction: 81% EXTRACTED · 19% INFERRED · 0% AMBIGUOUS · INFERRED: 1001 edges (avg confidence: 0.85)
- Token cost: 289,731 input · 0 output

## Graph Freshness
- Built from commit: `00b6ad32`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- withControl
- Decodable
- Credentials
- .remove
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
- AppViewModel
- ConnectionStore
- Credentials
- ServerTrustChallenge
- .gcs
- TrafficViewModelTests
- MacOSDesktopServices
- Equatable
- ViewModelFixture
- .refresh
- MountService
- Decision
- AppSearchTests
- LocalizedError
- AppError
- ConnectionIdentityFields
- FixtureResources
- ViewModelFixture
- DriveGateway
- GoogleToken
- AppViewModel
- UnixConnection
- .status
- AppError
- .connect
- ServiceAccountKey
- .connect
- AppViewModel
- SFTPFixture
- .remove
- ControlServer
- MacOSDesktopServices.swift
- AppViewModel
- State
- .refresh
- ServiceAccountKey
- TrafficView
- .validate
- .runBackendCommand
- ServerTrustChallenge
- ServerTrustChallenge
- FileActivity
- SFTPAuthentication
- ControlServer
- .refresh
- TrafficViewModelTests
- .sample
- MountService
- Drive.swift
- CaseIterable
- ShareLinkExpiry
- Backend
- Decision
- StatusIndicator
- SFTPLogin
- .connect
- ConnectionDraft
- MenuBarIcon
- GCSConnectionFields
- TransferSummary
- GoogleSignIn
- .shareLink
- StatusIndicator
- SpeedSample
- .canCleanUpUploads
- State
- Traffic
- FakeDrive
- awsFixture
- Indicator
- DriveEjectError
- GoogleAccountField
- TrafficView
- statusBatch
- ConnectionEditorField
- .reading
- FileActionError
- UploadCleanup
- Command.swift
- .body
- TrafficPeriod
- GoogleDriveTests
- UploadTally
- Notification
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
- ServerTrustChallenge
- waitUntil
- State
- GoogleClient
- AppViewModel
- ClosedRange<Date>
- RcloneState

## God Nodes (most connected - your core abstractions)
1. `Connection` - 226 edges
2. `UnlocalFSDomain` - 109 edges
3. `Credentials` - 98 edges
4. `MountService` - 91 edges
5. `ViewModelFixture` - 84 edges
6. `DriveGateway` - 52 edges
7. `FileActivity` - 50 edges
8. `AppViewModel` - 49 edges
9. `ConnectionEditorViewModel` - 48 edges
10. `UnlocalFSPresentation` - 45 edges

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

## Communities (121 total, 30 thin omitted)

### Community 0 - "withControl"
Cohesion: 0.17
Nodes (6): mark(), MountSafetyTests, shutdown(), withControl(), withFixture(), statusBatch()

### Community 1 - "Decodable"
Cohesion: 0.05
Nodes (13): Connection, .backend, .bucketPath, .exportsRcloneConfig, .storageName, .usesGoogleSignIn, .usesUploadTimes, .driveStorage (+5 more)

### Community 2 - "Credentials"
Cohesion: 0.07
Nodes (45): RcloneError, DriveAbout, User, BatchResult, CodingKeys, error, ControlSnapshot, CodingKeys (+37 more)

### Community 4 - ".remove"
Cohesion: 0.08
Nodes (13): .serviceAccountEmail, ServiceAccountKey, String, .isBlank, ValidationResult, .fieldErrors, Issue, .isValid (+5 more)

### Community 5 - "UnixConnection"
Cohesion: 0.08
Nodes (8): Foundation, GRDB, Observation, sftpSettings(), Security, Subprocess, System, UnlocalFSDomain

### Community 6 - "Connection"
Cohesion: 0.13
Nodes (10): Direction, .color, download, .fill, .label, .symbol, upload, SpeedChart (+2 more)

### Community 7 - ".validate"
Cohesion: 0.05
Nodes (42): runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, environment, if (+34 more)

### Community 8 - ".s3"
Cohesion: 0.11
Nodes (4): Synchronization, Testing, UnlocalFSInfrastructure, UnlocalFSTestSupport

### Community 9 - "ConnectionRepository"
Cohesion: 0.09
Nodes (5): ActivityViewModelTests, AppPollingTests, AppViewModelTests, UploadCleanupTests, TestDesktopServices

### Community 10 - "MountStatus"
Cohesion: 0.10
Nodes (10): GoogleDriveValidationTests, AppSignInTests, GoogleSignInEditorTests, ViewModelFixture, .paths, .rcloneCalls, .root, .service (+2 more)

### Community 11 - "LocalizedError"
Cohesion: 0.10
Nodes (8): SaveConnectionUseCase, ConnectionStore, SavedConnectionRepository, configURL(), ConnectionTests, RepositoryTests, withWorkflowFixture(), WorkflowTests

### Community 12 - "Date"
Cohesion: 0.09
Nodes (14): ConnectionRepository, DeleteConnectionUseCase, DriveGateway, ConnectDriveUseCase, Outcome, connected, ejected, QuitUseCase (+6 more)

### Community 14 - "TrafficPreset"
Cohesion: 0.14
Nodes (6): AppKit, Charts, Network, SwiftUI, UniformTypeIdentifiers, UnlocalFSPresentation

### Community 16 - "AppViewModel"
Cohesion: 0.09
Nodes (7): Credentials, .encryptionPassword, .googleSignIn, .keyPassphrase, .password, GCSDriveTests, ConnectionEditorViewModelTests

### Community 17 - "ConnectionStore"
Cohesion: 0.06
Nodes (5): CancelUploadTests, FinderServicesTests, MenuBarActivityTests, SpeedRecordingTests, ControlServers

### Community 18 - "Credentials"
Cohesion: 0.11
Nodes (7): DriveTraffic, TrafficDay, TrafficRepository, TrafficStore, .migrator, .total, TrafficStoreTests

### Community 19 - "ServerTrustChallenge"
Cohesion: 0.06
Nodes (35): env, runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, DEVELOPER_DIR (+27 more)

### Community 20 - ".gcs"
Cohesion: 0.11
Nodes (4): DesktopServices, RcloneConfigDestination, MacOSDesktopServices, .opensAtLogin

### Community 21 - "TrafficViewModelTests"
Cohesion: 0.17
Nodes (12): ConnectionDetail, .actions, .awsDetails, .bucketDetail, .disconnected, .logo, .notices, .sftpDetails (+4 more)

### Community 22 - "MacOSDesktopServices"
Cohesion: 0.14
Nodes (10): ConnectionEditorViewModel, .connection, .credentials, .fieldErrors, .firstInvalidField, .initialFocus, .isLocked, .locksRemoteFolder (+2 more)

### Community 23 - "Equatable"
Cohesion: 0.07
Nodes (29): env, runs-on, steps, timeout-minutes, APPLE_ID, DEVELOPER_DIR, GH_TOKEN, GOOGLE_CLIENT_ID (+21 more)

### Community 25 - "ViewModelFixture"
Cohesion: 0.11
Nodes (10): AppPaths, .knownHosts, .sockets, .traffic, MountCommand, .arguments, .environment, .mountParameters (+2 more)

### Community 26 - ".refresh"
Cohesion: 0.09
Nodes (17): ClosedRange<Date>, DateInterval, TrafficPeriod, custom, last12Months, last30Days, last90Days, TrafficPreset (+9 more)

### Community 28 - "Decision"
Cohesion: 0.13
Nodes (4): Notification, AppDelegate, .model, .viewModels

### Community 30 - "LocalizedError"
Cohesion: 0.14
Nodes (12): Backend, gcs, googleDrive, .locksFolderAfterSave, s3Compatible, sftp, .supportsMultiThreadUploads, .supportsServerCopy (+4 more)

### Community 31 - "AppError"
Cohesion: 0.23
Nodes (6): Drive, dump(), makeDrive(), rclone(), verifyRoundTrip(), withOfflineDrive()

### Community 32 - "ConnectionIdentityFields"
Cohesion: 0.22
Nodes (5): ConnectionIdentityFields, .body, .providerPicker, S3ConnectionFields, .body

### Community 33 - "FixtureResources"
Cohesion: 0.19
Nodes (4): ControlSocket, ControlUnreachable, UnixConnection, .timedOut

### Community 34 - "ViewModelFixture"
Cohesion: 0.13
Nodes (4): RcloneProcess, TrafficCheckpoint, TrafficSave, UnfinishedUpload

### Community 35 - "DriveGateway"
Cohesion: 0.16
Nodes (7): AWSSettings, .customKMSKey, ServerSideEncryption, .id, kms, s3Managed, .title

### Community 36 - "GoogleToken"
Cohesion: 0.11
Nodes (19): ConnectionField, accessKey, bucket, confirmation, .displayName, encryptionPassword, endpoint, folder (+11 more)

### Community 37 - "AppViewModel"
Cohesion: 0.23
Nodes (12): NamedRemote, Options, RcloneRemote, .cryptOptions, .driveOptions, .environment, .gcsOptions, .namedRemotes (+4 more)

### Community 38 - "UnixConnection"
Cohesion: 0.10
Nodes (19): Provider, aws, .backend, cloudflare, digitalOcean, googleCloudStorage, googleDrive, .group (+11 more)

### Community 39 - ".status"
Cohesion: 0.17
Nodes (13): Date, DayCell, .body, MonthGrid, .body, TrafficRangePicker, .body, TrafficChart (+5 more)

### Community 40 - "AppError"
Cohesion: 0.10
Nodes (7): AppError, Keychain, CredentialStorage, KeychainTests, MemoryCredentialStorage, UnavailableCredentialStorage, LockableCredentialStorage

### Community 41 - ".connect"
Cohesion: 0.14
Nodes (9): TrafficBar, .id, TrafficViewModel, .custom, .period, .recentTotal, .unit, .body (+1 more)

### Community 42 - "ServiceAccountKey"
Cohesion: 0.23
Nodes (6): Traffic, .total, TrafficMeter, .unsaved, TrafficReading, TrafficMeterTests

### Community 44 - "AppViewModel"
Cohesion: 0.25
Nodes (7): BatchReply, .current, counters(), finished(), reply(), TrafficTests, withRclone()

### Community 45 - "SFTPFixture"
Cohesion: 0.18
Nodes (5): FixtureResources, Launch, requireOutput(), withFixture(), startAgent()

### Community 46 - ".remove"
Cohesion: 0.11
Nodes (14): DriveCondition, checking, connected, disconnected, ejected, .indicator, needsAttention, needsReconnect (+6 more)

### Community 48 - "MacOSDesktopServices.swift"
Cohesion: 0.17
Nodes (8): .isSignedInToGoogle, .secrets, GoogleAccountChanged, .errorDescription, GoogleSignInRequired, .errorDescription, GoogleToken, Fields

### Community 49 - "AppViewModel"
Cohesion: 0.06
Nodes (21): AppViewModel, Activity, connected, downloading, idle, uploading, .busy, Indicator (+13 more)

### Community 50 - "State"
Cohesion: 0.20
Nodes (8): SFTPFixture, .agentSocket, .connection, .credentials, .key, .protectedKey, .served, SFTPServer

### Community 51 - ".refresh"
Cohesion: 0.22
Nodes (4): MountStatus, .isActive, .isServing, .needsReconnect

### Community 52 - "ServiceAccountKey"
Cohesion: 0.14
Nodes (7): controlCalls(), failingStatus(), revokedDrive(), ServiceRecoveryTests, withRevokedDrive(), StubbedDrives, .rcloneCalls

### Community 53 - "TrafficView"
Cohesion: 0.14
Nodes (8): ConnectionRow, .icon, .sidebar, FocusedValues, SidebarSearchField, .body, TrafficCard, .body

### Community 54 - ".validate"
Cohesion: 0.17
Nodes (6): ActivityViewModel, .refreshInterval, UploadCancellation, .message, .title, .body

### Community 55 - ".runBackendCommand"
Cohesion: 0.25
Nodes (6): ShareBar, .body, TrafficList, .body, TrafficStats, .body

### Community 56 - "ServerTrustChallenge"
Cohesion: 0.10
Nodes (8): ServerTrustChallenge, .errorDescription, .server, SFTPSettings, .agentSocketPath, .keyPath, SFTPTrustStore, Pending

### Community 57 - "ServerTrustChallenge"
Cohesion: 0.20
Nodes (3): S3DriveTests, S3Server, withS3Drive()

### Community 58 - "FileActivity"
Cohesion: 0.14
Nodes (10): FileActivity, .finishedAt, .id, .isUpload, Sequence<FileActivity>, .folder, .isCancellable, .name (+2 more)

### Community 59 - "SFTPAuthentication"
Cohesion: 0.29
Nodes (6): SFTPAuthentication, agent, .id, password, privateKey, .title

### Community 60 - "ControlServer"
Cohesion: 0.16
Nodes (3): ControlFailure, ControlRequest, ControlServer

### Community 62 - ".refresh"
Cohesion: 0.29
Nodes (6): Build from source, Documentation, Documentation development, Features, Install, License

### Community 64 - ".sample"
Cohesion: 0.15
Nodes (13): ARCHS, ASSETCATALOG_COMPILER_APPICON_NAME, CODE_SIGN_STYLE, CURRENT_PROJECT_VERSION, ENABLE_HARDENED_RUNTIME, ENABLE_USER_SCRIPT_SANDBOXING, INFOPLIST_FILE, MARKETING_VERSION (+5 more)

### Community 65 - "MountService"
Cohesion: 0.13
Nodes (5): Darwin, MountService, .baseEnvironment, TrafficTracker, UploadTally

### Community 66 - "Drive.swift"
Cohesion: 0.21
Nodes (7): SFTPDriveTests, SFTPLogin, agent, key, password, protectedKey, withSFTPDrive()

### Community 67 - "CaseIterable"
Cohesion: 0.15
Nodes (10): ActivityFileName, .body, ActivityTable, .body, ActivityView, .activity, .idle, .body (+2 more)

### Community 68 - "ShareLinkExpiry"
Cohesion: 0.14
Nodes (5): ConnectionBucketFields, .body, GCSConnectionFields, .body, .serviceAccountField

### Community 71 - "StatusIndicator"
Cohesion: 0.22
Nodes (7): ActivityStatus, .body, .movingText, .progress, FailedUploadButton, .body, .details

### Community 72 - "SFTPLogin"
Cohesion: 0.18
Nodes (9): ProviderGroup, generic, google, s3Services, .providerSections, Pane, connection, .displayName (+1 more)

### Community 73 - ".connect"
Cohesion: 0.19
Nodes (7): GCSAuthentication, googleAccount, .id, serviceAccount, .title, GCSSettings, Config

### Community 74 - "ConnectionDraft"
Cohesion: 0.20
Nodes (9): interval, time, timezone, updates, directory, open-pull-requests-limit, package-ecosystem, schedule (+1 more)

### Community 75 - "MenuBarIcon"
Cohesion: 0.18
Nodes (5): MenuBarIcon, .accessibilityValue, .animatesUploads, .body, .image

### Community 77 - "TransferSummary"
Cohesion: 0.22
Nodes (6): ShareLinkExpiry, day, hour, .title, week, AppViewModel

### Community 78 - "GoogleSignIn"
Cohesion: 0.21
Nodes (3): GoogleSignIn, GoogleSignInRun, .isRunning

### Community 80 - "StatusIndicator"
Cohesion: 0.20
Nodes (10): Debug, Release, package, product, UnlocalFS, configFiles, dependencies, platform (+2 more)

### Community 81 - "SpeedSample"
Cohesion: 0.24
Nodes (5): SFTPConnectionFields, .authenticationHelp, .authenticationSection, .body, .serverSection

### Community 83 - "State"
Cohesion: 0.25
Nodes (6): .header, DriveManagementItems, .body, .body, StatusIndicator, .body

### Community 84 - "Traffic"
Cohesion: 0.40
Nodes (3): .signInAgainButton, GoogleSignInButton, .body

### Community 85 - "FakeDrive"
Cohesion: 0.28
Nodes (4): DriveEjectError, .errorDescription, UploadsPendingError, .errorDescription

### Community 86 - "awsFixture"
Cohesion: 0.25
Nodes (8): config, targets, config, schemes, UnlocalFS, archive, build, run

### Community 87 - "Indicator"
Cohesion: 0.18
Nodes (4): ConnectionDraft, .id, .isDuplicate, ConnectionRulesTests

### Community 88 - "DriveEjectError"
Cohesion: 0.29
Nodes (6): ActivitySnapshot, checking, .files, idle, transfers, unavailable

### Community 89 - "GoogleAccountField"
Cohesion: 0.29
Nodes (4): SpeedSample, .axisLimit, .fastestDownload, .fastestUpload

### Community 92 - "ConnectionEditorField"
Cohesion: 0.17
Nodes (6): ConnectionEditorField, .body, GoogleAccountField, .body, GoogleDriveConnectionFields, .body

### Community 93 - ".reading"
Cohesion: 0.29
Nodes (6): name, packages, UnlocalFSCore, settings, targets, path

### Community 97 - ".body"
Cohesion: 0.25
Nodes (3): ConnectionEditor, .advancedSection, .body

### Community 100 - "UploadTally"
Cohesion: 0.33
Nodes (6): copyFiles, destination, subpath, buildPhase, path, sources

### Community 101 - "Notification"
Cohesion: 0.50
Nodes (3): OSLog, ServiceManagement, UserNotifications

### Community 102 - ".status"
Cohesion: 0.18
Nodes (4): Decision, disconnect, quit, wait

### Community 103 - "MainView"
Cohesion: 0.22
Nodes (6): UnlocalFSApp, .body, MainView, .detail, MenuContent, .body

### Community 104 - "UploadCleanup"
Cohesion: 0.24
Nodes (4): AppViewModel, UploadCleanup, .message, .title

### Community 105 - ".quitDisconnectsEveryDriveAtTheSameTime"
Cohesion: 0.28
Nodes (3): AppQuitTests, Overlap, .peak

### Community 107 - "QuitUseCase"
Cohesion: 0.40
Nodes (5): macOS, options, deploymentTarget, postGenCommand, projectFileFormat

### Community 108 - "Command.swift"
Cohesion: 0.40
Nodes (5): basedOnDependencyAnalysis, name, script, shell, postBuildScripts

### Community 109 - ".signInAgain"
Cohesion: 0.50
Nodes (4): package, config, targets, test

### Community 110 - "S3StorageClass"
Cohesion: 0.25
Nodes (8): S3StorageClass, glacierInstantRetrieval, .id, intelligentTiering, oneZoneInfrequentAccess, standard, standardInfrequentAccess, .title

### Community 115 - "State"
Cohesion: 0.29
Nodes (7): State, downloaded, downloading, failed, queued, uploaded, uploading

### Community 118 - "ClosedRange<Date>"
Cohesion: 0.40
Nodes (4): ClosedRange<Date>, .formattedDays, DateInterval, .formattedDays

### Community 119 - "RcloneState"
Cohesion: 0.50
Nodes (4): RcloneState, running, stopped, untracked

## Knowledge Gaps
- **279 isolated node(s):** `PackageDescription`, `standard`, `intelligentTiering`, `standardInfrequentAccess`, `oneZoneInfrequentAccess` (+274 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 645 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **30 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Connection` connect `Decodable` to `withControl`, `.mount`, `.remove`, `ConnectionRepository`, `MountStatus`, `LocalizedError`, `Date`, `AppViewModel`, `.shareLink`, `AppViewModel`, `ConnectionStore`, `Credentials`, `.gcs`, `TrafficViewModelTests`, `MacOSDesktopServices`, `withControl`, `ViewModelFixture`, `LocalizedError`, `AppError`, `ViewModelFixture`, `DriveGateway`, `AppViewModel`, `AppError`, `.connect`, `.connect`, `AppViewModel`, `ControlServer`, `AppViewModel`, `State`, `ServiceAccountKey`, `TrafficView`, `.validate`, `ServerTrustChallenge`, `FileActivity`, `.control`, `TrafficViewModelTests`, `MountService`, `CaseIterable`, `SFTPLogin`, `.connect`, `.shareLink`, `State`, `Indicator`, `UploadCleanup`, `.status`, `MainView`, `UploadCleanup`, `.test`, `GoogleClient`, `AppViewModel`?**
  _High betweenness centrality (0.294) - this node is a cross-community bridge._
- **Are the 10 inferred relationships involving `Connection` (e.g. with `AWSSettings` and `GCSSettings`) actually correct?**
  _`Connection` has 10 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `standard`, `intelligentTiering` to the rest of the system?**
  _279 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Decodable` be split into smaller, more focused modules?**
  _Cohesion score 0.05380852550663871 - nodes in this community are weakly interconnected._
- **Why does `Foundation` connect `UnixConnection` to `Credentials`, `.remove`, `.s3`, `LocalizedError`, `Date`, `Credentials`, `ViewModelFixture`, `.refresh`, `MountService`, `AppError`, `FixtureResources`, `ViewModelFixture`, `DriveGateway`, `MacOSDesktopServices.swift`, `ServerTrustChallenge`, `FileActivity`, `SFTPAuthentication`, `ControlServer`, `MountService`, `Decision`, `SFTPLogin`, `.connect`, `GCSConnectionFields`, `FakeDrive`, `Indicator`, `FileActionError`, `Command.swift`, `.test`, `ServerTrustChallenge`?**
  _High betweenness centrality (0.061) - this node is a cross-community bridge._
- **Are the 33 inferred relationships involving `Credentials` (e.g. with `.delete()` and `ConnectionEditorViewModel`) actually correct?**
  _`Credentials` has 33 INFERRED edges - model-reasoned connections that need verification._
- **Should `Credentials` be split into smaller, more focused modules?**
  _Cohesion score 0.06610169491525424 - nodes in this community are weakly interconnected._