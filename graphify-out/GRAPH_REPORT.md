# Graph Report - unlocalfs  (2026-11-13)

## Corpus Check
- 152 files · ~43,075 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 12 file(s) not represented in the graph (top: .xcstrings 5, (none) 3, .resolved 1)

## Summary
- 1933 nodes · 4765 edges · 117 communities (86 shown, 31 thin omitted)
- Extraction: 83% EXTRACTED · 17% INFERRED · 0% AMBIGUOUS · INFERRED: 819 edges (avg confidence: 0.85)
- Token cost: 289,731 input · 0 output

## Graph Freshness
- Built from commit: `88810bd5`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Traffic
- View Model Fixtures
- .sftp
- ServerTrustChallenge
- MountStatus
- Foundation Module Imports
- Documentation Deployment
- Connection
- TestDesktopServices
- Mount Process Shutdown
- Build Test Workflow
- Test Module Dependencies
- Connection Editor Tests
- .interval
- AppViewModel
- FileActivity
- Connection Detail Views
- Release Build Workflow
- Finder Service Dispatch
- Darwin
- withControl
- AppSearchTests
- withControl
- Traffic Database Storage
- Desktop File Dialogs
- ConnectionEditorField
- CopyName
- TrafficPeriod
- AppError
- Traffic Counter Accounting
- AppViewModel
- Storage Smoke Fixtures
- Rclone Remote Configuration
- Connection Field Names
- .status
- AppSearchTests
- .validate
- .status
- Process Test Resources
- Presentation and Application
- Keychain
- TrafficStore
- Storage Provider Selection
- MountService
- .sftp
- TrafficView
- Fake Storage Server
- Equatable
- ValidationResult
- SFTP Host Trust
- S3 Drive Tests
- AWS Encryption Settings
- GCSConnectionFields
- UnlocalFSPresentation
- ConnectionStore
- ProviderIcon
- DriveCondition
- Credentials
- SFTPAuthentication
- ConnectionStore
- CopyName
- MountCommand
- TrafficPreset
- .refresh
- ActivityView
- SidebarSearchField
- StubbedDrives
- .reading
- Storage Backend Capabilities
- Direction
- ShareBar
- DriveEjectError
- FileActionError
- MainView
- Connection Editor Form
- .serve
- Activity
- StatusIndicator
- waitUntil
- SFTP Authentication Fields
- Dependency Update Schedule
- ClosedRange<Date>
- App Target Configuration
- ConnectionRulesTests
- Command Process Execution
- ServerTrustSheet
- Credentials
- ProviderIcon
- .recordTraffic
- UnfinishedUpload
- ConnectionDraft
- .sample
- MacOSDesktopServices.swift
- Application Build Schemes
- Decision
- ConnectionDraft
- connection-settings.md
- ActivitySnapshot
- waitUntil
- README.md
- ControlServers
- Sidebar Search Actions
- AppPathsTests.swift
- App Resource Copying
- .copyShareLinks
- MemoryCredentialStorage
- Activity
- Indicator
- SFTPSettings
- Helper Embedding Phase
- Package Test Configuration
- Swift Package Definition

## God Nodes (most connected - your core abstractions)
1. `Connection` - 210 edges
2. `UnlocalFSDomain` - 98 edges
3. `Credentials` - 92 edges
4. `MountService` - 81 edges
5. `AppViewModel` - 66 edges
6. `ViewModelFixture` - 65 edges
7. `FileActivity` - 50 edges
8. `DriveGateway` - 45 edges
9. `Traffic` - 44 edges
10. `ConnectionField` - 42 edges

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

## Communities (117 total, 31 thin omitted)

### Community 0 - "Traffic"
Cohesion: 0.07
Nodes (38): RcloneError, BatchResult, CodingKeys, bytes, completedAt, dstFs, error, initiated (+30 more)

### Community 1 - "View Model Fixtures"
Cohesion: 0.16
Nodes (3): AppPollingTests, AppViewModelTests, TestDesktopServices

### Community 3 - "ServerTrustChallenge"
Cohesion: 0.13
Nodes (5): CredentialStorage, SavedConnectionRepository, MemoryCredentialStorage, RepositoryTests, UnavailableCredentialStorage

### Community 4 - "MountStatus"
Cohesion: 0.22
Nodes (4): MountStatus, .isActive, .isServing, .needsReconnect

### Community 5 - "Foundation Module Imports"
Cohesion: 0.06
Nodes (14): Darwin, Foundation, GRDB, Observation, MountService, .baseEnvironment, String, .expandingTilde (+6 more)

