# Graph Report - unlocalfs  (2026-11-13)

## Corpus Check
- 205 files · ~59,127 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 14 file(s) not represented in the graph (top: (none) 5, .xcstrings 5, .resolved 1)

## Summary
- 2166 nodes · 5063 edges · 151 communities (94 shown, 57 thin omitted)
- Extraction: 83% EXTRACTED · 17% INFERRED · 0% AMBIGUOUS · INFERRED: 873 edges (avg confidence: 0.86)
- Token cost: host-agent semantic usage unavailable; structural extraction uses no model tokens.

## Community Hubs (Navigation)
- Transfer Response Decoding
- View Model Fixtures
- Saved Connection Workflows
- Credential Transactions
- Drive Safety Conditions
- Foundation Module Imports
- Documentation Deployment
- Connection Storage Options
- Traffic Display Totals
- Drive Gateway Workflows
- Mount Process Shutdown
- Build Test Workflow
- Test Module Dependencies
- Connection Editor Tests
- Traffic Date Ranges
- App State Dependencies
- File Activity Values
- Connection Detail Views
- Release Build Workflow
- Finder Service Dispatch
- Calendar Date Picker
- Mount Command Paths
- Polling Feedback Tests
- Upload Safety Tests
- Traffic Database Storage
- Desktop File Dialogs
- Connection Form Fields
- Speed Chart Display
- UI Module Imports
- Remote File Actions
- Traffic Counter Accounting
- Documentation Site Build
- Storage Smoke Fixtures
- Rclone Remote Configuration
- Connection Field Names
- Connection Editor State
- Unix Control Socket
- Connection Input Validation
- Drive Action Availability
- Process Test Resources
- Activity Polling
- Application Layer Boundaries
- Traffic Checkpoint Models
- Storage Provider Selection
- Server Trust Challenges
- SFTP Server Fixtures
- Control Socket Fixtures
- Fake Storage Server
- Mount Service Operations
- Validation Issue Collection
- Mount Service Extensions
- SFTP Host Trust
- S3 Drive Tests
- AWS Encryption Settings
- Service Account Parsing
- Application Platform Imports
- S3 Storage Classes
- Menu Bar Status
- Keychain Credential Storage
- SFTP Authentication Options
- Drive Lifecycle Actions
- Drive Status Polling
- Revoked Access Recovery
- Upload Cancellation Tests
- Traffic View Model Tests
- Xcode Build Settings
- Activity Status Views
- Troubleshooting Guide
- Storage Backend Capabilities
- Saved Data Compatibility
- SFTP Drive Tests
- Build Documentation Guides
- Lifecycle Extension Architecture
- Testing Principles Fixtures
- Connection Editor Form
- Activity Reporting Tests
- Xcode Project Structure
- Drive Management Controls
- Main Window Navigation
- SFTP Authentication Fields
- Dependency Update Schedule
- Unfinished Upload Cleanup
- App Target Configuration
- Duplicate File Naming
- Command Process Execution
- Activity Panel Views
- Concurrent Quit Tests
- Application Menu Views
- Rclone Download Script
- File Transfer States
- Quit Coordination
- Sidebar Search Tests
- Application Build Schemes
- Sidebar Search Field
- Connection Draft State
- Activity Panel States
- Unavailable Status Safety
- Swift Lint Rules
- Connection Settings Guide
- Drive Settings Guide
- Sidebar Search Actions
- Drive Path Mapping
- App Resource Copying
- Encryption Recovery Guide
- Drive Usage Guide
- Sidebar Item Identity
- Menu Activity States
- Finder Sharing Actions
- Drive Status Indicators
- Helper Embedding Phase
- Server Trust Dialog
- Getting Started Guide
- Package Test Configuration
- Activity Table Views
- Product Guide Overview
- TypeScript Build Configuration
- Subprocess Module Imports
- Remote String Values
- Byte Count Formatting
- Local Privacy Guide
- Swift Package Definition
- Copy Name Tests

## God Nodes (most connected - your core abstractions)
1. `Connection` - 191 edges
2. `Credentials` - 105 edges
3. `UnlocalFSDomain` - 101 edges
4. `MountService` - 93 edges
5. `ViewModelFixture` - 72 edges

