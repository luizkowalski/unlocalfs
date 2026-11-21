# Graph Report - unlocalfs  (2026-11-21)

## Corpus Check
- 170 files · ~49,582 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 12 file(s) not represented in the graph (top: .xcstrings 5, (none) 3, .resolved 1)

## Summary
- 2184 nodes · 5339 edges · 142 communities (93 shown, 49 thin omitted)
- Extraction: 81% EXTRACTED · 19% INFERRED · 0% AMBIGUOUS · INFERRED: 1008 edges (avg confidence: 0.85)
- Token cost: 289,731 input · 0 output

## Graph Freshness
- Built from commit: `833cf86f`
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
- withControl
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
- ViewModelFixture
- Date
- QuitUseCase
- AppViewModel
- ControlServer
- .status
- AppError
- .connect
- ServerTrustChallenge
- .connect
- AppViewModel
- SFTPFixture
- .remove
- Darwin
- Direction
- TransferSummary
- .refresh
- ServiceAccountKey
- .validate
- .runBackendCommand
- ServerTrustChallenge
- ConnectionEditorField
- SidebarSearchField
- SFTPAuthentication
- ViewModelFixture
- ActivityViewModel
- TrafficViewModelTests
- ConnectionEditorField
- MountService
- Drive.swift
- SFTPSettings
- ShareLinkExpiry
- ShareLinkExpiry
- Decision
- Keychain
- .connect
- ConnectionDraft
- MenuBarIcon
- UploadTally
- TransferSummary
- GoogleSignIn
- GoogleToken
- FileActivity
- SpeedSample
- LockableCredentialStorage
- fetchActivity
- AppError
- FakeDrive
- awsFixture
- .update
- StatusIndicator
- TrafficView.swift
- TrafficPeriod
- statusBatch
- ConnectionEditorField
- CaseIterable
- Command.swift
- UnfinishedUpload
- ActivityView
- GoogleDriveTests
- UploadTally
- .status
- MainView
- UploadCleanup
- SpeedSample
- postBuildScripts
- QuitUseCase
- ServiceRecoveryTests
- .signInAgain
- S3StorageClass
- GoogleSignInRun
- State
- ClosedRange<Date>
- .serve
- State
- ServiceRecoveryTests.swift
- ActivitySnapshot
- TrafficPreset
- FileActivity
- Indicator
- RcloneRemote.swift
- TrafficPreset

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
- `AppDelegate` --references--> `ViewModelFactory`  [EXTRACTED]
  UnlocalFS/Application/UnlocalFSApp.swift → Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/ViewModelFactory.swift
- `GoogleAccountField` --references--> `ConnectionField`  [EXTRACTED]
  UnlocalFS/Presentation/Connections/GoogleAccountField.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `GoogleAccountField` --references--> `ConnectionEditorViewModel`  [EXTRACTED]
  UnlocalFS/Presentation/Connections/GoogleAccountField.swift → Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/ConnectionEditorViewModel.swift

## Import Cycles
- None detected.

## Communities (142 total, 49 thin omitted)

### Community 0 - "withControl"
Cohesion: 0.11
Nodes (3): ActivityViewModelTests, AppViewModelTests, TestDesktopServices

### Community 1 - "Decodable"
Cohesion: 0.07
Nodes (44): DriveAbout, User, BatchResult, CodingKeys, error, ControlSnapshot, CodingKeys, results (+36 more)

### Community 2 - "ConnectionStore"
Cohesion: 0.14
Nodes (5): ConnectionStore, SavedConnectionRepository, configURL(), ConnectionTests, RepositoryTests

### Community 3 - ".mount"
Cohesion: 0.08
Nodes (12): Connection, .backend, .bucketPath, .exportsRcloneConfig, .storageName, .usesGoogleSignIn, .usesUploadTimes, .driveStorage (+4 more)

### Community 4 - "DriveGateway"
Cohesion: 0.13
Nodes (14): ConnectionRepository, DeleteConnectionUseCase, DriveGateway, ConnectDriveUseCase, Outcome, connected, ejected, QuitUseCase (+6 more)

### Community 5 - "UnixConnection"
Cohesion: 0.09
Nodes (5): GCSDriveTests, GoogleDriveValidationTests, AppSignInTests, GoogleSignInEditorTests, waitUntil()

### Community 6 - "Connection"
Cohesion: 0.09
Nodes (5): Foundation, GRDB, Observation, Security, UnlocalFSDomain

### Community 7 - ".validate"
Cohesion: 0.07
Nodes (13): .serviceAccountEmail, ServiceAccountKey, String, .isBlank, ValidationResult, .fieldErrors, Issue, .isValid (+5 more)