### Community 6 - "Documentation Deployment"
Cohesion: 0.05
Nodes (42): runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, environment, if (+34 more)

### Community 7 - "Connection"
Cohesion: 0.08
Nodes (11): Connection, .backend, .bucketPath, .exportsRcloneConfig, .folderPath, .usesUploadTimes, .driveStorage, .driveTarget (+3 more)

### Community 8 - "TestDesktopServices"
Cohesion: 0.18
Nodes (8): .unsaved, TrafficBar, .id, TrafficViewModel, .custom, .period, .recentTotal, .unit

### Community 10 - "Mount Process Shutdown"
Cohesion: 0.25
Nodes (7): BatchReply, .current, counters(), finished(), reply(), TrafficTests, withRclone()

### Community 11 - "Build Test Workflow"
Cohesion: 0.06
Nodes (35): env, runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, DEVELOPER_DIR (+27 more)

### Community 12 - "Test Module Dependencies"
Cohesion: 0.10
Nodes (5): sftpSettings(), Synchronization, Testing, UnlocalFSInfrastructure, UnlocalFSTestSupport

### Community 13 - "Connection Editor Tests"
Cohesion: 0.16
Nodes (7): ConnectionEditorViewModelTests, ViewModelFixture, .paths, .rcloneCalls, .root, .service, .traffic

### Community 15 - "AppViewModel"
Cohesion: 0.07
Nodes (11): AppViewModel, .busy, .isConfirmingDelete, .isShowingAlert, .isShowingDisconnectFailure, .isShowingUploadsBlockingDisconnect, .selected, .unsavedTraffic (+3 more)

### Community 16 - "FileActivity"
Cohesion: 0.14
Nodes (10): FileActivity, .finishedAt, .id, .isUpload, Sequence<FileActivity>, .folder, .isCancellable, .name (+2 more)

### Community 17 - "Connection Detail Views"
Cohesion: 0.17
Nodes (11): ConnectionDetail, .actions, .awsDetails, .bucketDetail, .disconnected, .logo, .notices, .sftpDetails (+3 more)

### Community 18 - "Release Build Workflow"
Cohesion: 0.07
Nodes (27): env, runs-on, steps, timeout-minutes, APPLE_ID, DEVELOPER_DIR, GH_TOKEN, PASSWORD (+19 more)

### Community 19 - "Finder Service Dispatch"
Cohesion: 0.13
Nodes (3): AppDelegate, .model, .viewModels

### Community 20 - "Darwin"
Cohesion: 0.29
Nodes (7): Date, DayCell, .body, MonthGrid, .body, TrafficRangePicker, .body

### Community 21 - "withControl"
Cohesion: 0.15
Nodes (6): AppPaths, .knownHosts, .sockets, .traffic, .arguments, .knownHosts

### Community 23 - "withControl"
Cohesion: 0.05
Nodes (15): ActivityTests, fetchActivity(), mark(), MountSafetyTests, shutdown(), withControl(), withFixture(), failingStatus() (+7 more)

### Community 24 - "Traffic Database Storage"
Cohesion: 0.11
Nodes (7): DriveTraffic, TrafficDay, TrafficRepository, TrafficStore, .migrator, .total, TrafficStoreTests

### Community 25 - "Desktop File Dialogs"
Cohesion: 0.13
Nodes (4): DesktopServices, RcloneConfigDestination, MacOSDesktopServices, .opensAtLogin

### Community 26 - "ConnectionEditorField"
Cohesion: 0.17
Nodes (7): ConnectionBucketFields, .body, ConnectionEditorField, .body, .body, S3ConnectionFields, .body

### Community 27 - "CopyName"
Cohesion: 0.36
Nodes (3): SpeedChart, .body, .selectedSample

### Community 28 - "TrafficPeriod"
Cohesion: 0.22
Nodes (7): TrafficPeriod, custom, last12Months, last30Days, last90Days, date(), TrafficPeriodTests

### Community 29 - "AppError"
Cohesion: 0.08
Nodes (6): AppError, ShareLinkExpiry, day, hour, .title, week

### Community 30 - "Traffic Counter Accounting"
Cohesion: 0.28
Nodes (4): Traffic, .total, TrafficMeter, TrafficMeterTests

### Community 32 - "Storage Smoke Fixtures"
Cohesion: 0.17
Nodes (8): Drive, .mounted, dump(), makeDrive(), rclone(), verifyRoundTrip(), GCSDriveTests, withOfflineDrive()

