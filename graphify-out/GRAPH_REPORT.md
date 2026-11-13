# Graph Report - unlocalfs  (2026-11-13)

## Corpus Check
- 183 files · ~59,146 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 14 file(s) not represented in the graph (top: (none) 5, .xcstrings 5, .resolved 1)

## Summary
- 2105 nodes · 5051 edges · 146 communities (94 shown, 52 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 889 edges (avg confidence: 0.86)
- Token cost: 289,731 input · 0 output

## Graph Freshness
- Built from commit: `17a25222`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Traffic
- Decodable
- Foundation
- ViewModelFixture
- Testing
- deploy
- .post
- .s3
- AppViewModel
- .app
- ConnectionRepository
- Credentials
- Sendable
- Connection
- withControl
- steps
- MacOSDesktopServices
- MountService
- .mount
- ConnectionStore
- MountService
- ControlServer
- UnlocalFSPresentation
- AppDelegate
- MountStatus
- .serve
- DriveCondition
- AppPaths
- Direction
- RcloneRemote
- TrafficView.swift
- Provider
- AppViewModel
- ConnectionEditorViewModel
- package.json
- Drive
- MountStatus
- ConnectionField
- FixtureResources
- ViewModelFixture
- .remove
- .validate
- TrafficStore
- .control
- SFTPFixture
- ServiceAccountKey
- Infrastructure
- ActivityViewModel
- ShareLinkExpiry
- .sftp
- TrafficRangePicker
- AppError
- .status
- ActivityView
- Credentials
- ActivityStatus
- TrafficPreset
- withS3Drive
- Identifiable
- MenuBarIcon
- Keychain
- withRclone
- GoogleSignInRun
- withSFTPDrive
- .serve
- Equatable
- GCSAuthentication
- Presentation and Application
- Backend
- UploadCleanup
- GCSConnectionFields
- ConnectionEditor
- TrafficView
- .quitDisconnectsEveryDriveAtTheSameTime
- FakeStorage
- StubbedDrives
- StatusIndicator
- updates
- ServiceAccountKey
- CopyName
- Sendable
- SFTPConnectionFields
- README.md
- ValidationResult
- .run
- .recordTraffic
- TrafficPreset
- ServiceRecoveryTests
- .serve
- connection-settings.md
- S3StorageClass
- S3StorageClass
- .update
- SpeedSample
- UnlocalFS
- SidebarSearchField
- ConnectionDraft
- GoogleClient
- SFTPAuthentication
- ActivitySnapshot
- GCSConnectionFields
- .write
- date
- .swiftlint.yml
- .post
- drive-settings.md
- .serve
- TrafficPeriod
- UploadTally
- .body
- ConnectionDraft
- What to test
- CaseIterable
- encryption.md
- AppViewModel
- Activity
- Indicator
- waitUntil
- Activity
- .copyShareLinks
- index.md
- Indicator
- ClosedRange<Date>
- ConnectionValidationTests.swift

## God Nodes (most connected - your core abstractions)
1. `Connection` - 217 edges
2. `Credentials` - 105 edges
3. `UnlocalFSDomain` - 98 edges
4. `MountService` - 93 edges
5. `ViewModelFixture` - 72 edges
6. `AppViewModel` - 70 edges
7. `DriveGateway` - 48 edges
8. `ConnectionField` - 44 edges
9. `Traffic` - 44 edges
10. `AppError` - 42 edges

## Surprising Connections (you probably didn't know these)
- `Build from source` --references--> `ViewModelFactory`  [INFERRED]
  README.md → Packages/UnlocalFSCore/Sources/UnlocalFSPresentation/ViewModelFactory.swift
- `Domain` --references--> `ConnectionField`  [INFERRED]
  docs/architecture.md → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `Infrastructure` --references--> `Credentials`  [INFERRED]
  docs/architecture.md → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `Infrastructure` --references--> `MountCommand`  [INFERRED]
  docs/architecture.md → Packages/UnlocalFSCore/Sources/UnlocalFSInfrastructure/MountCommand.swift
- `Infrastructure` --references--> `GoogleClient`  [INFERRED]
  docs/architecture.md → Packages/UnlocalFSCore/Sources/UnlocalFSInfrastructure/MountService+GoogleSignIn.swift

## Import Cycles
- None detected.

## Communities (146 total, 52 thin omitted)

### Community 0 - "Traffic"
Cohesion: 0.28
Nodes (4): Traffic, .total, TrafficMeter, TrafficMeterTests

### Community 1 - "Decodable"
Cohesion: 0.07
Nodes (38): BatchResult, CodingKeys, bytes, completedAt, dstFs, error, initiated, key (+30 more)

### Community 2 - "Foundation"
Cohesion: 0.07
Nodes (10): Darwin, Foundation, GRDB, Observation, String, .expandingTilde, Security, FormatStyle (+2 more)

### Community 4 - "Testing"
Cohesion: 0.05
Nodes (42): runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, environment, if (+34 more)

### Community 5 - "deploy"
Cohesion: 0.07
Nodes (8): AppViewModel, .busy, .isConfirmingDelete, .isShowingAlert, .isShowingDisconnectFailure, .isShowingUploadsBlockingDisconnect, .selected, .unsavedTraffic

### Community 6 - ".post"
Cohesion: 0.11
Nodes (4): Synchronization, Testing, UnlocalFSInfrastructure, UnlocalFSTestSupport

### Community 8 - "AppViewModel"
Cohesion: 0.38
Nodes (3): ControlUnreachable, UnixConnection, .timedOut

### Community 9 - ".app"
Cohesion: 0.06
Nodes (35): env, runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, DEVELOPER_DIR (+27 more)

### Community 10 - "ConnectionRepository"
Cohesion: 0.15
Nodes (7): ConnectionRepository, DeleteConnectionUseCase, SetAutomaticConnectUseCase, DuplicateFilesUseCase, ExportRcloneConfigUseCase, ShareFilesUseCase, AppDependencies

### Community 11 - "Credentials"
Cohesion: 0.19
Nodes (3): SaveConnectionUseCase, withWorkflowFixture(), WorkflowTests

### Community 12 - "Sendable"
Cohesion: 0.13
Nodes (3): AppDelegate, .model, .viewModels

### Community 13 - "Connection"
Cohesion: 0.12
Nodes (8): Infrastructure, ConnectionStore, CredentialStorage, SavedConnectionRepository, MemoryCredentialStorage, RepositoryTests, UnavailableCredentialStorage, MemoryCredentialStorage

### Community 14 - "withControl"
Cohesion: 0.07
Nodes (12): Connection, .backend, .bucketPath, .exportsRcloneConfig, .folderPath, .usesGoogleSignIn, .usesUploadTimes, .driveStorage (+4 more)

### Community 15 - "steps"
Cohesion: 0.10
Nodes (4): DesktopServices, RcloneConfigDestination, MacOSDesktopServices, .opensAtLogin

### Community 16 - "MacOSDesktopServices"
Cohesion: 0.07
Nodes (27): env, runs-on, steps, timeout-minutes, APPLE_ID, DEVELOPER_DIR, GH_TOKEN, PASSWORD (+19 more)

### Community 17 - "MountService"
Cohesion: 0.13
Nodes (8): AppKit, Charts, Network, ServiceManagement, SwiftUI, UniformTypeIdentifiers, UnlocalFSPresentation, UserNotifications

### Community 18 - ".mount"
Cohesion: 0.12
Nodes (13): DriveCondition, checking, connected, disconnected, ejected, .indicator, needsAttention, needsReconnect (+5 more)

### Community 19 - "ConnectionStore"
Cohesion: 0.17
Nodes (12): ConnectionDetail, .awsDetails, .bucketDetail, .disconnected, .logo, .notices, .sftpDetails, .storageName (+4 more)

### Community 21 - "ControlServer"
Cohesion: 0.07
Nodes (15): CryptoKit, mark(), MountSafetyTests, shutdown(), withControl(), withFixture(), failingStatus(), revokedDrive() (+7 more)

### Community 23 - "AppDelegate"
Cohesion: 0.20
Nodes (8): Storage smoke tests, Drive, dump(), makeDrive(), rclone(), verifyRoundTrip(), GCSDriveTests, withOfflineDrive()

### Community 24 - "MountStatus"
Cohesion: 0.14
Nodes (8): DriveEjectError, .errorDescription, MountStatus, .isActive, .isServing, .needsReconnect, UploadsPendingError, .errorDescription

### Community 25 - ".serve"
Cohesion: 0.17
Nodes (7): ConnectionBucketFields, .body, ConnectionEditorField, .body, .body, S3ConnectionFields, .body

### Community 26 - "DriveCondition"
Cohesion: 0.10
Nodes (18): dependencies, astro@^7.4.8, @astrojs/starlight@^0.42.10, engines, node, name, overrides, postcss-selector-parser (+10 more)

### Community 28 - "Direction"
Cohesion: 0.11
Nodes (19): ConnectionField, accessKey, bucket, confirmation, .displayName, encryptionPassword, endpoint, folder (+11 more)

### Community 29 - "RcloneRemote"
Cohesion: 0.11
Nodes (10): AppPaths, .knownHosts, .sockets, .traffic, MountCommand, .arguments, .environment, .mountParameters (+2 more)

### Community 30 - "TrafficView.swift"
Cohesion: 0.16
Nodes (9): ConnectionEditorViewModel, .connection, .credentials, .fieldErrors, .firstInvalidField, .initialFocus, .isLocked, .locksRemoteFolder (+1 more)

### Community 31 - "Provider"
Cohesion: 0.09
Nodes (4): FinderServicesTests, MenuBarActivityTests, SpeedRecordingTests, ControlServers

### Community 32 - "AppViewModel"
Cohesion: 0.21
Nodes (5): MenuBarIcon, .accessibilityValue, .animatesUploads, .body, .image

### Community 33 - "ConnectionEditorViewModel"
Cohesion: 0.18
Nodes (5): FixtureResources, Launch, requireOutput(), withFixture(), startAgent()

### Community 34 - "package.json"
Cohesion: 0.10
Nodes (17): Provider, aws, .backend, cloudflare, digitalOcean, googleCloudStorage, .id, .isGeneric (+9 more)

### Community 35 - "Drive"
Cohesion: 0.20
Nodes (3): ServerTrustChallenge, .errorDescription, .server

### Community 37 - "ConnectionField"
Cohesion: 0.18
Nodes (7): FileActivity, .finishedAt, .id, .isUpload, Sequence<FileActivity>, .hasFailed, .rank

### Community 38 - "FixtureResources"
Cohesion: 0.14
Nodes (8): TrafficBar, .id, TrafficViewModel, .custom, .period, .recentTotal, .unit, .body

### Community 39 - "ViewModelFixture"
Cohesion: 0.12
Nodes (8): AppSearchTests, ViewModelFixture, .paths, .rcloneCalls, .root, .service, .signInEnvironment, .traffic

### Community 41 - ".validate"
Cohesion: 0.17
Nodes (14): NamedRemote, Options, RcloneRemote, .cryptOptions, .environment, .gcsOptions, .namedRemotes, .options (+6 more)

### Community 42 - "TrafficStore"
Cohesion: 0.12
Nodes (6): DriveTraffic, TrafficDay, TrafficStore, .migrator, .total, TrafficStoreTests

### Community 43 - ".control"
Cohesion: 0.18
Nodes (3): FakeStorage, .uploadCount, UploadCleanupTests

### Community 44 - "SFTPFixture"
Cohesion: 0.14
Nodes (7): ActivityViewModel, .refreshInterval, FileActivity, .folder, .isCancellable, .name, ActivityViewModelTests

### Community 46 - "ServiceAccountKey"
Cohesion: 0.18
Nodes (5): .serviceAccountEmail, ServiceAccountKey, awsFixture(), AWSValidationTests, GCSValidationTests

### Community 47 - "Infrastructure"
Cohesion: 0.22
Nodes (8): SFTPFixture, .agentSocket, .connection, .credentials, .key, .protectedKey, .served, SFTPServer

### Community 48 - "ActivityViewModel"
Cohesion: 0.17
Nodes (11): SpeedSample, .axisLimit, .fastestDownload, .fastestUpload, Date, DayCell, .body, MonthGrid (+3 more)

### Community 49 - "ShareLinkExpiry"
Cohesion: 0.18
Nodes (7): AWSSettings, ServerSideEncryption, .id, kms, s3Managed, .title, Config

### Community 53 - "AppError"
Cohesion: 0.20
Nodes (3): S3DriveTests, S3Server, withS3Drive()

### Community 54 - ".status"
Cohesion: 0.16
Nodes (4): RcloneState, running, stopped, untracked

### Community 55 - "ActivityView"
Cohesion: 0.20
Nodes (7): ActivityStatus, .body, .movingText, .progress, FailedUploadButton, .body, .details

### Community 56 - "Credentials"
Cohesion: 0.14
Nodes (7): Credentials, .encryptionPassword, .isSignedInToGoogle, .keyPassphrase, .password, .secrets, ConnectionRulesTests

### Community 58 - "TrafficPreset"
Cohesion: 0.12
Nodes (12): ClosedRange<Date>, DateInterval, TrafficPreset, last7Days, lastMonth, thisMonth, thisYear, today (+4 more)

### Community 59 - "withS3Drive"
Cohesion: 0.12
Nodes (9): ConnectionRow, MainView, .detail, .sidebar, FocusedValues, SidebarSearchField, .body, TrafficCard (+1 more)

### Community 60 - "Identifiable"
Cohesion: 0.21
Nodes (7): SFTPDriveTests, SFTPLogin, agent, key, password, protectedKey, withSFTPDrive()

### Community 62 - "Keychain"
Cohesion: 0.15
Nodes (13): ARCHS, ASSETCATALOG_COMPILER_APPICON_NAME, CODE_SIGN_STYLE, CURRENT_PROJECT_VERSION, ENABLE_HARDENED_RUNTIME, ENABLE_USER_SCRIPT_SANDBOXING, INFOPLIST_FILE, MARKETING_VERSION (+5 more)

### Community 63 - "withRclone"
Cohesion: 0.25
Nodes (7): BatchReply, .current, counters(), finished(), reply(), TrafficTests, withRclone()

### Community 64 - "GoogleSignInRun"
Cohesion: 0.17
Nodes (11): A connection test fails, A drive cannot eject, A drive needs reconnecting, A Google Cloud Storage connection fails, An SFTP connection fails, Changes from another app do not appear, Files download when you did not open them, Finder adds .DS_Store files (+3 more)

### Community 65 - "withSFTPDrive"
Cohesion: 0.17
Nodes (10): Backend, gcs, .locksFolderAfterSave, s3Compatible, sftp, .supportsMultiThreadUploads, .supportsServerCopy, .supportsShareLinks (+2 more)

### Community 67 - "Equatable"
Cohesion: 0.20
Nodes (5): RcloneProcess, TrafficCheckpoint, .unsaved, TrafficReading, TrafficSave

### Community 68 - "GCSAuthentication"
Cohesion: 0.14
Nodes (10): ActivityFileName, .body, ActivityTable, .body, ActivityView, .activity, .idle, .body (+2 more)

### Community 69 - "Presentation and Application"
Cohesion: 0.14
Nodes (11): Clean Architecture with MVVM, Domain, Presentation and Application, Verification, TrafficRepository, UploadCancellation, .message, .title (+3 more)

### Community 70 - "Backend"
Cohesion: 0.22
Nodes (7): Documentation site, Build from source, Documentation, Documentation development, Features, Install, License

### Community 71 - "UploadCleanup"
Cohesion: 0.13
Nodes (10): Direction, .color, download, .fill, .label, .symbol, upload, SpeedChart (+2 more)

### Community 73 - "ConnectionEditor"
Cohesion: 0.24
Nodes (4): AppViewModel, UploadCleanup, .message, .title

### Community 74 - "TrafficView"
Cohesion: 0.12
Nodes (15): .icon, ProviderIcon, .body, ShareBar, .body, TrafficChart, TrafficList, .body (+7 more)

### Community 76 - "FakeStorage"
Cohesion: 0.18
Nodes (10): macOS, name, options, deploymentTarget, postGenCommand, packages, UnlocalFSCore, settings (+2 more)

### Community 77 - "StubbedDrives"
Cohesion: 0.12
Nodes (6): controlCalls(), LockableCredentialStorage, ServiceRecoveryTests, withRevokedDrive(), StubbedDrives, .rcloneCalls

### Community 78 - "StatusIndicator"
Cohesion: 0.20
Nodes (9): interval, time, timezone, updates, directory, open-pull-requests-limit, package-ecosystem, schedule (+1 more)

### Community 80 - "ServiceAccountKey"
Cohesion: 0.22
Nodes (6): ShareLinkExpiry, day, hour, .title, week, AppViewModel

### Community 81 - "CopyName"
Cohesion: 0.17
Nodes (3): AppError, Command, CommandTests

### Community 82 - "Sendable"
Cohesion: 0.15
Nodes (9): ConnectDriveUseCase, Decision, disconnect, quit, wait, Outcome, connected, ejected (+1 more)

### Community 83 - "SFTPConnectionFields"
Cohesion: 0.20
Nodes (10): Debug, Release, package, product, UnlocalFS, configFiles, dependencies, platform (+2 more)

### Community 84 - "README.md"
Cohesion: 0.25
Nodes (5): SFTPConnectionFields, .authenticationHelp, .authenticationSection, .body, .serverSection

### Community 85 - "ValidationResult"
Cohesion: 0.23
Nodes (6): Issue, String, .isBlank, ValidationResult, .fieldErrors, .isValid

### Community 86 - ".run"
Cohesion: 0.22
Nodes (3): AppQuitTests, Overlap, .peak

### Community 87 - ".recordTraffic"
Cohesion: 0.22
Nodes (7): .actions, .header, DriveManagementItems, .body, .body, StatusIndicator, .body

### Community 89 - "ServiceRecoveryTests"
Cohesion: 0.29
Nodes (7): State, downloaded, downloading, failed, queued, uploaded, uploading

### Community 91 - "connection-settings.md"
Cohesion: 0.25
Nodes (8): config, targets, config, schemes, UnlocalFS, archive, build, run

### Community 92 - "S3StorageClass"
Cohesion: 0.24
Nodes (3): ConnectionEditor, .advancedSection, .body

### Community 93 - "S3StorageClass"
Cohesion: 0.15
Nodes (12): S3StorageClass, glacierInstantRetrieval, .id, intelligentTiering, oneZoneInfrequentAccess, standard, standardInfrequentAccess, .title (+4 more)

### Community 94 - ".update"
Cohesion: 0.18
Nodes (7): SFTPAuthentication, agent, .id, password, privateKey, .title, SFTPSettings

### Community 95 - "SpeedSample"
Cohesion: 0.29
Nodes (6): ActivitySnapshot, checking, .files, idle, transfers, unavailable

### Community 98 - "ConnectionDraft"
Cohesion: 0.29
Nodes (6): disabled_rules, included, line_length, trailing_comma, mandatory_comma, type_body_length

### Community 100 - "SFTPAuthentication"
Cohesion: 0.33
Nodes (5): Credentials, Google Cloud Storage, SFTP, Storage, Test and save

### Community 101 - "ActivitySnapshot"
Cohesion: 0.33
Nodes (5): Advanced, Amazon S3, Cache, Encryption, General

### Community 105 - ".swiftlint.yml"
Cohesion: 0.33
Nodes (6): copyFiles, destination, subpath, buildPhase, path, sources

### Community 107 - "drive-settings.md"
Cohesion: 0.40
Nodes (4): Recover a Google Cloud Storage drive, Recover an SFTP drive, Recover files without UnlocalFS, Server-side encryption

### Community 108 - ".serve"
Cohesion: 0.40
Nodes (4): Clean up unfinished uploads, Finder files and dates, Menu bar and quitting, Shortcuts

### Community 109 - "TrafficPeriod"
Cohesion: 0.22
Nodes (8): SidebarItem, drive, traffic, TrafficPeriod, custom, last12Months, last30Days, last90Days

### Community 110 - "UploadTally"
Cohesion: 0.32
Nodes (3): OSLog, TrafficTracker, UploadTally

### Community 111 - ".body"
Cohesion: 0.33
Nodes (4): UnlocalFSApp, .body, MenuContent, .body

### Community 112 - "ConnectionDraft"
Cohesion: 0.29
Nodes (3): ConnectionDraft, .id, .isDuplicate

### Community 113 - "What to test"
Cohesion: 0.33
Nodes (4): Fixture notes, Tests, What to test, When a test fails

### Community 114 - "CaseIterable"
Cohesion: 0.40
Nodes (5): basedOnDependencyAnalysis, name, script, shell, postBuildScripts

### Community 115 - "encryption.md"
Cohesion: 0.50
Nodes (3): Connect a drive, Install, Open at login

### Community 117 - "Activity"
Cohesion: 0.50
Nodes (4): package, config, targets, test

### Community 122 - "Activity"
Cohesion: 0.40
Nodes (5): Activity, connected, downloading, idle, uploading

### Community 130 - "Indicator"
Cohesion: 0.40
Nodes (5): Indicator, attention, connected, idle, working

### Community 131 - "ClosedRange<Date>"
Cohesion: 0.40
Nodes (4): ClosedRange<Date>, .formattedDays, DateInterval, .formattedDays

## Knowledge Gaps
- **261 isolated node(s):** `.backend`, `.usesUploadTimes`, `.usesGoogleSignIn`, `.exportsRcloneConfig`, `.bucketPath` (+256 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 676 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **52 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Connection` connect `withControl` to `Foundation`, `.prepareCancellation`, `deploy`, `.mountLocation`, `.s3`, `ConnectionRepository`, `Credentials`, `steps`, `ConnectionStore`, `MountService`, `ControlServer`, `UnlocalFSPresentation`, `AppDelegate`, `AppPaths`, `RcloneRemote`, `TrafficView.swift`, `package.json`, `Drive`, `MountStatus`, `FixtureResources`, `.remove`, `.validate`, `TrafficStore`, `.control`, `SFTPFixture`, `.control`, `ServiceAccountKey`, `Infrastructure`, `ShareLinkExpiry`, `.sftp`, `.status`, `Credentials`, `withS3Drive`, `withRclone`, `withSFTPDrive`, `.serve`, `Equatable`, `GCSAuthentication`, `Presentation and Application`, `ConnectionEditor`, `StubbedDrives`, `CopyName`, `Sendable`, `ValidationResult`, `.recordTraffic`, `.serve`, `GoogleClient`, `.write`, `.body`, `ConnectionDraft`, `AppViewModel`, `String`, `.activity`?**
  _High betweenness centrality (0.212) - this node is a cross-community bridge._
- **Are the 9 inferred relationships involving `Connection` (e.g. with `AWSSettings` and `SFTPSettings`) actually correct?**
  _`Connection` has 9 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.backend`, `.usesUploadTimes`, `.usesGoogleSignIn` to the rest of the system?**
  _261 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Decodable` be split into smaller, more focused modules?**
  _Cohesion score 0.07407407407407407 - nodes in this community are weakly interconnected._
- **Why does `Foundation` connect `Foundation` to `Decodable`, `ConnectionValidationTests.swift`, `.post`, `ConnectionRepository`, `ControlServer`, `AppDelegate`, `MountStatus`, `RcloneRemote`, `package.json`, `Drive`, `MountStatus`, `ConnectionField`, `TrafficStore`, `ServiceAccountKey`, `ShareLinkExpiry`, `.serve`, `Equatable`, `updates`, `Sendable`, `ValidationResult`, `TrafficPreset`, `.update`, `UnlocalFS`, `SidebarSearchField`, `UploadTally`, `ConnectionDraft`?**
  _High betweenness centrality (0.104) - this node is a cross-community bridge._
- **Are the 42 inferred relationships involving `Credentials` (e.g. with `Infrastructure` and `ConnectionEditorViewModel`) actually correct?**
  _`Credentials` has 42 INFERRED edges - model-reasoned connections that need verification._
- **Should `Foundation` be split into smaller, more focused modules?**
  _Cohesion score 0.07184325108853411 - nodes in this community are weakly interconnected._