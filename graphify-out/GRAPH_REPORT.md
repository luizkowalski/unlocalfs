# Graph Report - unlocalfs  (2026-11-13)

## Corpus Check
- 186 files · ~59,127 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 14 file(s) not represented in the graph (top: (none) 5, .xcstrings 5, .resolved 1)

## Summary
- 2120 nodes · 5045 edges · 151 communities (90 shown, 61 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 885 edges (avg confidence: 0.86)
- Token cost: 289,731 input · 0 output

## Graph Freshness
- Built from commit: `aa896f45`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- AppViewModel
- .remote
- SFTPTrustStore
- View Model Test Fixtures
- Foundation Module Imports
- AppViewModel
- Test Module Dependencies
- Google Sign In Tests
- Connection
- Build and Test Workflow
- Sendable
- Traffic Display Calculations
- Traffic Date Ranges
- Application Module Imports
- Connection
- Release Build Workflow
- Finder Service Actions
- TrafficRangePicker
- MountStatus
- .exportKeepsHostVerificationAndNeedsNoLocalFiles
- Connection Editor Tests
- withControl
- Upload Safety Tests
- Connection Workflow Tests
- ActivityViewModel
- Transfer Response Models
- Remote Response Decoding
- Traffic Database Storage
- Storage Provider Selection
- Drive Condition Priority
- Speed Chart Display
- GoogleToken
- Traffic Counter Accounting
- Unix Control Socket
- ConnectionStore
- Documentation Site Build
- ControlServer
- FileActivity
- Polling and Desktop Feedback
- Drive Detail Notices
- Storage Smoke Fixtures
- Process Test Resources
- Connection Field Names
- Connection Editor State
- Traffic Checkpoint Models
- Connection Form Fields
- SFTP Server Fixtures
- MacOSDesktopServices
- Control Socket Test Server
- Storage Recovery Architecture
- .connect
- .validate
- MountService
- AppViewModel
- S3 Drive Smoke Tests
- Activity Table Views
- AppPaths
- Traffic Status Tests
- SFTP Authentication Options
- AWS Encryption Settings
- Menu Bar Status
- Keychain Credential Storage
- Validation Issue Collection
- MountStatus
- waitUntil
- Upload Cancellation Tests
- Traffic View Model Tests
- Xcode Build Settings
- Application Layer Boundaries
- Troubleshooting Guide
- Drive Error Messages
- Storage Backend Capabilities
- Safe Application Quit
- .connect
- GCS Authentication Settings
- State
- ConnectionDraft
- .run
- fetch-rclone.swift
- Xcode Project Structure
- Traffic Total Statistics
- ViewModelFactory
- GCS Credential Fields
- Dependency Update Schedule
- Duplicate File Naming
- LockableCredentialStorage
- .serve
- App Target Configuration
- AppViewModel
- AppError
- UnfinishedUpload
- Concurrent Quit Tests
- Rclone Download Script
- Encryption and Local Data
- S3 Storage Classes
- .gcs
- SFTP Login Fixtures
- .serve
- awsFixture
- Google Authorization Guide
- FileActivity
- .run
- Mount Command Configuration
- Activity Panel States
- Locked Credential Fixtures
- SidebarItem
- ControlServers
- Activity and Traffic Presentation
- Product and Testing Principles
- SFTPSettings
- Drive Settings Guide
- ServerTrustChallenge
- ByteCountFormatStyle+Size.swift
- TrafficPreset
- UploadCleanup
- Drive Path Mapping
- AppError
- MountService+Process.swift
- Activity Status Text
- Google Sign In Controls
- SpeedSample
- Helper Embedding Phase
- AppViewModel
- AppPollingTests
- AppViewModel
- MemoryCredentialStorage

## God Nodes (most connected - your core abstractions)
1. `Connection` - 216 edges
2. `Credentials` - 105 edges
3. `UnlocalFSDomain` - 101 edges
4. `MountService` - 93 edges
5. `ViewModelFixture` - 72 edges
6. `AppViewModel` - 49 edges
7. `DriveGateway` - 47 edges
8. `Traffic` - 44 edges
9. `ConnectionField` - 44 edges
10. `ConnectionEditorViewModel` - 42 edges

## Surprising Connections (you probably didn't know these)
- `Build from source` --references--> `ViewModelFactory`  [INFERRED]
  README.md → Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/ViewModelFactory.swift
- `Domain` --references--> `ConnectionField`  [INFERRED]
  docs/architecture.md → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `Domain` --references--> `ConnectionRepository`  [INFERRED]
  docs/architecture.md → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/ConnectionRepository.swift
- `Domain` --references--> `DriveGateway`  [INFERRED]
  docs/architecture.md → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/DriveGateway.swift
- `Domain` --references--> `TrafficMeter`  [INFERRED]
  docs/architecture.md → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/TrafficMeter.swift

## Import Cycles
- None detected.

## Communities (151 total, 61 thin omitted)

### Community 0 - "AppViewModel"
Cohesion: 0.28
Nodes (4): Traffic, .total, TrafficMeter, TrafficMeterTests

### Community 1 - ".remote"
Cohesion: 0.05
Nodes (42): OSLog, TrafficTracker, UploadTally, BatchResult, CodingKeys, bytes, completedAt, dstFs (+34 more)

### Community 2 - "SFTPTrustStore"
Cohesion: 0.07
Nodes (10): Darwin, Foundation, GRDB, Observation, String, .expandingTilde, Security, FormatStyle (+2 more)

### Community 4 - "Foundation Module Imports"
Cohesion: 0.05
Nodes (42): runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, environment, if (+34 more)

### Community 5 - "AppViewModel"
Cohesion: 0.10
Nodes (8): AppViewModel, .busy, .isConfirmingDelete, .isShowingAlert, .isShowingDisconnectFailure, .isShowingUploadsBlockingDisconnect, .selected, .unsavedTraffic

### Community 6 - "Test Module Dependencies"
Cohesion: 0.11
Nodes (4): Synchronization, Testing, UnlocalFSInfrastructure, UnlocalFSTestSupport

### Community 9 - "Build and Test Workflow"
Cohesion: 0.06
Nodes (35): env, runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, DEVELOPER_DIR (+27 more)

### Community 10 - "Sendable"
Cohesion: 0.13
Nodes (8): ConnectionRepository, DeleteConnectionUseCase, SetAutomaticConnectUseCase, ConnectDriveUseCase, QuitUseCase, DuplicateFilesUseCase, ExportRcloneConfigUseCase, ShareFilesUseCase

### Community 11 - "Traffic Display Calculations"
Cohesion: 0.19
Nodes (3): SaveConnectionUseCase, withWorkflowFixture(), WorkflowTests

### Community 12 - "Traffic Date Ranges"
Cohesion: 0.15
Nodes (3): AppDelegate, .model, .viewModels

### Community 13 - "Application Module Imports"
Cohesion: 0.16
Nodes (7): Infrastructure, ConnectionStore, CredentialStorage, SavedConnectionRepository, MemoryCredentialStorage, RepositoryTests, UnavailableCredentialStorage

### Community 14 - "Connection"
Cohesion: 0.06
Nodes (13): Connection, .backend, .bucketPath, .exportsRcloneConfig, .folderPath, .usesGoogleSignIn, .usesUploadTimes, DriveGateway (+5 more)

### Community 15 - "Release Build Workflow"
Cohesion: 0.12
Nodes (4): DesktopServices, RcloneConfigDestination, MacOSDesktopServices, .opensAtLogin

### Community 16 - "Finder Service Actions"
Cohesion: 0.07
Nodes (27): env, runs-on, steps, timeout-minutes, APPLE_ID, DEVELOPER_DIR, GH_TOKEN, PASSWORD (+19 more)

### Community 17 - "TrafficRangePicker"
Cohesion: 0.13
Nodes (8): AppKit, Charts, Network, ServiceManagement, SwiftUI, UniformTypeIdentifiers, UnlocalFSPresentation, UserNotifications

### Community 18 - "MountStatus"
Cohesion: 0.12
Nodes (13): DriveCondition, checking, connected, disconnected, ejected, .indicator, needsAttention, needsReconnect (+5 more)

### Community 19 - ".exportKeepsHostVerificationAndNeedsNoLocalFiles"
Cohesion: 0.17
Nodes (12): ConnectionDetail, .awsDetails, .bucketDetail, .disconnected, .logo, .notices, .sftpDetails, .storageName (+4 more)

### Community 21 - "withControl"
Cohesion: 0.17
Nodes (6): mark(), MountSafetyTests, shutdown(), withControl(), withFixture(), statusBatch()

### Community 22 - "Upload Safety Tests"
Cohesion: 0.12
Nodes (7): Credentials, .encryptionPassword, .isSignedInToGoogle, .keyPassphrase, .password, .secrets, ConnectionEditorViewModelTests

### Community 23 - "Connection Workflow Tests"
Cohesion: 0.20
Nodes (7): Storage smoke tests, Drive, dump(), makeDrive(), rclone(), verifyRoundTrip(), withOfflineDrive()

### Community 24 - "ActivityViewModel"
Cohesion: 0.20
Nodes (6): DriveEjectError, .errorDescription, UploadsPendingError, .errorDescription, ControlUnreachable, .timedOut

### Community 25 - "Transfer Response Models"
Cohesion: 0.12
Nodes (11): ConnectionBucketFields, .body, ConnectionEditorField, .body, ConnectionIdentityFields, .body, GCSConnectionFields, .body (+3 more)

### Community 26 - "Remote Response Decoding"
Cohesion: 0.10
Nodes (18): dependencies, astro@^7.4.8, @astrojs/starlight@^0.42.10, engines, node, name, overrides, postcss-selector-parser (+10 more)

### Community 28 - "Storage Provider Selection"
Cohesion: 0.09
Nodes (21): ConnectionField, accessKey, bucket, confirmation, .displayName, encryptionPassword, endpoint, folder (+13 more)

### Community 29 - "Drive Condition Priority"
Cohesion: 0.13
Nodes (10): AppPaths, .knownHosts, .sockets, .traffic, MountCommand, .arguments, .environment, .mountParameters (+2 more)

### Community 30 - "Speed Chart Display"
Cohesion: 0.15
Nodes (10): ConnectionEditorViewModel, .connection, .credentials, .fieldErrors, .firstInvalidField, .initialFocus, .isLocked, .locksRemoteFolder (+2 more)

### Community 32 - "Traffic Counter Accounting"
Cohesion: 0.21
Nodes (5): MenuBarIcon, .accessibilityValue, .animatesUploads, .body, .image

### Community 33 - "Unix Control Socket"
Cohesion: 0.17
Nodes (4): FixtureResources, Launch, requireOutput(), withFixture()

### Community 34 - "ConnectionStore"
Cohesion: 0.12
Nodes (16): Provider, aws, .backend, cloudflare, digitalOcean, googleCloudStorage, .id, .isGeneric (+8 more)

### Community 35 - "Documentation Site Build"
Cohesion: 0.22
Nodes (3): ServerTrustChallenge, .errorDescription, .server

### Community 36 - "ControlServer"
Cohesion: 0.17
Nodes (4): revokedDrive(), ControlFailure, ControlRequest, ControlServer

### Community 37 - "FileActivity"
Cohesion: 0.09
Nodes (11): FileActivity, .finishedAt, .id, .isUpload, Sequence<FileActivity>, .hasFailed, .rank, TransferSummary (+3 more)

### Community 38 - "Polling and Desktop Feedback"
Cohesion: 0.11
Nodes (14): TrafficBar, .id, TrafficViewModel, .custom, .period, .recentTotal, .unit, TrafficChart (+6 more)

### Community 39 - "Drive Detail Notices"
Cohesion: 0.11
Nodes (9): AppSearchTests, FinderServicesTests, ViewModelFixture, .paths, .rcloneCalls, .root, .service, .signInEnvironment (+1 more)

### Community 41 - "Process Test Resources"
Cohesion: 0.11
Nodes (15): GoogleClient, NamedRemote, Options, RcloneRemote, .cryptOptions, .environment, .gcsOptions, .namedRemotes (+7 more)

### Community 42 - "Connection Field Names"
Cohesion: 0.10
Nodes (8): Domain, DriveTraffic, TrafficDay, TrafficRepository, TrafficStore, .migrator, .total, TrafficStoreTests

### Community 43 - "Connection Editor State"
Cohesion: 0.18
Nodes (3): FakeStorage, .uploadCount, UploadCleanupTests

### Community 44 - "Traffic Checkpoint Models"
Cohesion: 0.17
Nodes (6): ActivityViewModel, .refreshInterval, FileActivity, .folder, .isCancellable, .name

### Community 46 - "Connection Form Fields"
Cohesion: 0.18
Nodes (3): .serviceAccountEmail, ServiceAccountKey, GCSValidationTests

### Community 47 - "SFTP Server Fixtures"
Cohesion: 0.21
Nodes (9): SFTPFixture, .agentSocket, .connection, .credentials, .key, .protectedKey, .served, SFTPServer (+1 more)

### Community 48 - "MacOSDesktopServices"
Cohesion: 0.09
Nodes (19): State, downloaded, downloading, failed, queued, uploaded, uploading, UnfinishedUpload (+11 more)

### Community 49 - "Control Socket Test Server"
Cohesion: 0.19
Nodes (7): AWSSettings, ServerSideEncryption, .id, kms, s3Managed, .title, Config

### Community 51 - "Storage Recovery Architecture"
Cohesion: 0.11
Nodes (8): Issue, String, .isBlank, ValidationResult, .fieldErrors, .isValid, ConnectionValidationTests, SFTPValidationTests

### Community 53 - ".validate"
Cohesion: 0.22
Nodes (3): S3DriveTests, S3Server, withS3Drive()

### Community 55 - "MountService"
Cohesion: 0.20
Nodes (7): ActivityStatus, .body, .movingText, .progress, FailedUploadButton, .body, .details

### Community 58 - "Activity Table Views"
Cohesion: 0.10
Nodes (17): ClosedRange<Date>, DateInterval, TrafficPeriod, custom, last12Months, last30Days, last90Days, TrafficPreset (+9 more)

### Community 59 - "AppPaths"
Cohesion: 0.12
Nodes (11): .actions, DriveManagementItems, .body, ConnectionRow, .body, .sidebar, FocusedValues, SidebarSearchField (+3 more)

### Community 60 - "Traffic Status Tests"
Cohesion: 0.21
Nodes (7): SFTPDriveTests, SFTPLogin, agent, key, password, protectedKey, withSFTPDrive()

### Community 62 - "AWS Encryption Settings"
Cohesion: 0.15
Nodes (13): ARCHS, ASSETCATALOG_COMPILER_APPICON_NAME, CODE_SIGN_STYLE, CURRENT_PROJECT_VERSION, ENABLE_HARDENED_RUNTIME, ENABLE_USER_SCRIPT_SANDBOXING, INFOPLIST_FILE, MARKETING_VERSION (+5 more)

### Community 63 - "Menu Bar Status"
Cohesion: 0.25
Nodes (7): BatchReply, .current, counters(), finished(), reply(), TrafficTests, withRclone()

### Community 64 - "Keychain Credential Storage"
Cohesion: 0.17
Nodes (11): A connection test fails, A drive cannot eject, A drive needs reconnecting, A Google Cloud Storage connection fails, An SFTP connection fails, Changes from another app do not appear, Files download when you did not open them, Finder adds .DS_Store files (+3 more)

### Community 65 - "Validation Issue Collection"
Cohesion: 0.17
Nodes (10): Backend, gcs, .locksFolderAfterSave, s3Compatible, sftp, .supportsMultiThreadUploads, .supportsServerCopy, .supportsShareLinks (+2 more)

### Community 66 - "MountStatus"
Cohesion: 0.22
Nodes (4): MountStatus, .isActive, .isServing, .needsReconnect

### Community 67 - "waitUntil"
Cohesion: 0.13
Nodes (12): Decision, disconnect, quit, wait, Outcome, connected, ejected, RcloneProcess (+4 more)

### Community 68 - "Upload Cancellation Tests"
Cohesion: 0.14
Nodes (10): ActivityFileName, .body, ActivityTable, .body, ActivityView, .activity, .idle, .body (+2 more)

### Community 69 - "Traffic View Model Tests"
Cohesion: 0.17
Nodes (7): Clean Architecture with MVVM, Presentation and Application, Verification, UploadCancellation, .message, .title, .body

### Community 70 - "Xcode Build Settings"
Cohesion: 0.22
Nodes (7): Documentation site, Build from source, Documentation, Documentation development, Features, Install, License

### Community 71 - "Application Layer Boundaries"
Cohesion: 0.13
Nodes (10): Direction, .color, download, .fill, .label, .symbol, upload, SpeedChart (+2 more)

### Community 73 - "Drive Error Messages"
Cohesion: 0.24
Nodes (4): AppViewModel, UploadCleanup, .message, .title

### Community 74 - "Storage Backend Capabilities"
Cohesion: 0.17
Nodes (9): .icon, ProviderIcon, .body, ShareBar, .body, TrafficList, .body, TrafficStats (+1 more)

### Community 76 - "Safe Application Quit"
Cohesion: 0.18
Nodes (10): macOS, name, options, deploymentTarget, postGenCommand, packages, UnlocalFSCore, settings (+2 more)

### Community 77 - ".connect"
Cohesion: 0.11
Nodes (10): Fixture notes, Tests, What to test, When a test fails, controlCalls(), failingStatus(), ServiceRecoveryTests, withRevokedDrive() (+2 more)

### Community 78 - "GCS Authentication Settings"
Cohesion: 0.20
Nodes (9): interval, time, timezone, updates, directory, open-pull-requests-limit, package-ecosystem, schedule (+1 more)

### Community 80 - "ConnectionDraft"
Cohesion: 0.22
Nodes (6): ShareLinkExpiry, day, hour, .title, week, AppViewModel

### Community 82 - "fetch-rclone.swift"
Cohesion: 0.36
Nodes (4): CryptoKit, FetchError, run(), setting()

### Community 83 - "Xcode Project Structure"
Cohesion: 0.20
Nodes (10): Debug, Release, package, product, UnlocalFS, configFiles, dependencies, platform (+2 more)

### Community 84 - "Traffic Total Statistics"
Cohesion: 0.29
Nodes (4): SFTPConnectionFields, .authenticationHelp, .authenticationSection, .body

### Community 85 - "ViewModelFactory"
Cohesion: 0.32
Nodes (3): ViewModelFactory, AppDependencies, .body

### Community 86 - "GCS Credential Fields"
Cohesion: 0.22
Nodes (3): AppQuitTests, Overlap, .peak

### Community 87 - "Dependency Update Schedule"
Cohesion: 0.40
Nodes (3): .header, StatusIndicator, .body

### Community 91 - "App Target Configuration"
Cohesion: 0.25
Nodes (8): config, targets, config, schemes, UnlocalFS, archive, build, run

### Community 93 - "AppError"
Cohesion: 0.25
Nodes (8): S3StorageClass, glacierInstantRetrieval, .id, intelligentTiering, oneZoneInfrequentAccess, standard, standardInfrequentAccess, .title

### Community 94 - "UnfinishedUpload"
Cohesion: 0.17
Nodes (10): SFTPAuthentication, agent, .id, password, privateKey, .title, Pane, connection (+2 more)

### Community 95 - "Concurrent Quit Tests"
Cohesion: 0.29
Nodes (6): ActivitySnapshot, checking, .files, idle, transfers, unavailable

### Community 98 - "S3 Storage Classes"
Cohesion: 0.29
Nodes (6): disabled_rules, included, line_length, trailing_comma, mandatory_comma, type_body_length

### Community 100 - "SFTP Login Fixtures"
Cohesion: 0.33
Nodes (5): Credentials, Google Cloud Storage, SFTP, Storage, Test and save

### Community 101 - ".serve"
Cohesion: 0.33
Nodes (5): Advanced, Amazon S3, Cache, Encryption, General

### Community 105 - ".run"
Cohesion: 0.33
Nodes (6): copyFiles, destination, subpath, buildPhase, path, sources

### Community 107 - "Activity Panel States"
Cohesion: 0.40
Nodes (4): Recover a Google Cloud Storage drive, Recover an SFTP drive, Recover files without UnlocalFS, Server-side encryption

### Community 108 - "Locked Credential Fixtures"
Cohesion: 0.40
Nodes (4): Clean up unfinished uploads, Finder files and dates, Menu bar and quitting, Shortcuts

### Community 109 - "SidebarItem"
Cohesion: 0.40
Nodes (3): SidebarItem, drive, traffic

### Community 111 - "Activity and Traffic Presentation"
Cohesion: 0.22
Nodes (6): UnlocalFSApp, .body, MainView, .detail, MenuContent, .body

### Community 112 - "Product and Testing Principles"
Cohesion: 0.29
Nodes (3): ConnectionDraft, .id, .isDuplicate

### Community 114 - "Drive Settings Guide"
Cohesion: 0.40
Nodes (5): basedOnDependencyAnalysis, name, script, shell, postBuildScripts

### Community 115 - "ServerTrustChallenge"
Cohesion: 0.50
Nodes (3): Connect a drive, Install, Open at login

### Community 117 - "TrafficPreset"
Cohesion: 0.50
Nodes (4): package, config, targets, test

### Community 121 - "MountService+Process.swift"
Cohesion: 0.40
Nodes (4): RcloneState, running, stopped, untracked

### Community 122 - "Activity Status Text"
Cohesion: 0.40
Nodes (5): Activity, connected, downloading, idle, uploading

### Community 130 - "Helper Embedding Phase"
Cohesion: 0.40
Nodes (5): Indicator, attention, connected, idle, working

### Community 131 - "AppViewModel"
Cohesion: 0.40
Nodes (4): ClosedRange<Date>, .formattedDays, DateInterval, .formattedDays

## Knowledge Gaps
- **261 isolated node(s):** `idle`, `connected`, `uploading`, `downloading`, `working` (+256 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 687 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **61 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Connection` connect `Connection` to `.remote`, `SFTPTrustStore`, `AppViewModel`, `Google Sign In Tests`, `Sendable`, `Traffic Display Calculations`, `Application Module Imports`, `Release Build Workflow`, `.exportKeepsHostVerificationAndNeedsNoLocalFiles`, `Connection Editor Tests`, `withControl`, `Upload Safety Tests`, `Connection Workflow Tests`, `Traffic Database Storage`, `Drive Condition Priority`, `Speed Chart Display`, `Polling and Desktop Feedback`, `Storage Smoke Fixtures`, `Process Test Resources`, `Connection Field Names`, `Connection Editor State`, `Traffic Checkpoint Models`, `.unmount`, `SFTP Server Fixtures`, `Control Socket Test Server`, `Storage Recovery Architecture`, `.connect`, `Remote File Actions`, `AppViewModel`, `AppPaths`, `Menu Bar Status`, `Validation Issue Collection`, `MountStatus`, `waitUntil`, `Upload Cancellation Tests`, `Traffic View Model Tests`, `Drive Error Messages`, `.connect`, `.serve`, `AppViewModel`, `.gcs`, `awsFixture`, `Google Authorization Guide`, `ControlServers`, `Activity and Traffic Presentation`, `Product and Testing Principles`, `ByteCountFormatStyle+Size.swift`, `AppError`?**
  _High betweenness centrality (0.237) - this node is a cross-community bridge._
- **Are the 8 inferred relationships involving `Connection` (e.g. with `AWSSettings` and `SFTPSettings`) actually correct?**
  _`Connection` has 8 INFERRED edges - model-reasoned connections that need verification._
- **What connects `idle`, `connected`, `uploading` to the rest of the system?**
  _261 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `.remote` be split into smaller, more focused modules?**
  _Cohesion score 0.053830227743271224 - nodes in this community are weakly interconnected._
- **Why does `Credentials` connect `Upload Safety Tests` to `.remote`, `Google Sign In Tests`, `Sendable`, `Traffic Display Calculations`, `Application Module Imports`, `Connection`, `MemoryCredentialStorage`, `Connection Editor Tests`, `withControl`, `Connection Workflow Tests`, `Drive Condition Priority`, `Speed Chart Display`, `Drive Detail Notices`, `Storage Smoke Fixtures`, `Process Test Resources`, `Connection Form Fields`, `SFTP Server Fixtures`, `Control Socket Test Server`, `Storage Recovery Architecture`, `.connect`, `.validate`, `S3 Drive Smoke Tests`, `waitUntil`, `.connect`, `LockableCredentialStorage`, `.gcs`, `Google Authorization Guide`, `AppError`?**
  _High betweenness centrality (0.065) - this node is a cross-community bridge._
- **Are the 42 inferred relationships involving `Credentials` (e.g. with `Infrastructure` and `ConnectionEditorViewModel`) actually correct?**
  _`Credentials` has 42 INFERRED edges - model-reasoned connections that need verification._
- **Should `SFTPTrustStore` be split into smaller, more focused modules?**
  _Cohesion score 0.06868686868686869 - nodes in this community are weakly interconnected._