### Community 8 - ".s3"
Cohesion: 0.11
Nodes (3): Testing, UnlocalFSInfrastructure, UnlocalFSTestSupport

### Community 9 - "ConnectionRepository"
Cohesion: 0.05
Nodes (42): runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, environment, if (+34 more)

### Community 10 - "MountStatus"
Cohesion: 0.12
Nodes (6): Credentials, .encryptionPassword, .googleSignIn, .keyPassphrase, .password, ConnectionEditorViewModelTests

### Community 11 - "LocalizedError"
Cohesion: 0.25
Nodes (3): CredentialStorage, MemoryCredentialStorage, UnavailableCredentialStorage

### Community 12 - "Date"
Cohesion: 0.06
Nodes (35): env, runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, DEVELOPER_DIR (+27 more)

### Community 13 - "AppViewModel"
Cohesion: 0.10
Nodes (12): AppViewModel, Activity, connected, downloading, idle, uploading, .busy, .isConfirmingDelete (+4 more)

### Community 15 - ".shareLink"
Cohesion: 0.11
Nodes (7): DriveTraffic, TrafficDay, TrafficRepository, TrafficStore, .migrator, .total, TrafficStoreTests

### Community 16 - "AppViewModel"
Cohesion: 0.16
Nodes (4): ClosedRange<Date>, DateInterval, date(), TrafficPeriodTests

### Community 17 - ".remove"
Cohesion: 0.08
Nodes (4): AppPollingTests, MenuBarActivityTests, SpeedRecordingTests, ControlServers

### Community 18 - "Credentials"
Cohesion: 0.12
Nodes (7): AppKit, Network, ServiceManagement, SwiftUI, UniformTypeIdentifiers, UnlocalFSPresentation, UserNotifications

### Community 19 - "ServerTrustChallenge"
Cohesion: 0.07
Nodes (29): env, runs-on, steps, timeout-minutes, APPLE_ID, DEVELOPER_DIR, GH_TOKEN, GOOGLE_CLIENT_ID (+21 more)

### Community 20 - ".gcs"
Cohesion: 0.12
Nodes (4): DesktopServices, RcloneConfigDestination, MacOSDesktopServices, .opensAtLogin

### Community 21 - "withControl"
Cohesion: 0.18
Nodes (6): mark(), MountSafetyTests, shutdown(), withControl(), withFixture(), statusBatch()

### Community 22 - "MacOSDesktopServices"
Cohesion: 0.05
Nodes (17): Notification, AppDelegate, .model, .viewModels, UnlocalFSApp, .body, .driveCommands, .model (+9 more)

### Community 23 - "Equatable"
Cohesion: 0.28
Nodes (4): Traffic, .total, TrafficMeter, TrafficMeterTests

### Community 24 - "withControl"
Cohesion: 0.13
Nodes (18): ConnectionDetail, .actions, .awsDetails, .body, .bucketDetail, .disconnected, .logo, .notices (+10 more)

### Community 25 - "ViewModelFixture"
Cohesion: 0.13
Nodes (10): AppPaths, .knownHosts, .sockets, .traffic, MountCommand, .arguments, .environment, .mountParameters (+2 more)

### Community 26 - ".refresh"
Cohesion: 0.11
Nodes (15): .unsaved, TrafficBar, .id, TrafficViewModel, .custom, .period, .recentTotal, .unit (+7 more)

### Community 27 - "MountService"
Cohesion: 0.18
Nodes (5): GoogleSignIn, controlCalls(), withRevokedDrive(), StubbedDrives, .rcloneCalls

### Community 28 - "Decision"
Cohesion: 0.11
Nodes (9): DriveEjectError, .errorDescription, UploadsPendingError, .errorDescription, ControlSocket, ControlUnreachable, RcloneError, UnixConnection (+1 more)

### Community 29 - "UploadCleanup"
Cohesion: 0.17
Nodes (5): AppAlert, AppViewModel, UploadCleanup, .message, .title

### Community 30 - "Equatable"
Cohesion: 0.21
Nodes (4): RcloneProcess, TrafficCheckpoint, TrafficReading, TrafficSave

### Community 31 - "AppError"
Cohesion: 0.10
Nodes (19): Provider, aws, .backend, cloudflare, digitalOcean, googleCloudStorage, googleDrive, .group (+11 more)

### Community 33 - ".sftp"
Cohesion: 0.18
Nodes (4): SaveConnectionUseCase, withWorkflowFixture(), WorkflowTests, sftpSettings()

### Community 35 - "Date"
Cohesion: 0.29
Nodes (7): Date, DayCell, .body, MonthGrid, .body, TrafficRangePicker, .body

