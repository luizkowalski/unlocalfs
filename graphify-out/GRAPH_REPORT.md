# Graph Report - unlocalfs  (2026-11-13)

## Corpus Check
- 173 files · ~53,604 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 14 file(s) not represented in the graph (top: (none) 5, .xcstrings 5, .resolved 1)

## Summary
- 2033 nodes · 4906 edges · 121 communities (88 shown, 33 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 867 edges (avg confidence: 0.85)
- Token cost: 289,731 input · 0 output

## Graph Freshness
- Built from commit: `2bbd014f`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Traffic
- Decodable
- Foundation
- SFTPSettings
- deploy
- AppViewModel
- Testing
- .s3
- .post
- steps
- Sendable
- .sftp
- AppDelegate
- ConnectionStore
- Connection
- MacOSDesktopServices
- steps
- UnlocalFSPresentation
- DriveCondition
- View
- MountService
- withControl
- ViewModelFixture
- Drive
- MountStatus
- ConnectionEditorField
- package.json
- AppViewModel
- ConnectionField
- AppPaths
- ConnectionEditorViewModel
- .remove
- MenuBarIcon
- FixtureResources
- Provider
- ServerTrustChallenge
- FileActivity
- TrafficViewModel
- AppSearchTests
- TrafficViewModelTests
- RcloneRemote
- DriveTraffic
- .serve
- ActivityViewModel
- .validate
- SFTPFixture
- TrafficRangePicker
- ServerSideEncryption
- ControlServer
- ViewModelFactory
- TransferSummary
- withS3Drive
- DriveEjectError
- ActivityStatus
- SpeedChart
- Keychain
- .interval
- SidebarSearchField
- withSFTPDrive
- .serve
- base
- ControlFailure
- troubleshooting.md
- Backend
- UnfinishedUpload
- date
- ActivityView
- Presentation and Application
- README.md
- Direction
- .reading
- UploadCleanup
- TrafficView
- fetchActivity
- project.yml
- StubbedDrives
- updates
- CopyName
- ShareLinkExpiry
- .run
- failingStatus
- UnlocalFS
- SFTPConnectionFields
- TrafficPreset
- .quitDisconnectsEveryDriveAtTheSameTime
- StatusIndicator
- FileActionError
- State
- MemoryCredentialStorage
- UnlocalFS
- ConnectionEditor
- SFTPAuthentication
- ActivitySnapshot
- Command.swift
- AppPathsTests.swift
- .swiftlint.yml
- RcloneRemote.swift
- connection-settings.md
- drive-settings.md
- GCSConnectionFields
- .sample
- copyFiles
- encryption.md
- using-drives.md
- postBuildScripts
- getting-started.md
- test
- index.md
- tsconfig.json
- ByteCountFormatStyle+Size.swift
- FittedScrollView
- privacy.md
- PackageDescription

## God Nodes (most connected - your core abstractions)
1. `Connection` - 210 edges
2. `UnlocalFSDomain` - 98 edges
3. `Credentials` - 93 edges
4. `MountService` - 84 edges
5. `AppViewModel` - 66 edges
6. `ViewModelFixture` - 66 edges
7. `FileActivity` - 50 edges
8. `DriveGateway` - 47 edges
9. `Traffic` - 44 edges
10. `ConnectionField` - 43 edges

## Surprising Connections (you probably didn't know these)
- `Build from source` --references--> `ViewModelFactory`  [INFERRED]
  README.md → Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/ViewModelFactory.swift
- `Domain` --references--> `ConnectionField`  [INFERRED]
  docs/architecture.md → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `Infrastructure` --references--> `Credentials`  [INFERRED]
  docs/architecture.md → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `Infrastructure` --references--> `DeleteConnectionUseCase`  [INFERRED]
  docs/architecture.md → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/ConnectionUseCases.swift
- `Infrastructure` --references--> `DriveGateway`  [INFERRED]
  docs/architecture.md → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/DriveGateway.swift

## Import Cycles
- None detected.

## Communities (121 total, 33 thin omitted)

### Community 0 - "Traffic"
Cohesion: 0.06
Nodes (21): Traffic, .total, TrafficDay, RcloneProcess, TrafficCheckpoint, TrafficMeter, TrafficReading, TrafficSave (+13 more)

### Community 1 - "Decodable"
Cohesion: 0.07
Nodes (38): RcloneError, BatchResult, CodingKeys, bytes, completedAt, dstFs, error, initiated (+30 more)

### Community 2 - "Foundation"
Cohesion: 0.10
Nodes (5): Foundation, GRDB, Observation, Security, UnlocalFSDomain

### Community 3 - "SFTPSettings"
Cohesion: 0.23
Nodes (5): SFTPSettings, .agentSocketPath, .keyPath, Pending, SFTPTrustStore

### Community 4 - "deploy"
Cohesion: 0.05
Nodes (42): runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, environment, if (+34 more)

### Community 5 - "AppViewModel"
Cohesion: 0.07
Nodes (11): AppViewModel, .busy, .isConfirmingDelete, .isShowingAlert, .isShowingDisconnectFailure, .isShowingUploadsBlockingDisconnect, .selected, .unsavedTraffic (+3 more)

### Community 6 - "Testing"
Cohesion: 0.13
Nodes (5): sftpSettings(), Synchronization, Testing, UnlocalFSInfrastructure, UnlocalFSTestSupport

### Community 7 - ".s3"
Cohesion: 0.10
Nodes (4): AppPollingTests, AppQuitTests, AppViewModelTests, TestDesktopServices

### Community 8 - ".post"
Cohesion: 0.22
Nodes (4): ControlSocket, ControlUnreachable, UnixConnection, .timedOut

### Community 9 - "steps"
Cohesion: 0.06
Nodes (35): env, runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, DEVELOPER_DIR (+27 more)

### Community 10 - "Sendable"
Cohesion: 0.09
Nodes (17): Domain, ConnectionRepository, DeleteConnectionUseCase, SetAutomaticConnectUseCase, DriveGateway, ConnectDriveUseCase, Decision, disconnect (+9 more)

### Community 11 - ".sftp"
Cohesion: 0.16
Nodes (8): Credentials, .encryptionPassword, .keyPassphrase, .password, .secrets, SaveConnectionUseCase, withWorkflowFixture(), WorkflowTests

### Community 12 - "AppDelegate"
Cohesion: 0.13
Nodes (4): Notification, AppDelegate, .model, .viewModels

### Community 13 - "ConnectionStore"
Cohesion: 0.10
Nodes (9): Infrastructure, ConnectionStore, CredentialStorage, SavedConnectionRepository, configURL(), ConnectionTests, MemoryCredentialStorage, RepositoryTests (+1 more)

### Community 14 - "Connection"
Cohesion: 0.06
Nodes (16): Connection, .backend, .bucketPath, .exportsRcloneConfig, .folderPath, .usesUploadTimes, ConnectionDraft, .id (+8 more)

### Community 15 - "MacOSDesktopServices"
Cohesion: 0.12
Nodes (4): DesktopServices, RcloneConfigDestination, MacOSDesktopServices, .opensAtLogin

### Community 16 - "steps"
Cohesion: 0.07
Nodes (27): env, runs-on, steps, timeout-minutes, APPLE_ID, DEVELOPER_DIR, GH_TOKEN, PASSWORD (+19 more)

### Community 17 - "UnlocalFSPresentation"
Cohesion: 0.11
Nodes (12): AppKit, Charts, Network, ServiceManagement, SwiftUI, UniformTypeIdentifiers, ClosedRange<Date>, .formattedDays (+4 more)

### Community 18 - "DriveCondition"
Cohesion: 0.12
Nodes (13): DriveCondition, checking, connected, disconnected, ejected, .indicator, needsAttention, needsReconnect (+5 more)

### Community 19 - "View"
Cohesion: 0.17
Nodes (11): ConnectionDetail, .actions, .awsDetails, .bucketDetail, .disconnected, .logo, .notices, .sftpDetails (+3 more)

### Community 20 - "MountService"
Cohesion: 0.11
Nodes (8): Darwin, OSLog, MountService, .baseEnvironment, RcloneState, running, stopped, untracked

### Community 21 - "withControl"
Cohesion: 0.18
Nodes (6): mark(), MountSafetyTests, shutdown(), withControl(), withFixture(), statusBatch()

### Community 22 - "ViewModelFixture"
Cohesion: 0.16
Nodes (7): ConnectionEditorViewModelTests, ViewModelFixture, .paths, .rcloneCalls, .root, .service, .traffic

### Community 23 - "Drive"
Cohesion: 0.19
Nodes (8): Storage smoke tests, Drive, dump(), makeDrive(), rclone(), verifyRoundTrip(), GCSDriveTests, withOfflineDrive()

### Community 24 - "MountStatus"
Cohesion: 0.13
Nodes (5): MountStatus, .isActive, .isServing, .needsReconnect, ConnectionRulesTests

### Community 25 - "ConnectionEditorField"
Cohesion: 0.11
Nodes (10): ConnectionBucketFields, .body, ConnectionEditorField, .body, ConnectionIdentityFields, .body, .body, S3ConnectionFields (+2 more)

### Community 26 - "package.json"
Cohesion: 0.10
Nodes (18): dependencies, astro@^7.4.8, @astrojs/starlight@^0.42.10, engines, node, name, overrides, postcss-selector-parser (+10 more)

### Community 27 - "AppViewModel"
Cohesion: 0.10
Nodes (12): Activity, connected, downloading, idle, uploading, AppViewModel, .activity, Indicator (+4 more)

### Community 28 - "ConnectionField"
Cohesion: 0.11
Nodes (18): ConnectionField, accessKey, bucket, confirmation, .displayName, encryptionPassword, endpoint, folder (+10 more)

### Community 29 - "AppPaths"
Cohesion: 0.07
Nodes (10): AppPaths, .knownHosts, .sockets, .traffic, MountCommand, .arguments, .environment, .mountParameters (+2 more)

### Community 30 - "ConnectionEditorViewModel"
Cohesion: 0.15
Nodes (10): ConnectionEditorViewModel, .availableProviders, .connection, .credentials, .fieldErrors, .firstInvalidField, .initialFocus, .isLocked (+2 more)

### Community 31 - ".remove"
Cohesion: 0.08
Nodes (4): FinderServicesTests, MenuBarActivityTests, SpeedRecordingTests, ControlServers

### Community 32 - "MenuBarIcon"
Cohesion: 0.13
Nodes (9): UnlocalFSApp, .body, MenuBarIcon, .accessibilityValue, .animatesUploads, .body, .image, MenuContent (+1 more)

### Community 33 - "FixtureResources"
Cohesion: 0.18
Nodes (5): FixtureResources, Launch, requireOutput(), withFixture(), startAgent()

### Community 34 - "Provider"
Cohesion: 0.10
Nodes (17): Provider, aws, .backend, cloudflare, digitalOcean, googleCloudStorage, .id, .isGeneric (+9 more)

### Community 35 - "ServerTrustChallenge"
Cohesion: 0.16
Nodes (6): ServerTrustChallenge, .errorDescription, .server, ActivityFileName, .body, .body

### Community 37 - "FileActivity"
Cohesion: 0.11
Nodes (10): FileActivity, .finishedAt, .id, .isUpload, Sequence<FileActivity>, .folder, .isCancellable, .name (+2 more)

### Community 38 - "TrafficViewModel"
Cohesion: 0.18
Nodes (8): .unsaved, TrafficBar, .id, TrafficViewModel, .custom, .period, .recentTotal, .unit

### Community 41 - "RcloneRemote"
Cohesion: 0.19
Nodes (10): NamedRemote, Options, RcloneRemote, .cryptOptions, .environment, .gcsOptions, .namedRemotes, .options (+2 more)

### Community 42 - "DriveTraffic"
Cohesion: 0.23
Nodes (3): DriveTraffic, TrafficRepository, .total

### Community 43 - ".serve"
Cohesion: 0.19
Nodes (3): FakeStorage, .uploadCount, UploadCleanupTests

### Community 44 - "ActivityViewModel"
Cohesion: 0.18
Nodes (4): ActivityViewModel, .refreshInterval, ActivityViewModelTests, .body

### Community 46 - ".validate"
Cohesion: 0.07
Nodes (13): .serviceAccountEmail, ServiceAccountKey, Issue, String, .isBlank, ValidationResult, .fieldErrors, .isValid (+5 more)

### Community 47 - "SFTPFixture"
Cohesion: 0.23
Nodes (8): SFTPFixture, .agentSocket, .connection, .credentials, .key, .protectedKey, .served, SFTPServer

### Community 48 - "TrafficRangePicker"
Cohesion: 0.17
Nodes (11): SpeedSample, .axisLimit, .fastestDownload, .fastestUpload, Date, DayCell, .body, MonthGrid (+3 more)

### Community 49 - "ServerSideEncryption"
Cohesion: 0.11
Nodes (15): AWSSettings, S3StorageClass, glacierInstantRetrieval, .id, intelligentTiering, oneZoneInfrequentAccess, standard, standardInfrequentAccess (+7 more)

### Community 50 - "ControlServer"
Cohesion: 0.18
Nodes (3): ControlFailure, ControlRequest, ControlServer

### Community 51 - "ViewModelFactory"
Cohesion: 0.22
Nodes (5): ViewModelFactory, AppDependencies, MainView, .body, .detail

### Community 53 - "withS3Drive"
Cohesion: 0.14
Nodes (4): S3DriveTests, S3Server, withS3Drive(), waitUntil()

### Community 54 - "DriveEjectError"
Cohesion: 0.28
Nodes (4): DriveEjectError, .errorDescription, UploadsPendingError, .errorDescription

### Community 55 - "ActivityStatus"
Cohesion: 0.22
Nodes (7): ActivityStatus, .body, .movingText, .progress, FailedUploadButton, .body, .details

### Community 56 - "SpeedChart"
Cohesion: 0.36
Nodes (3): SpeedChart, .body, .selectedSample

### Community 58 - ".interval"
Cohesion: 0.19
Nodes (7): ClosedRange<Date>, DateInterval, TrafficPeriod, custom, last12Months, last30Days, last90Days

### Community 59 - "SidebarSearchField"
Cohesion: 0.12
Nodes (11): DriveManagementItems, .body, ConnectionRow, .body, .icon, .sidebar, FocusedValues, SidebarSearchField (+3 more)

### Community 60 - "withSFTPDrive"
Cohesion: 0.21
Nodes (7): SFTPDriveTests, SFTPLogin, agent, key, password, protectedKey, withSFTPDrive()

### Community 62 - "base"
Cohesion: 0.15
Nodes (13): ARCHS, ASSETCATALOG_COMPILER_APPICON_NAME, CODE_SIGN_STYLE, CURRENT_PROJECT_VERSION, ENABLE_HARDENED_RUNTIME, ENABLE_USER_SCRIPT_SANDBOXING, INFOPLIST_FILE, MARKETING_VERSION (+5 more)

### Community 63 - "ControlFailure"
Cohesion: 0.36
Nodes (4): CryptoKit, FetchError, run(), setting()

### Community 64 - "troubleshooting.md"
Cohesion: 0.17
Nodes (11): A connection test fails, A drive cannot eject, A drive needs reconnecting, A Google Cloud Storage connection fails, An SFTP connection fails, Changes from another app do not appear, Files download when you did not open them, Finder adds .DS_Store files (+3 more)

### Community 65 - "Backend"
Cohesion: 0.17
Nodes (10): Backend, gcs, .locksFolderAfterSave, s3Compatible, sftp, .supportsMultiThreadUploads, .supportsServerCopy, .supportsShareLinks (+2 more)

### Community 68 - "ActivityView"
Cohesion: 0.23
Nodes (7): ActivityTable, ActivityView, .activity, .idle, .body, ServerTrustSheet, .body

### Community 69 - "Presentation and Application"
Cohesion: 0.29
Nodes (6): Clean Architecture with MVVM, Presentation and Application, Verification, UploadCancellation, .message, .title

### Community 70 - "README.md"
Cohesion: 0.18
Nodes (7): Documentation site, Build from source, Documentation, Documentation development, Features, Install, License

### Community 71 - "Direction"
Cohesion: 0.11
Nodes (11): Direction, .color, download, .fill, .label, .symbol, upload, ShareBar (+3 more)

### Community 73 - "UploadCleanup"
Cohesion: 0.24
Nodes (4): AppViewModel, UploadCleanup, .message, .title

### Community 74 - "TrafficView"
Cohesion: 0.18
Nodes (9): TrafficChart, .body, TrafficList, .body, TrafficView, .body, .heading, .periodPicker (+1 more)

### Community 76 - "project.yml"
Cohesion: 0.18
Nodes (10): macOS, name, options, deploymentTarget, postGenCommand, packages, UnlocalFSCore, settings (+2 more)

### Community 77 - "StubbedDrives"
Cohesion: 0.22
Nodes (6): Fixture notes, Tests, What to test, When a test fails, StubbedDrives, .rcloneCalls

### Community 78 - "updates"
Cohesion: 0.20
Nodes (9): interval, time, timezone, updates, directory, open-pull-requests-limit, package-ecosystem, schedule (+1 more)

### Community 80 - "ShareLinkExpiry"
Cohesion: 0.22
Nodes (6): ShareLinkExpiry, day, hour, .title, week, AppViewModel

### Community 81 - ".run"
Cohesion: 0.19
Nodes (3): AppError, Command, CommandTests

### Community 83 - "UnlocalFS"
Cohesion: 0.20
Nodes (10): Debug, Release, package, product, UnlocalFS, configFiles, dependencies, platform (+2 more)

### Community 84 - "SFTPConnectionFields"
Cohesion: 0.29
Nodes (4): SFTPConnectionFields, .authenticationHelp, .authenticationSection, .body

### Community 85 - "TrafficPreset"
Cohesion: 0.20
Nodes (8): TrafficPreset, last7Days, lastMonth, thisMonth, thisYear, today, yesterday, .title

### Community 87 - "StatusIndicator"
Cohesion: 0.40
Nodes (3): .header, StatusIndicator, .body

### Community 89 - "State"
Cohesion: 0.29
Nodes (7): State, downloaded, downloading, failed, queued, uploaded, uploading

### Community 91 - "UnlocalFS"
Cohesion: 0.25
Nodes (8): config, targets, config, schemes, UnlocalFS, archive, build, run

### Community 92 - "ConnectionEditor"
Cohesion: 0.24
Nodes (3): ConnectionEditor, .advancedSection, .body

### Community 94 - "SFTPAuthentication"
Cohesion: 0.17
Nodes (10): SFTPAuthentication, agent, .id, password, privateKey, .title, Pane, connection (+2 more)

### Community 95 - "ActivitySnapshot"
Cohesion: 0.29
Nodes (6): ActivitySnapshot, checking, .files, idle, transfers, unavailable

### Community 98 - ".swiftlint.yml"
Cohesion: 0.29
Nodes (6): disabled_rules, included, line_length, trailing_comma, mandatory_comma, type_body_length

### Community 100 - "connection-settings.md"
Cohesion: 0.33
Nodes (5): Credentials, Google Cloud Storage, SFTP, Storage, Test and save

### Community 101 - "drive-settings.md"
Cohesion: 0.33
Nodes (5): Advanced, Amazon S3, Cache, Encryption, General

### Community 105 - "copyFiles"
Cohesion: 0.33
Nodes (6): copyFiles, destination, subpath, buildPhase, path, sources

### Community 107 - "encryption.md"
Cohesion: 0.40
Nodes (4): Recover a Google Cloud Storage drive, Recover an SFTP drive, Recover files without UnlocalFS, Server-side encryption

### Community 108 - "using-drives.md"
Cohesion: 0.40
Nodes (4): Clean up unfinished uploads, Finder files and dates, Menu bar and quitting, Shortcuts

### Community 114 - "postBuildScripts"
Cohesion: 0.40
Nodes (5): basedOnDependencyAnalysis, name, script, shell, postBuildScripts

### Community 115 - "getting-started.md"
Cohesion: 0.50
Nodes (3): Connect a drive, Install, Open at login

### Community 117 - "test"
Cohesion: 0.50
Nodes (4): package, config, targets, test

## Knowledge Gaps
- **257 isolated node(s):** `PackageDescription`, `standard`, `intelligentTiering`, `standardInfrequentAccess`, `oneZoneInfrequentAccess` (+252 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 653 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **33 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Connection` connect `Connection` to `Traffic`, `Decodable`, `SFTPSettings`, `AppViewModel`, `.s3`, `Sendable`, `.sftp`, `ConnectionStore`, `MacOSDesktopServices`, `View`, `withControl`, `ViewModelFixture`, `Drive`, `MountStatus`, `AppViewModel`, `AppPaths`, `ConnectionEditorViewModel`, `.remove`, `MenuBarIcon`, `Provider`, `ServerTrustChallenge`, `.execute`, `FileActivity`, `TrafficViewModel`, `TrafficViewModelTests`, `RcloneRemote`, `.serve`, `ActivityViewModel`, `.control`, `.validate`, `SFTPFixture`, `ServerSideEncryption`, `SidebarSearchField`, `Backend`, `UnfinishedUpload`, `ActivityView`, `Presentation and Application`, `UploadCleanup`, `.run`, `RcloneRemote.swift`?**
  _High betweenness centrality (0.220) - this node is a cross-community bridge._
- **Are the 9 inferred relationships involving `Connection` (e.g. with `AWSSettings` and `SFTPSettings`) actually correct?**
  _`Connection` has 9 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `standard`, `intelligentTiering` to the rest of the system?**
  _257 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Traffic` be split into smaller, more focused modules?**
  _Cohesion score 0.05860805860805861 - nodes in this community are weakly interconnected._
- **Why does `AppError` connect `.run` to `Decodable`, `SFTPSettings`, `.s3`, `.post`, `Sendable`, `.sftp`, `ConnectionStore`, `Connection`, `ViewModelFixture`, `MountStatus`, `AppPaths`, `FixtureResources`, `Provider`, `.execute`, `RcloneRemote`, `.control`, `.validate`, `withS3Drive`, `DriveEjectError`, `Keychain`?**
  _High betweenness centrality (0.083) - this node is a cross-community bridge._
- **Are the 42 inferred relationships involving `Credentials` (e.g. with `Infrastructure` and `ConnectionEditorViewModel`) actually correct?**
  _`Credentials` has 42 INFERRED edges - model-reasoned connections that need verification._
- **Should `Decodable` be split into smaller, more focused modules?**
  _Cohesion score 0.07080200501253132 - nodes in this community are weakly interconnected._