## Surprising Connections (you probably didn't know these)
- `Build from source` --references--> `ViewModelFactory`  [INFERRED]
  README.md → Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/ViewModelFactory.swift
- `Domain` --references--> `TrafficMeter`  [INFERRED]
  docs/architecture.md → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/TrafficMeter.swift
- `Domain` --references--> `ConnectionRepository`  [INFERRED]
  docs/architecture.md → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/ConnectionRepository.swift

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Clean Architecture layers** — docs_architecture_clean_architecture, docs_architecture_domain, docs_architecture_infrastructure, docs_architecture_presentation, docs_architecture_application [EXTRACTED 1.00]
- **Drive traffic reporting** — docs_architecture_mountservice, docs_architecture_trafficmeter, docs_architecture_trafficstore, docs_architecture_trafficviewmodel [EXTRACTED 1.00]
- **Live Google reauthorization** — docs_architecture_signinagainusecase, docs_architecture_mountservice, docs_architecture_google_token_transport, docs_architecture_appviewmodel [EXTRACTED 1.00]

## Communities (151 total, 57 thin omitted)

### Community 0 - "Transfer Response Decoding"
Cohesion: 0.06
Nodes (41): RcloneError, TrafficTracker, UploadTally, BatchResult, CodingKeys, bytes, completedAt, dstFs (+33 more)

### Community 1 - "View Model Fixtures"
Cohesion: 0.10
Nodes (4): ExportRcloneConfigUseCase, ActivityViewModelTests, AppViewModelTests, TestDesktopServices

### Community 2 - "Saved Connection Workflows"
Cohesion: 0.12
Nodes (10): DeleteConnectionUseCase, SaveConnectionUseCase, SetAutomaticConnectUseCase, DuplicateFilesUseCase, ShareFilesUseCase, ConnectionStore, SavedConnectionRepository, RepositoryTests (+2 more)

### Community 3 - "Credential Transactions"
Cohesion: 0.07
Nodes (12): Credentials, .encryptionPassword, .isSignedInToGoogle, .keyPassphrase, .password, .secrets, CredentialStorage, MemoryCredentialStorage (+4 more)

### Community 4 - "Drive Safety Conditions"
Cohesion: 0.05
Nodes (23): DriveEjectError, .errorDescription, MountStatus, .isActive, .isServing, .needsReconnect, UploadsPendingError, .errorDescription (+15 more)

### Community 5 - "Foundation Module Imports"
Cohesion: 0.09
Nodes (6): Darwin, Foundation, GRDB, Observation, Security, UnlocalFSDomain

### Community 6 - "Documentation Deployment"
Cohesion: 0.05
Nodes (42): runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, environment, if (+34 more)

### Community 7 - "Connection Storage Options"
Cohesion: 0.06
Nodes (13): Connection, .backend, .bucketPath, .exportsRcloneConfig, .folderPath, .usesGoogleSignIn, .usesUploadTimes, .driveStorage (+5 more)

### Community 8 - "Traffic Display Totals"
Cohesion: 0.09
Nodes (18): DriveTraffic, TrafficRepository, .unsaved, TrafficBar, .id, TrafficViewModel, .custom, .period (+10 more)

### Community 9 - "Drive Gateway Workflows"
Cohesion: 0.08
Nodes (13): ConnectionRepository, DriveGateway, ConnectDriveUseCase, Decision, disconnect, quit, wait, Outcome (+5 more)

### Community 10 - "Mount Process Shutdown"
Cohesion: 0.11
Nodes (11): RcloneState, running, stopped, untracked, BatchReply, .current, counters(), finished() (+3 more)

### Community 11 - "Build Test Workflow"
Cohesion: 0.06
Nodes (35): env, runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, DEVELOPER_DIR (+27 more)

### Community 12 - "Test Module Dependencies"
Cohesion: 0.16
Nodes (5): Synchronization, Testing, UnlocalFSInfrastructure, UnlocalFSPresentation, UnlocalFSTestSupport