### Community 36 - "QuitUseCase"
Cohesion: 0.18
Nodes (4): Decision, disconnect, quit, wait

### Community 37 - "AppViewModel"
Cohesion: 0.18
Nodes (4): FixtureResources, Launch, requireOutput(), withFixture()

### Community 38 - "ControlServer"
Cohesion: 0.15
Nodes (4): revokedDrive(), ControlFailure, ControlRequest, ControlServer

### Community 39 - ".status"
Cohesion: 0.11
Nodes (11): ConnectionEditorViewModel, .connection, .credentials, .fieldErrors, .firstInvalidField, .initialFocus, .isLocked, .locksRemoteFolder (+3 more)

### Community 40 - "AppError"
Cohesion: 0.21
Nodes (3): AppViewModel, .activity, .canDisconnectAll

### Community 41 - ".connect"
Cohesion: 0.11
Nodes (19): ConnectionField, accessKey, bucket, confirmation, .displayName, encryptionPassword, endpoint, folder (+11 more)

### Community 42 - "ServerTrustChallenge"
Cohesion: 0.26
Nodes (3): ServerTrustChallenge, .errorDescription, .server

### Community 43 - ".connect"
Cohesion: 0.09
Nodes (15): DriveCondition, checking, connected, disconnected, ejected, .indicator, needsAttention, needsReconnect (+7 more)

### Community 44 - "AppViewModel"
Cohesion: 0.21
Nodes (7): BatchReply, .current, counters(), finished(), reply(), TrafficTests, withRclone()

### Community 45 - "SFTPFixture"
Cohesion: 0.20
Nodes (6): Drive, dump(), makeDrive(), rclone(), verifyRoundTrip(), withOfflineDrive()

### Community 46 - ".remove"
Cohesion: 0.18
Nodes (9): SFTPFixture, .agentSocket, .connection, .credentials, .key, .protectedKey, .served, SFTPServer (+1 more)

### Community 47 - "Darwin"
Cohesion: 0.25
Nodes (5): Darwin, RcloneState, running, stopped, untracked

### Community 48 - "Direction"
Cohesion: 0.13
Nodes (10): Direction, .color, download, .fill, .label, .symbol, upload, SpeedChart (+2 more)

### Community 51 - ".refresh"
Cohesion: 0.16
Nodes (13): GoogleClient, NamedRemote, Options, RcloneRemote, .cryptOptions, .driveOptions, .environment, .gcsOptions (+5 more)

### Community 52 - "ServiceAccountKey"
Cohesion: 0.12
Nodes (15): AWSSettings, .customKMSKey, S3StorageClass, glacierInstantRetrieval, .id, intelligentTiering, oneZoneInfrequentAccess, standard (+7 more)

### Community 54 - ".validate"
Cohesion: 0.22
Nodes (3): S3DriveTests, S3Server, withS3Drive()

### Community 55 - ".runBackendCommand"
Cohesion: 0.14
Nodes (12): Backend, gcs, googleDrive, .locksFolderAfterSave, s3Compatible, sftp, .supportsMultiThreadUploads, .supportsServerCopy (+4 more)

### Community 56 - "ServerTrustChallenge"
Cohesion: 0.17
Nodes (3): CancelUploadTests, TrafficViewModelTests, .yesterday

### Community 57 - "ConnectionEditorField"
Cohesion: 0.12
Nodes (10): ConnectionBucketFields, .body, ConnectionEditor, .advancedSection, .editor, ConnectionEditorField, .body, .body (+2 more)

### Community 58 - "SidebarSearchField"
Cohesion: 0.29
Nodes (3): FocusedValues, SidebarSearchField, .body

### Community 59 - "SFTPAuthentication"
Cohesion: 0.19
Nodes (7): GCSAuthentication, googleAccount, .id, serviceAccount, .title, GCSSettings, Config

### Community 61 - "ViewModelFixture"
Cohesion: 0.13
Nodes (9): AppSearchTests, FinderServicesTests, ViewModelFixture, .paths, .rcloneCalls, .root, .service, .signInEnvironment (+1 more)

### Community 62 - "ActivityViewModel"
Cohesion: 0.13
Nodes (7): ActivityViewModel, .refreshInterval, UploadCancellation, .fileName, .message, .title, .body

### Community 63 - "TrafficViewModelTests"
Cohesion: 0.15
Nodes (13): ARCHS, ASSETCATALOG_COMPILER_APPICON_NAME, CODE_SIGN_STYLE, CURRENT_PROJECT_VERSION, ENABLE_HARDENED_RUNTIME, ENABLE_USER_SCRIPT_SANDBOXING, INFOPLIST_FILE, MARKETING_VERSION (+5 more)