### Community 33 - "Rclone Remote Configuration"
Cohesion: 0.16
Nodes (10): NamedRemote, Options, RcloneRemote, .cryptOptions, .environment, .gcsOptions, .namedRemotes, .options (+2 more)

### Community 34 - "Connection Field Names"
Cohesion: 0.11
Nodes (18): ConnectionField, accessKey, bucket, confirmation, .displayName, encryptionPassword, endpoint, folder (+10 more)

### Community 35 - ".status"
Cohesion: 0.16
Nodes (10): ConnectionEditorViewModel, .connection, .credentials, .fieldErrors, .firstInvalidField, .initialFocus, .isLocked, .locksRemoteFolder (+2 more)

### Community 36 - "AppSearchTests"
Cohesion: 0.22
Nodes (4): ControlSocket, ControlUnreachable, UnixConnection, .timedOut

### Community 37 - ".validate"
Cohesion: 0.07
Nodes (13): .serviceAccountEmail, ServiceAccountKey, Issue, String, .isBlank, ValidationResult, .fieldErrors, .isValid (+5 more)

### Community 38 - ".status"
Cohesion: 0.18
Nodes (4): RcloneState, running, stopped, untracked

### Community 39 - "Process Test Resources"
Cohesion: 0.17
Nodes (4): FixtureResources, Launch, requireOutput(), withFixture()

### Community 40 - "Presentation and Application"
Cohesion: 0.15
Nodes (6): ActivityViewModel, .refreshInterval, UploadCancellation, .message, .title, .body

### Community 42 - "TrafficStore"
Cohesion: 0.20
Nodes (4): RcloneProcess, TrafficCheckpoint, TrafficReading, TrafficSave

### Community 43 - "Storage Provider Selection"
Cohesion: 0.10
Nodes (17): Provider, aws, .backend, cloudflare, digitalOcean, googleCloudStorage, .id, .isGeneric (+9 more)

### Community 45 - "MountService"
Cohesion: 0.16
Nodes (6): ServerTrustChallenge, .errorDescription, .server, ActivityFileName, .body, .body

### Community 46 - ".sftp"
Cohesion: 0.21
Nodes (9): SFTPFixture, .agentSocket, .connection, .credentials, .key, .protectedKey, .served, SFTPServer (+1 more)

### Community 47 - "TrafficView"
Cohesion: 0.20
Nodes (8): TrafficChart, .body, TrafficList, TrafficView, .body, .heading, .periodPicker, .title

### Community 48 - "Fake Storage Server"
Cohesion: 0.18
Nodes (3): FakeStorage, .uploadCount, UploadCleanupTests

### Community 50 - "Equatable"
Cohesion: 0.12
Nodes (3): FinderServicesTests, MenuBarActivityTests, SpeedRecordingTests

### Community 51 - "ValidationResult"
Cohesion: 0.19
Nodes (12): ConnectionRepository, DeleteConnectionUseCase, SaveConnectionUseCase, SetAutomaticConnectUseCase, DriveGateway, ConnectDriveUseCase, QuitUseCase, DuplicateFilesUseCase (+4 more)

### Community 54 - "S3 Drive Tests"
Cohesion: 0.22
Nodes (3): S3DriveTests, S3Server, withS3Drive()

### Community 55 - "AWS Encryption Settings"
Cohesion: 0.11
Nodes (15): AWSSettings, S3StorageClass, glacierInstantRetrieval, .id, intelligentTiering, oneZoneInfrequentAccess, standard, standardInfrequentAccess (+7 more)

### Community 57 - "UnlocalFSPresentation"
Cohesion: 0.12
Nodes (10): AppKit, Charts, Network, SwiftUI, UniformTypeIdentifiers, ClosedRange<Date>, .formattedDays, DateInterval (+2 more)

### Community 58 - "ConnectionStore"
Cohesion: 0.25
Nodes (3): ConnectionStore, configURL(), ConnectionTests

### Community 59 - "ProviderIcon"
Cohesion: 0.13
Nodes (9): UnlocalFSApp, .body, MenuBarIcon, .accessibilityValue, .animatesUploads, .body, .image, MenuContent (+1 more)

### Community 60 - "DriveCondition"
Cohesion: 0.12
Nodes (13): DriveCondition, checking, connected, disconnected, ejected, .indicator, needsAttention, needsReconnect (+5 more)

### Community 61 - "Credentials"
Cohesion: 0.10
Nodes (8): Credentials, .encryptionPassword, .keyPassphrase, .password, .secrets, Outcome, connected, ejected