### Community 13 - "Connection Editor Tests"
Cohesion: 0.11
Nodes (8): ConnectionEditorViewModelTests, ViewModelFixture, .paths, .rcloneCalls, .root, .service, .signInEnvironment, .traffic

### Community 14 - "Traffic Date Ranges"
Cohesion: 0.09
Nodes (17): ClosedRange<Date>, DateInterval, TrafficPeriod, custom, last12Months, last30Days, last90Days, TrafficPreset (+9 more)

### Community 15 - "App State Dependencies"
Cohesion: 0.09
Nodes (8): AppViewModel, .busy, .isConfirmingDelete, .isShowingAlert, .isShowingDisconnectFailure, .isShowingUploadsBlockingDisconnect, .selected, .unsavedTraffic

### Community 16 - "File Activity Values"
Cohesion: 0.12
Nodes (9): FileActivity, .finishedAt, .id, .isUpload, Sequence<FileActivity>, .hasFailed, .rank, TransferSummary (+1 more)

### Community 17 - "Connection Detail Views"
Cohesion: 0.16
Nodes (13): ConnectionDetail, .actions, .awsDetails, .bucketDetail, .disconnected, .logo, .notices, .sftpDetails (+5 more)

### Community 18 - "Release Build Workflow"
Cohesion: 0.07
Nodes (27): env, runs-on, steps, timeout-minutes, APPLE_ID, DEVELOPER_DIR, GH_TOKEN, PASSWORD (+19 more)

### Community 19 - "Finder Service Dispatch"
Cohesion: 0.13
Nodes (4): Notification, AppDelegate, .model, .viewModels

### Community 20 - "Calendar Date Picker"
Cohesion: 0.13
Nodes (12): UnfinishedUpload, SpeedSample, .axisLimit, .fastestDownload, .fastestUpload, Date, DayCell, .body (+4 more)

### Community 21 - "Mount Command Paths"
Cohesion: 0.13
Nodes (10): AppPaths, .knownHosts, .sockets, .traffic, MountCommand, .arguments, .environment, .mountParameters (+2 more)

### Community 22 - "Polling Feedback Tests"
Cohesion: 0.08
Nodes (5): AppPollingTests, FinderServicesTests, MenuBarActivityTests, SpeedRecordingTests, ControlServers

### Community 23 - "Upload Safety Tests"
Cohesion: 0.18
Nodes (5): mark(), MountSafetyTests, shutdown(), withControl(), withFixture()

### Community 24 - "Traffic Database Storage"
Cohesion: 0.14
Nodes (4): TrafficDay, TrafficStore, .migrator, TrafficStoreTests

### Community 25 - "Desktop File Dialogs"
Cohesion: 0.15
Nodes (4): DesktopServices, RcloneConfigDestination, MacOSDesktopServices, .opensAtLogin

### Community 26 - "Connection Form Fields"
Cohesion: 0.10
Nodes (10): ConnectionBucketFields, .body, ConnectionEditorField, .body, ConnectionIdentityFields, .body, GCSConnectionFields, .body (+2 more)

### Community 27 - "Speed Chart Display"
Cohesion: 0.13
Nodes (10): Direction, .color, download, .fill, .label, .symbol, upload, SpeedChart (+2 more)

### Community 28 - "UI Module Imports"
Cohesion: 0.12
Nodes (14): Charts, SwiftUI, ProviderIcon, .body, ClosedRange<Date>, .formattedDays, DateInterval, .formattedDays (+6 more)

### Community 29 - "Remote File Actions"
Cohesion: 0.13
Nodes (6): FileActionError, ShareLinkExpiry, day, hour, .title, week

### Community 30 - "Traffic Counter Accounting"
Cohesion: 0.28
Nodes (4): Traffic, .total, TrafficMeter, TrafficMeterTests

### Community 31 - "Documentation Site Build"
Cohesion: 0.10
Nodes (18): dependencies, astro@^7.4.8, @astrojs/starlight@^0.42.10, engines, node, name, overrides, postcss-selector-parser (+10 more)