### Community 64 - "ConnectionEditorField"
Cohesion: 0.12
Nodes (9): ConnectionIdentityFields, .providerPicker, GCSConnectionFields, .body, .serviceAccountField, GoogleAccountField, .body, GoogleDriveConnectionFields (+1 more)

### Community 65 - "MountService"
Cohesion: 0.21
Nodes (7): SFTPDriveTests, SFTPLogin, agent, key, password, protectedKey, withSFTPDrive()

### Community 66 - "Drive.swift"
Cohesion: 0.18
Nodes (3): FakeStorage, .uploadCount, UploadCleanupTests

### Community 67 - "SFTPSettings"
Cohesion: 0.15
Nodes (9): SFTPAuthentication, agent, .id, password, privateKey, .title, SFTPSettings, .agentSocketPath (+1 more)

### Community 68 - "ShareLinkExpiry"
Cohesion: 0.29
Nodes (3): ConnectionDraft, .id, .isDuplicate

### Community 69 - "ShareLinkExpiry"
Cohesion: 0.10
Nodes (7): FileActionError, ShareLinkExpiry, day, hour, .title, week, AppViewModel

### Community 70 - "Decision"
Cohesion: 0.12
Nodes (5): MountStatus, .isActive, .isServing, .needsReconnect, ConnectionRulesTests

### Community 74 - "ConnectionDraft"
Cohesion: 0.22
Nodes (7): ActivityStatus, .body, .movingText, .progress, FailedUploadButton, .body, .details

### Community 75 - "MenuBarIcon"
Cohesion: 0.24
Nodes (5): SFTPConnectionFields, .authenticationHelp, .authenticationSection, .body, .serverSection

### Community 76 - "UploadTally"
Cohesion: 0.32
Nodes (3): OSLog, TrafficTracker, UploadTally

### Community 77 - "TransferSummary"
Cohesion: 0.20
Nodes (9): interval, time, timezone, updates, directory, open-pull-requests-limit, package-ecosystem, schedule (+1 more)

### Community 79 - "GoogleToken"
Cohesion: 0.17
Nodes (8): .isSignedInToGoogle, .secrets, GoogleAccountChanged, .errorDescription, GoogleSignInRequired, .errorDescription, GoogleToken, Fields

### Community 80 - "FileActivity"
Cohesion: 0.20
Nodes (7): FileActivity, .finishedAt, .id, .isUpload, Sequence<FileActivity>, .hasFailed, .rank

### Community 81 - "SpeedSample"
Cohesion: 0.20
Nodes (10): Debug, Release, package, product, UnlocalFS, configFiles, dependencies, platform (+2 more)

### Community 84 - "AppError"
Cohesion: 0.11
Nodes (3): AppError, Command, CommandTests

### Community 86 - "awsFixture"
Cohesion: 0.28
Nodes (3): AppQuitTests, Overlap, .peak

### Community 88 - "StatusIndicator"
Cohesion: 0.25
Nodes (6): .header, ConnectionRow, .body, .icon, StatusIndicator, .body

### Community 89 - "TrafficView.swift"
Cohesion: 0.12
Nodes (17): Charts, ClosedRange<Date>, .formattedDays, DateInterval, .formattedDays, ShareBar, .body, TrafficChart (+9 more)

### Community 90 - "TrafficPeriod"
Cohesion: 0.20
Nodes (8): SidebarItem, drive, traffic, TrafficPeriod, custom, last12Months, last30Days, last90Days

### Community 92 - "ConnectionEditorField"
Cohesion: 0.25
Nodes (8): config, targets, config, schemes, UnlocalFS, archive, build, run

### Community 94 - "CaseIterable"
Cohesion: 0.18
Nodes (9): ProviderGroup, generic, google, s3Services, .providerSections, Pane, connection, .displayName (+1 more)

### Community 98 - "ActivityView"
Cohesion: 0.25
Nodes (7): ActivityFileName, .body, ActivityTable, .body, ActivityView, .activity, .idle

### Community 99 - "GoogleDriveTests"
Cohesion: 0.29
Nodes (6): name, packages, UnlocalFSCore, settings, targets, path

### Community 100 - "UploadTally"
Cohesion: 0.29
Nodes (6): Build from source, Documentation, Documentation development, Features, Install, License

### Community 103 - "MainView"
Cohesion: 0.25
Nodes (3): AppViewModel, .showsTraffic, .visibleConnections

### Community 105 - "SpeedSample"
Cohesion: 0.18
Nodes (5): SpeedSample, .axisLimit, .fastestDownload, .fastestUpload, SpeedSampleTests