### Community 62 - "SFTPAuthentication"
Cohesion: 0.33
Nodes (6): SFTPAuthentication, agent, .id, password, privateKey, .title

### Community 65 - "MountCommand"
Cohesion: 0.25
Nodes (3): MountCommand, .environment, .mountParameters

### Community 66 - "TrafficPreset"
Cohesion: 0.22
Nodes (8): TrafficPreset, last7Days, lastMonth, thisMonth, thisYear, today, yesterday, .title

### Community 69 - "SidebarSearchField"
Cohesion: 0.15
Nodes (13): ARCHS, ASSETCATALOG_COMPILER_APPICON_NAME, CODE_SIGN_STYLE, CURRENT_PROJECT_VERSION, ENABLE_HARDENED_RUNTIME, ENABLE_USER_SCRIPT_SANDBOXING, INFOPLIST_FILE, MARKETING_VERSION (+5 more)

### Community 70 - "StubbedDrives"
Cohesion: 0.22
Nodes (7): ActivityStatus, .body, .movingText, .progress, FailedUploadButton, .body, .details

### Community 72 - "Storage Backend Capabilities"
Cohesion: 0.17
Nodes (10): Backend, gcs, .locksFolderAfterSave, s3Compatible, sftp, .supportsMultiThreadUploads, .supportsServerCopy, .supportsShareLinks (+2 more)

### Community 73 - "Direction"
Cohesion: 0.13
Nodes (9): Direction, .color, download, .fill, .label, .symbol, upload, TrafficStats (+1 more)

### Community 74 - "ShareBar"
Cohesion: 0.21
Nodes (7): SFTPDriveTests, SFTPLogin, agent, key, password, protectedKey, withSFTPDrive()

### Community 75 - "DriveEjectError"
Cohesion: 0.28
Nodes (4): DriveEjectError, .errorDescription, UploadsPendingError, .errorDescription

### Community 77 - "MainView"
Cohesion: 0.33
Nodes (3): MainView, .body, .detail

### Community 78 - "Connection Editor Form"
Cohesion: 0.19
Nodes (6): ConnectionEditor, .advancedSection, Pane, connection, .displayName, settings

### Community 80 - "Activity"
Cohesion: 0.18
Nodes (10): macOS, name, options, deploymentTarget, postGenCommand, packages, UnlocalFSCore, settings (+2 more)

### Community 81 - "StatusIndicator"
Cohesion: 0.25
Nodes (6): .header, DriveManagementItems, .body, .body, StatusIndicator, .body

### Community 82 - "waitUntil"
Cohesion: 0.29
Nodes (3): FocusedValues, SidebarSearchField, .body

### Community 83 - "SFTP Authentication Fields"
Cohesion: 0.25
Nodes (5): SFTPConnectionFields, .authenticationHelp, .authenticationSection, .body, .serverSection

### Community 84 - "Dependency Update Schedule"
Cohesion: 0.20
Nodes (9): interval, time, timezone, updates, directory, open-pull-requests-limit, package-ecosystem, schedule (+1 more)

### Community 85 - "ClosedRange<Date>"
Cohesion: 0.24
Nodes (4): AppViewModel, UploadCleanup, .message, .title

### Community 86 - "App Target Configuration"
Cohesion: 0.20
Nodes (10): Debug, Release, package, product, UnlocalFS, configFiles, dependencies, platform (+2 more)

### Community 89 - "ServerTrustSheet"
Cohesion: 0.19
Nodes (9): ActivityTable, ActivityView, .activity, .idle, .body, FittedScrollView, .body, ServerTrustSheet (+1 more)

### Community 90 - "Credentials"
Cohesion: 0.22
Nodes (3): AppQuitTests, Overlap, .peak

### Community 91 - "ProviderIcon"
Cohesion: 0.14
Nodes (10): ConnectionRow, .icon, .sidebar, ProviderIcon, .body, TrafficCard, .body, ShareBar (+2 more)

### Community 94 - "ConnectionDraft"
Cohesion: 0.29
Nodes (4): SpeedSample, .axisLimit, .fastestDownload, .fastestUpload

### Community 96 - "MacOSDesktopServices.swift"
Cohesion: 0.40
Nodes (3): OSLog, ServiceManagement, UserNotifications

### Community 97 - "Application Build Schemes"
Cohesion: 0.25
Nodes (8): config, targets, config, schemes, UnlocalFS, archive, build, run

### Community 98 - "Decision"
Cohesion: 0.40
Nodes (4): Decision, disconnect, quit, wait