### Community 32 - "Storage Smoke Fixtures"
Cohesion: 0.20
Nodes (8): Storage smoke tests, Drive, dump(), makeDrive(), rclone(), verifyRoundTrip(), GCSDriveTests, withOfflineDrive()

### Community 33 - "Rclone Remote Configuration"
Cohesion: 0.15
Nodes (14): NamedRemote, Options, RcloneRemote, .cryptOptions, .environment, .gcsOptions, .namedRemotes, .options (+6 more)

### Community 34 - "Connection Field Names"
Cohesion: 0.10
Nodes (19): ConnectionField, accessKey, bucket, confirmation, .displayName, encryptionPassword, endpoint, folder (+11 more)

### Community 35 - "Connection Editor State"
Cohesion: 0.15
Nodes (10): ConnectionEditorViewModel, .connection, .credentials, .fieldErrors, .firstInvalidField, .initialFocus, .isLocked, .locksRemoteFolder (+2 more)

### Community 36 - "Unix Control Socket"
Cohesion: 0.22
Nodes (4): ControlSocket, ControlUnreachable, UnixConnection, .timedOut

### Community 37 - "Connection Input Validation"
Cohesion: 0.16
Nodes (5): awsFixture(), AWSValidationTests, ConnectionValidationTests, sftpSettings(), SFTPValidationTests

### Community 39 - "Process Test Resources"
Cohesion: 0.18
Nodes (5): FixtureResources, Launch, requireOutput(), withFixture(), startAgent()

### Community 40 - "Activity Polling"
Cohesion: 0.13
Nodes (10): ActivityViewModel, .refreshInterval, FileActivity, .folder, .isCancellable, .name, UploadCancellation, .message (+2 more)

### Community 41 - "Application Layer Boundaries"
Cohesion: 0.12
Nodes (17): Application, Clean Architecture, Clean Architecture with MVVM, ControlSocket, Domain, File use cases, Infrastructure, MountService (+9 more)

### Community 42 - "Traffic Checkpoint Models"
Cohesion: 0.22
Nodes (4): RcloneProcess, TrafficCheckpoint, TrafficReading, TrafficSave

### Community 43 - "Storage Provider Selection"
Cohesion: 0.11
Nodes (16): Provider, aws, .backend, cloudflare, digitalOcean, googleCloudStorage, .id, .isGeneric (+8 more)

### Community 45 - "Server Trust Challenges"
Cohesion: 0.16
Nodes (6): ServerTrustChallenge, .errorDescription, .server, ActivityFileName, .body, .body

### Community 46 - "SFTP Server Fixtures"
Cohesion: 0.22
Nodes (8): SFTPFixture, .agentSocket, .connection, .credentials, .key, .protectedKey, .served, SFTPServer

### Community 48 - "Fake Storage Server"
Cohesion: 0.20
Nodes (3): FakeStorage, .uploadCount, UploadCleanupTests

### Community 50 - "Validation Issue Collection"
Cohesion: 0.21
Nodes (6): Issue, String, .isBlank, ValidationResult, .fieldErrors, .isValid

### Community 54 - "S3 Drive Tests"
Cohesion: 0.20
Nodes (3): S3DriveTests, S3Server, withS3Drive()

### Community 55 - "AWS Encryption Settings"
Cohesion: 0.18
Nodes (7): AWSSettings, ServerSideEncryption, .id, kms, s3Managed, .title, Config

### Community 56 - "Service Account Parsing"
Cohesion: 0.18
Nodes (3): .serviceAccountEmail, ServiceAccountKey, GCSValidationTests

### Community 57 - "Application Platform Imports"
Cohesion: 0.15
Nodes (6): AppKit, Network, OSLog, ServiceManagement, UniformTypeIdentifiers, UserNotifications

### Community 58 - "S3 Storage Classes"
Cohesion: 0.15
Nodes (12): S3StorageClass, glacierInstantRetrieval, .id, intelligentTiering, oneZoneInfrequentAccess, standard, standardInfrequentAccess, .title (+4 more)

### Community 59 - "Menu Bar Status"
Cohesion: 0.21
Nodes (5): MenuBarIcon, .accessibilityValue, .animatesUploads, .body, .image