### Community 107 - "QuitUseCase"
Cohesion: 0.33
Nodes (6): copyFiles, destination, subpath, buildPhase, path, sources

### Community 109 - ".signInAgain"
Cohesion: 0.40
Nodes (5): macOS, options, deploymentTarget, postGenCommand, projectFileFormat

### Community 110 - "S3StorageClass"
Cohesion: 0.40
Nodes (5): basedOnDependencyAnalysis, name, script, shell, postBuildScripts

### Community 111 - "GoogleSignInRun"
Cohesion: 0.15
Nodes (5): GoogleSignInRun, .isRunning, .signInAgainButton, GoogleSignInButton, .body

### Community 115 - "State"
Cohesion: 0.50
Nodes (4): package, config, targets, test

### Community 129 - "State"
Cohesion: 0.29
Nodes (7): State, downloaded, downloading, failed, queued, uploaded, uploading

### Community 131 - "ActivitySnapshot"
Cohesion: 0.29
Nodes (6): ActivitySnapshot, checking, .files, idle, transfers, unavailable

### Community 132 - "TrafficPreset"
Cohesion: 0.29
Nodes (7): TrafficPreset, last7Days, lastMonth, thisMonth, thisYear, today, yesterday

### Community 133 - "FileActivity"
Cohesion: 0.33
Nodes (4): FileActivity, .folder, .isCancellable, .name

### Community 134 - "Indicator"
Cohesion: 0.40
Nodes (5): Indicator, attention, connected, idle, working

## Knowledge Gaps
- **283 isolated node(s):** `.body`, `.animatesUploads`, `.image`, `.accessibilityValue`, `error` (+278 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 672 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **49 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Connection` connect `.mount` to `withControl`, `ConnectionStore`, `DriveGateway`, `UnixConnection`, `.validate`, `RcloneRemote.swift`, `MountStatus`, `AppViewModel`, `.shareLink`, `.remove`, `.gcs`, `withControl`, `MacOSDesktopServices`, `withControl`, `ViewModelFixture`, `.refresh`, `MountService`, `UploadCleanup`, `Equatable`, `.connect`, `.sftp`, `ViewModelFixture`, `QuitUseCase`, `.status`, `AppError`, `AppViewModel`, `SFTPFixture`, `.remove`, `.control`, `.refresh`, `ServiceAccountKey`, `.exportKeepsHostVerificationAndNeedsNoLocalFiles`, `.runBackendCommand`, `ServerTrustChallenge`, `SFTPAuthentication`, `ControlServer`, `ActivityViewModel`, `Drive.swift`, `SFTPSettings`, `ShareLinkExpiry`, `ShareLinkExpiry`, `Decision`, `AppError`, `FakeDrive`, `.update`, `StatusIndicator`, `CaseIterable`, `UnfinishedUpload`, `ActivityView`, `.status`, `MainView`?**
  _High betweenness centrality (0.225) - this node is a cross-community bridge._
- **Are the 9 inferred relationships involving `Connection` (e.g. with `AWSSettings` and `GCSSettings`) actually correct?**
  _`Connection` has 9 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.body`, `.animatesUploads`, `.image` to the rest of the system?**
  _283 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `withControl` be split into smaller, more focused modules?**
  _Cohesion score 0.1130952380952381 - nodes in this community are weakly interconnected._
- **Why does `Foundation` connect `Connection` to `Decodable`, `ServiceRecoveryTests.swift`, `DriveGateway`, `.validate`, `RcloneRemote.swift`, `.s3`, `.shareLink`, `ViewModelFixture`, `Decision`, `Equatable`, `ControlServer`, `ServerTrustChallenge`, `AppViewModel`, `Darwin`, `TransferSummary`, `ServiceAccountKey`, `SFTPAuthentication`, `SFTPSettings`, `ShareLinkExpiry`, `ShareLinkExpiry`, `.connect`, `UploadTally`, `GoogleSignIn`, `GoogleToken`, `FileActivity`, `CaseIterable`, `Command.swift`, `UnfinishedUpload`, `UploadCleanup`, `ClosedRange<Date>`?**
  _High betweenness centrality (0.078) - this node is a cross-community bridge._
- **Are the 33 inferred relationships involving `Credentials` (e.g. with `.delete()` and `ConnectionEditorViewModel`) actually correct?**
  _`Credentials` has 33 INFERRED edges - model-reasoned connections that need verification._
- **Should `Decodable` be split into smaller, more focused modules?**
  _Cohesion score 0.06779661016949153 - nodes in this community are weakly interconnected._