### Community 99 - "ConnectionDraft"
Cohesion: 0.29
Nodes (3): ConnectionDraft, .id, .isDuplicate

### Community 100 - "connection-settings.md"
Cohesion: 0.29
Nodes (7): State, downloaded, downloading, failed, queued, uploaded, uploading

### Community 101 - "ActivitySnapshot"
Cohesion: 0.29
Nodes (6): ActivitySnapshot, checking, .files, idle, transfers, unavailable

### Community 103 - "README.md"
Cohesion: 0.29
Nodes (6): Build from source, Documentation, Documentation development, Features, Install, License

### Community 107 - "App Resource Copying"
Cohesion: 0.33
Nodes (6): copyFiles, destination, subpath, buildPhase, path, sources

### Community 111 - "Activity"
Cohesion: 0.40
Nodes (5): Activity, connected, downloading, idle, uploading

### Community 112 - "Indicator"
Cohesion: 0.40
Nodes (5): Indicator, attention, connected, idle, working

### Community 114 - "SFTPSettings"
Cohesion: 0.29
Nodes (3): SFTPSettings, .agentSocketPath, .keyPath

### Community 115 - "Helper Embedding Phase"
Cohesion: 0.40
Nodes (5): basedOnDependencyAnalysis, name, script, shell, postBuildScripts

### Community 119 - "Package Test Configuration"
Cohesion: 0.50
Nodes (4): package, config, targets, test

## Knowledge Gaps
- **255 isolated node(s):** `PackageDescription`, `standard`, `intelligentTiering`, `standardInfrequentAccess`, `oneZoneInfrequentAccess` (+250 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 591 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **31 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Connection` connect `Connection` to `Traffic`, `View Model Fixtures`, `.sftp`, `ServerTrustChallenge`, `Foundation Module Imports`, `TestDesktopServices`, `GoogleSignInRequired`, `Mount Process Shutdown`, `Connection Editor Tests`, `AppViewModel`, `FileActivity`, `Connection Detail Views`, `withControl`, `withControl`, `Traffic Database Storage`, `Desktop File Dialogs`, `AppError`, `AppViewModel`, `Storage Smoke Fixtures`, `Rclone Remote Configuration`, `.status`, `.validate`, `.status`, `Presentation and Application`, `TrafficStore`, `Storage Provider Selection`, `MountService`, `.sftp`, `Fake Storage Server`, `.deleteFileToStopUpload`, `ValidationResult`, `Server Copy Operations`, `SFTP Host Trust`, `AWS Encryption Settings`, `ConnectionStore`, `ProviderIcon`, `Credentials`, `ActivityView`, `Storage Backend Capabilities`, `.serve`, `StatusIndicator`, `ClosedRange<Date>`, `ConnectionRulesTests`, `ServerTrustSheet`, `ProviderIcon`, `.recordTraffic`, `UnfinishedUpload`, `ConnectionDraft`, `Sidebar Search Actions`, `SFTPSettings`?**
  _High betweenness centrality (0.269) - this node is a cross-community bridge._
- **Are the 9 inferred relationships involving `Connection` (e.g. with `AWSSettings` and `SFTPSettings`) actually correct?**
  _`Connection` has 9 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `standard`, `intelligentTiering` to the rest of the system?**
  _255 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Traffic` be split into smaller, more focused modules?**
  _Cohesion score 0.07078039927404718 - nodes in this community are weakly interconnected._
- **Why does `AppError` connect `AppError` to `Traffic`, `View Model Fixtures`, `.sftp`, `ServerTrustChallenge`, `MountStatus`, `Connection Editor Tests`, `Rclone Remote Configuration`, `AppSearchTests`, `.validate`, `.status`, `Process Test Resources`, `Keychain`, `Storage Provider Selection`, `.deleteFileToStopUpload`, `ValidationResult`, `Server Copy Operations`, `SFTP Host Trust`, `Credentials`, `MountCommand`, `DriveEjectError`, `Command Process Execution`, `waitUntil`?**
  _High betweenness centrality (0.077) - this node is a cross-community bridge._
- **Are the 41 inferred relationships involving `Credentials` (e.g. with `ConnectionEditorViewModel` and `.credentialsSavedBeforeEncryptionHaveNoPassword()`) actually correct?**
  _`Credentials` has 41 INFERRED edges - model-reasoned connections that need verification._
- **Should `ServerTrustChallenge` be split into smaller, more focused modules?**
  _Cohesion score 0.1349206349206349 - nodes in this community are weakly interconnected._