### Community 62 - "SFTP Authentication Options"
Cohesion: 0.18
Nodes (7): SFTPAuthentication, agent, .id, password, privateKey, .title, SFTPSettings

### Community 66 - "Revoked Access Recovery"
Cohesion: 0.17
Nodes (3): controlCalls(), failingStatus(), ServiceRecoveryTests

### Community 69 - "Xcode Build Settings"
Cohesion: 0.15
Nodes (13): ARCHS, ASSETCATALOG_COMPILER_APPICON_NAME, CODE_SIGN_STYLE, CURRENT_PROJECT_VERSION, ENABLE_HARDENED_RUNTIME, ENABLE_USER_SCRIPT_SANDBOXING, INFOPLIST_FILE, MARKETING_VERSION (+5 more)

### Community 70 - "Activity Status Views"
Cohesion: 0.18
Nodes (7): ActivityStatus, .body, .movingText, .progress, FailedUploadButton, .body, .details

### Community 71 - "Troubleshooting Guide"
Cohesion: 0.17
Nodes (11): A connection test fails, A drive cannot eject, A drive needs reconnecting, A Google Cloud Storage connection fails, An SFTP connection fails, Changes from another app do not appear, Files download when you did not open them, Finder adds .DS_Store files (+3 more)

### Community 72 - "Storage Backend Capabilities"
Cohesion: 0.17
Nodes (10): Backend, gcs, .locksFolderAfterSave, s3Compatible, sftp, .supportsMultiThreadUploads, .supportsServerCopy, .supportsShareLinks (+2 more)

### Community 74 - "SFTP Drive Tests"
Cohesion: 0.21
Nodes (7): SFTPDriveTests, SFTPLogin, agent, key, password, protectedKey, withSFTPDrive()

### Community 75 - "Build Documentation Guides"
Cohesion: 0.18
Nodes (7): Documentation site, Build from source, Documentation, Documentation development, Features, Install, License

### Community 76 - "Lifecycle Extension Architecture"
Cohesion: 0.20
Nodes (10): ActivityViewModel, AppViewModel, AppViewModel+Lifecycle, AppViewModel+Polling, AppViewModel+Quit, DriveCondition, QuitUseCase, SignInAgainUseCase (+2 more)

### Community 77 - "Testing Principles Fixtures"
Cohesion: 0.24
Nodes (6): Fixture notes, Tests, What to test, When a test fails, StubbedDrives, .rcloneCalls

### Community 78 - "Connection Editor Form"
Cohesion: 0.22
Nodes (3): ConnectionEditor, .advancedSection, .body

### Community 80 - "Xcode Project Structure"
Cohesion: 0.18
Nodes (10): macOS, name, options, deploymentTarget, postGenCommand, packages, UnlocalFSCore, settings (+2 more)

### Community 81 - "Drive Management Controls"
Cohesion: 0.20
Nodes (6): .header, DriveManagementItems, .body, .body, StatusIndicator, .body

### Community 82 - "Main Window Navigation"
Cohesion: 0.20
Nodes (7): ConnectionRow, .icon, MainView, .detail, .sidebar, TrafficCard, .body

### Community 83 - "SFTP Authentication Fields"
Cohesion: 0.25
Nodes (5): SFTPConnectionFields, .authenticationHelp, .authenticationSection, .body, .serverSection

### Community 84 - "Dependency Update Schedule"
Cohesion: 0.20
Nodes (9): interval, time, timezone, updates, directory, open-pull-requests-limit, package-ecosystem, schedule (+1 more)

### Community 85 - "Unfinished Upload Cleanup"
Cohesion: 0.24
Nodes (4): AppViewModel, UploadCleanup, .message, .title

### Community 86 - "App Target Configuration"
Cohesion: 0.20
Nodes (10): Debug, Release, package, product, UnlocalFS, configFiles, dependencies, platform (+2 more)

### Community 89 - "Activity Panel Views"
Cohesion: 0.25
Nodes (3): ActivityView, .activity, .idle

### Community 90 - "Concurrent Quit Tests"
Cohesion: 0.28
Nodes (3): AppQuitTests, Overlap, .peak

### Community 91 - "Application Menu Views"
Cohesion: 0.29
Nodes (4): UnlocalFSApp, .body, MenuContent, .body

### Community 92 - "Rclone Download Script"
Cohesion: 0.36
Nodes (4): CryptoKit, FetchError, run(), setting()

### Community 93 - "File Transfer States"
Cohesion: 0.25
Nodes (7): State, downloaded, downloading, failed, queued, uploaded, uploading

### Community 97 - "Application Build Schemes"
Cohesion: 0.25
Nodes (8): config, targets, config, schemes, UnlocalFS, archive, build, run

### Community 98 - "Sidebar Search Field"
Cohesion: 0.29
Nodes (3): FocusedValues, SidebarSearchField, .body

### Community 99 - "Connection Draft State"
Cohesion: 0.29
Nodes (3): ConnectionDraft, .id, .isDuplicate

### Community 100 - "Activity Panel States"
Cohesion: 0.29
Nodes (6): ActivitySnapshot, checking, .files, idle, transfers, unavailable

### Community 101 - "Unavailable Status Safety"
Cohesion: 0.43
Nodes (3): revokedDrive(), ControlFailure, statusBatch()

### Community 102 - "Swift Lint Rules"
Cohesion: 0.29
Nodes (6): disabled_rules, included, line_length, trailing_comma, mandatory_comma, type_body_length

### Community 103 - "Connection Settings Guide"
Cohesion: 0.33
Nodes (5): Credentials, Google Cloud Storage, SFTP, Storage, Test and save

### Community 104 - "Drive Settings Guide"
Cohesion: 0.33
Nodes (5): Advanced, Amazon S3, Cache, Encryption, General

### Community 107 - "App Resource Copying"
Cohesion: 0.33
Nodes (6): copyFiles, destination, subpath, buildPhase, path, sources

### Community 108 - "Encryption Recovery Guide"
Cohesion: 0.40
Nodes (4): Recover a Google Cloud Storage drive, Recover an SFTP drive, Recover files without UnlocalFS, Server-side encryption

### Community 109 - "Drive Usage Guide"
Cohesion: 0.40
Nodes (4): Clean up unfinished uploads, Finder files and dates, Menu bar and quitting, Shortcuts

### Community 110 - "Sidebar Item Identity"
Cohesion: 0.40
Nodes (3): SidebarItem, drive, traffic

### Community 111 - "Menu Activity States"
Cohesion: 0.40
Nodes (5): Activity, connected, downloading, idle, uploading

### Community 114 - "Drive Status Indicators"
Cohesion: 0.40
Nodes (5): Indicator, attention, connected, idle, working

### Community 115 - "Helper Embedding Phase"
Cohesion: 0.40
Nodes (5): basedOnDependencyAnalysis, name, script, shell, postBuildScripts

### Community 116 - "Server Trust Dialog"
Cohesion: 0.40
Nodes (3): .body, ServerTrustSheet, .body

### Community 117 - "Getting Started Guide"
Cohesion: 0.50
Nodes (3): Connect a drive, Install, Open at login

### Community 119 - "Package Test Configuration"
Cohesion: 0.50
Nodes (4): package, config, targets, test

## Knowledge Gaps
- **273 isolated node(s):** `.total`, `bytes`, `completedAt`, `dstFs`, `error` (+268 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 711 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **57 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **How does `Connection` connect lifecycle actions, polling, and quit coordination?**
  _High betweenness centrality (0.223) - this node is a cross-community bridge._
- **Are the 7 inferred relationships involving `Connection` (e.g. with `AWSSettings` and `SFTPSettings`) actually correct?**
  _`Connection` has 7 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.total`, `bytes`, `completedAt` to the rest of the system?**
  _273 weakly-connected nodes found - possible documentation gaps or missing edges._
## Graph Health
No missing or dangling endpoints. 42 self-loop edges remain. The fresh extraction combined 24 relationships sharing undirected endpoints.

`graphify-out/` is in the working tree: report and JSON are tracked; HTML and sidecars are ignored.
