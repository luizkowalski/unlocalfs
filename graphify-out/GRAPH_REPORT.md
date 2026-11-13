# Graph Report - unlocalfs  (2026-11-13)

## Corpus Check
- 173 files · ~53,604 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 14 file(s) not represented in the graph (top: (none) 5, .xcstrings 5, .resolved 1)

## Summary
- 2176 nodes · 5077 edges · 128 communities (93 shown, 35 thin omitted)
- Extraction: 83% EXTRACTED · 17% INFERRED · 0% AMBIGUOUS · INFERRED: 854 edges (avg confidence: 0.85)
- Token cost: 289,731 input · 0 output

## Graph Freshness
- Built from commit: `8a15a37e`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- .sftp
- AppError
- rclone Transfer Responses
- Control Server Test Harness
- FileActivity
- Sendable
- AppViewModel Drive Actions
- Infrastructure Module Imports
- Docs Deploy Workflow
- Connection Paths and Backends
- AWS and SFTP Settings
- TrafficStore
- CI Workflow
- SFTP Server Trust
- TrafficPreset
- Connection Status Activity
- Core Test Files
- .serve
- ConnectionStore
- AppKit App Delegate
- Desktop Services (Finder)
- Release Workflow
- Traffic Bars View Model
- App UI Frameworks
- Activity View Model
- Connection Detail View
- Direction
- Connection Editor Tests
- Docs Site Packages
- App Paths
- Connection Editor View Model
- App Polling Tests
- Control Socket Client
- .mount
- Connection Fields
- .control
- Bucket Editor Fields
- Menu Bar App Scene
- Test Fixture Resources
- .write
- ShareBar
- .validate
- Drive rc Control
- Upload Cleanup Fake Storage
- S3 Providers
- Drive Condition States
- Equatable
- Date
- ShareLinkExpiry
- Credentials Guide
- Traffic
- Main Window Sidebar
- Architecture: Presentation Layer
- S3 Drive Smoke Tests
- README Features
- Drive Settings Guide
- ConnectionDraft
- withRclone
- ControlServer
- Traffic View Model Tests
- Activity Status Row
- ConnectionEditor
- Architecture: Infrastructure Layer
- fetch-rclone.swift
- ClosedRange<Date>
- SFTP Drive Smoke Tests
- Cancel Upload Tests
- Xcode Build Settings
- Testing Guide: Fakes
- Using Drives Guide
- Duplicate and Traffic Guide
- Docs Home and Privacy
- Backend Kinds
- Upload Cleanup Flow
- XcodeGen Project Options
- Architecture: Domain Layer
- Dependabot Config
- Copy Naming
- .copyShareLinks
- Xcode Configurations
- SFTP Editor Fields
- Share Links and Troubleshooting
- ControlFailure
- App Quit Tests
- Status Indicator
- Sidebar Search Tests
- Xcode Schemes
- Architecture: Use Cases and Smoke Tests
- SFTP Connection Guide
- fetchActivity
- App Paths Tests
- SwiftLint Config
- Architecture: App Target
- Encryption Guide
- QuitUseCase
- Embed rclone Phase
- Post-Build Scripts
- App Logo and Screenshot
- Start Up and Retry Guide
- Test Scheme Targets
- Docs TypeScript Config
- Swift Package Manifest
- Toolchain Notes
- App Icon Layers
- Simple Icons Notice
- Install Notes
- Local Signing Config
- Amazon S3 Logo
- Cloudflare Logo
- DigitalOcean Logo
- GCS Logo
- MinIO Logo
- SFTP Logo
- Wasabi Logo
- ActivityView
- MemoryCredentialStorage
- Indicator
- ByteCountFormatStyle+Size.swift

## God Nodes (most connected - your core abstractions)
1. `Connection` - 210 edges
2. `UnlocalFSDomain` - 98 edges
3. `Credentials` - 92 edges
4. `MountService` - 81 edges
5. `AppViewModel` - 66 edges
6. `ViewModelFixture` - 65 edges
7. `DriveGateway` - 45 edges
8. `Traffic` - 44 edges
9. `ConnectionField` - 42 edges
10. `UnlocalFSPresentation` - 41 edges

## Surprising Connections (you probably didn't know these)
- `CI and Release Pipeline` --conceptually_related_to--> `Test Strategy`  [AMBIGUOUS]
  README.md → docs/testing.md
- `.body` --calls--> `Connection`  [INFERRED]
  UnlocalFS/Application/UnlocalFSApp.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `.body` --references--> `Provider`  [INFERRED]
  UnlocalFS/Presentation/Provider+Logo.swift → Packages/UnlocalFSCore/Sources/UnlocalFSDomain/Connection.swift
- `Encrypted Drives` --conceptually_related_to--> `ExportRcloneConfigUseCase`  [INFERRED]
  README.md → docs/architecture.md
- `Safe Disconnects` --conceptually_related_to--> `MountService`  [INFERRED]
  README.md → docs/architecture.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Encrypted drive recovery with rclone** — docs_src_content_docs_encryption_export_rclone_config, docs_src_content_docs_encryption_exported_remote_names, docs_src_content_docs_encryption_rclone_config_update_recovery, docs_src_content_docs_encryption_gcs_recovery, docs_src_content_docs_encryption_sftp_recovery, docs_src_content_docs_encryption_rclone_crypt [EXTRACTED 1.00]
- **Finder Services features with per-backend availability** — docs_src_content_docs_duplicating_files_finder_services_menu, docs_src_content_docs_duplicating_files_duplicate_on_server, docs_src_content_docs_sharing_links_presigned_share_link [EXTRACTED 1.00]
- **Domain Use Cases** — docs_architecture_saveconnectionusecase, docs_architecture_setautomaticconnectusecase, docs_architecture_deleteconnectionusecase, docs_architecture_connectdriveusecase, docs_architecture_sharefilesusecase, docs_architecture_duplicatefilesusecase, docs_architecture_exportrcloneconfigusecase, docs_architecture_quitusecase [EXTRACTED 1.00]
- **Drive Mount Pipeline (MountService, MountCommand, RcloneRemote, ControlSocket, rclone rcd)** — docs_architecture_mountservice, docs_architecture_mountcommand, docs_architecture_rcloneremote, docs_architecture_controlsocket, docs_architecture_rclone_rcd [EXTRACTED 1.00]
- **One Smoke Suite per Storage Type** — docs_testing_s3drivetests, docs_testing_sftpdrivetests, docs_testing_gcsdrivetests [EXTRACTED 1.00]
- **Safe disconnect protects pending uploads** — docs_src_content_docs_troubleshooting_safe_disconnect_block, docs_src_content_docs_using_drives_disconnect_pending_alert, docs_src_content_docs_troubleshooting_upload_retry, docs_src_content_docs_using_drives_quit_flow, docs_src_content_docs_drive_settings_turn_off_multi_connection_procedure, docs_src_content_docs_drive_settings_vfs_cache [INFERRED 0.85]
- **S3-compatible provider logos** — unlocalfs_assets_xcassets_amazon_s3_imageset_amazon_s3_amazon_s3_logo, unlocalfs_assets_xcassets_cloudflare_imageset_cloudflare_cloudflare_logo, unlocalfs_assets_xcassets_digital_ocean_imageset_digital_ocean_digitalocean_logo, unlocalfs_assets_xcassets_minio_imageset_minio_minio_logo, unlocalfs_assets_xcassets_wasabi_imageset_wasabi_wasabi_logo [INFERRED 0.85]
- **Storage type logos (S3, GCS, SFTP)** — unlocalfs_assets_xcassets_amazon_s3_imageset_amazon_s3_amazon_s3_logo, unlocalfs_assets_xcassets_gcs_imageset_gcs_gcs_logo, unlocalfs_assets_xcassets_sftp_imageset_sftp_sftp_logo [INFERRED 0.85]

## Communities (128 total, 35 thin omitted)

### Community 0 - ".sftp"
Cohesion: 0.11
Nodes (9): Credentials, .encryptionPassword, .keyPassphrase, .password, .secrets, SaveConnectionUseCase, SavedConnectionRepository, withWorkflowFixture() (+1 more)

### Community 1 - "AppError"
Cohesion: 0.05
Nodes (18): AppError, Command, Keychain, NamedRemote, Options, RcloneRemote, .cryptOptions, .environment (+10 more)

### Community 2 - "rclone Transfer Responses"
Cohesion: 0.07
Nodes (37): BatchResult, CodingKeys, bytes, completedAt, dstFs, error, initiated, key (+29 more)

### Community 3 - "Control Server Test Harness"
Cohesion: 0.12
Nodes (8): mark(), MountSafetyTests, shutdown(), withControl(), withFixture(), failingStatus(), ServiceRecoveryTests, statusBatch()

### Community 4 - "FileActivity"
Cohesion: 0.09
Nodes (15): FileActivity, .finishedAt, .id, .isUpload, Sequence<FileActivity>, ActivitySnapshot, checking, .files (+7 more)

### Community 5 - "Sendable"
Cohesion: 0.10
Nodes (13): ConnectionRepository, DeleteConnectionUseCase, SetAutomaticConnectUseCase, DriveGateway, ConnectDriveUseCase, Outcome, connected, ejected (+5 more)

### Community 6 - "AppViewModel Drive Actions"
Cohesion: 0.08
Nodes (10): AppViewModel, .busy, .isConfirmingDelete, .isShowingAlert, .isShowingDisconnectFailure, .isShowingUploadsBlockingDisconnect, .unsavedTraffic, SidebarItem (+2 more)

### Community 7 - "Infrastructure Module Imports"
Cohesion: 0.07
Nodes (13): Darwin, Foundation, GRDB, Observation, OSLog, MountService, .baseEnvironment, String (+5 more)

### Community 8 - "Docs Deploy Workflow"
Cohesion: 0.05
Nodes (42): runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, environment, if (+34 more)

### Community 9 - "Connection Paths and Backends"
Cohesion: 0.05
Nodes (14): Connection, .backend, .bucketPath, .exportsRcloneConfig, .folderPath, .usesUploadTimes, .driveStorage, .driveTarget (+6 more)

### Community 10 - "AWS and SFTP Settings"
Cohesion: 0.08
Nodes (22): AWSSettings, S3StorageClass, glacierInstantRetrieval, .id, intelligentTiering, oneZoneInfrequentAccess, standard, standardInfrequentAccess (+14 more)

### Community 11 - "TrafficStore"
Cohesion: 0.11
Nodes (7): DriveTraffic, TrafficDay, TrafficRepository, TrafficStore, .migrator, .total, TrafficStoreTests

### Community 12 - "CI Workflow"
Cohesion: 0.06
Nodes (35): env, runs-on, steps, timeout-minutes, concurrency, cancel-in-progress, group, DEVELOPER_DIR (+27 more)

### Community 13 - "SFTP Server Trust"
Cohesion: 0.12
Nodes (8): ServerTrustChallenge, .errorDescription, .server, Pending, SFTPTrustStore, ActivityFileName, .body, .body

### Community 14 - "TrafficPreset"
Cohesion: 0.09
Nodes (17): ClosedRange<Date>, DateInterval, TrafficPeriod, custom, last12Months, last30Days, last90Days, TrafficPreset (+9 more)

### Community 15 - "Connection Status Activity"
Cohesion: 0.13
Nodes (7): Activity, connected, downloading, idle, uploading, AppViewModel, .activity

### Community 16 - "Core Test Files"
Cohesion: 0.10
Nodes (5): sftpSettings(), Synchronization, Testing, UnlocalFSInfrastructure, UnlocalFSTestSupport

### Community 17 - ".serve"
Cohesion: 0.11
Nodes (4): ActivityViewModelTests, AppViewModelTests, ControlServers, TestDesktopServices

### Community 18 - "ConnectionStore"
Cohesion: 0.22
Nodes (4): CredentialStorage, MemoryCredentialStorage, RepositoryTests, UnavailableCredentialStorage

### Community 19 - "AppKit App Delegate"
Cohesion: 0.12
Nodes (4): Notification, AppDelegate, .model, .viewModels

### Community 20 - "Desktop Services (Finder)"
Cohesion: 0.12
Nodes (4): DesktopServices, RcloneConfigDestination, MacOSDesktopServices, .opensAtLogin

### Community 21 - "Release Workflow"
Cohesion: 0.07
Nodes (27): env, runs-on, steps, timeout-minutes, APPLE_ID, DEVELOPER_DIR, GH_TOKEN, PASSWORD (+19 more)

### Community 22 - "Traffic Bars View Model"
Cohesion: 0.09
Nodes (19): .unsaved, TrafficBar, .id, TrafficViewModel, .custom, .period, .recentTotal, .unit (+11 more)

### Community 23 - "App UI Frameworks"
Cohesion: 0.13
Nodes (8): AppKit, Charts, Network, ServiceManagement, SwiftUI, UniformTypeIdentifiers, UnlocalFSPresentation, UserNotifications

### Community 24 - "Activity View Model"
Cohesion: 0.11
Nodes (10): ActivityViewModel, .refreshInterval, FileActivity, .folder, .isCancellable, .name, UploadCancellation, .message (+2 more)

### Community 25 - "Connection Detail View"
Cohesion: 0.16
Nodes (13): ConnectionDetail, .actions, .awsDetails, .bucketDetail, .disconnected, .logo, .notices, .sftpDetails (+5 more)

### Community 26 - "Direction"
Cohesion: 0.13
Nodes (10): Direction, .color, download, .fill, .label, .symbol, upload, SpeedChart (+2 more)

### Community 27 - "Connection Editor Tests"
Cohesion: 0.13
Nodes (7): ConnectionEditorViewModelTests, ViewModelFixture, .paths, .rcloneCalls, .root, .service, .traffic

### Community 28 - "Docs Site Packages"
Cohesion: 0.10
Nodes (18): dependencies, astro@^7.4.7, @astrojs/starlight@^0.42.10, engines, node, name, overrides, postcss-selector-parser (+10 more)

### Community 29 - "App Paths"
Cohesion: 0.10
Nodes (10): AppPaths, .knownHosts, .sockets, .traffic, .arguments, .mountParameters, .knownHosts, .mounted (+2 more)

### Community 30 - "Connection Editor View Model"
Cohesion: 0.12
Nodes (12): ConnectionEditorViewModel, .availableProviders, .connection, .credentials, .fieldErrors, .firstInvalidField, .initialFocus, .isLocked (+4 more)

### Community 31 - "App Polling Tests"
Cohesion: 0.10
Nodes (3): AppPollingTests, FinderServicesTests, MenuBarActivityTests

### Community 32 - "Control Socket Client"
Cohesion: 0.21
Nodes (5): ControlSocket, ControlUnreachable, RcloneError, UnixConnection, .timedOut

### Community 34 - "Connection Fields"
Cohesion: 0.11
Nodes (18): ConnectionField, accessKey, bucket, confirmation, .displayName, encryptionPassword, endpoint, folder (+10 more)

### Community 35 - ".control"
Cohesion: 0.08
Nodes (4): RcloneState, running, stopped, untracked

### Community 36 - "Bucket Editor Fields"
Cohesion: 0.11
Nodes (10): ConnectionBucketFields, .body, ConnectionEditorField, .body, ConnectionIdentityFields, .body, .body, S3ConnectionFields (+2 more)

### Community 37 - "Menu Bar App Scene"
Cohesion: 0.13
Nodes (9): UnlocalFSApp, .body, MenuBarIcon, .accessibilityValue, .animatesUploads, .body, .image, MenuContent (+1 more)

### Community 38 - "Test Fixture Resources"
Cohesion: 0.11
Nodes (13): FixtureResources, Launch, requireOutput(), withFixture(), SFTPFixture, .agentSocket, .connection, .credentials (+5 more)

### Community 39 - ".write"
Cohesion: 0.21
Nodes (3): ConnectionStore, configURL(), ConnectionTests

### Community 40 - "ShareBar"
Cohesion: 0.29
Nodes (5): ShareBar, .body, .body, TrafficStats, .body

### Community 41 - ".validate"
Cohesion: 0.07
Nodes (13): .serviceAccountEmail, ServiceAccountKey, Issue, String, .isBlank, ValidationResult, .fieldErrors, .isValid (+5 more)

### Community 42 - "Drive rc Control"
Cohesion: 0.24
Nodes (7): Drive, dump(), makeDrive(), rclone(), verifyRoundTrip(), GCSDriveTests, withOfflineDrive()

### Community 43 - "Upload Cleanup Fake Storage"
Cohesion: 0.18
Nodes (3): FakeStorage, .uploadCount, UploadCleanupTests

### Community 44 - "S3 Providers"
Cohesion: 0.10
Nodes (17): Provider, aws, .backend, cloudflare, digitalOcean, googleCloudStorage, .id, .isGeneric (+9 more)

### Community 45 - "Drive Condition States"
Cohesion: 0.05
Nodes (23): DriveEjectError, .errorDescription, MountStatus, .isActive, .isServing, .needsReconnect, UploadsPendingError, .errorDescription (+15 more)

### Community 46 - "Equatable"
Cohesion: 0.15
Nodes (6): RcloneProcess, TrafficCheckpoint, TrafficReading, TrafficSave, TrafficTracker, UploadTally

### Community 47 - "Date"
Cohesion: 0.09
Nodes (19): State, downloaded, downloading, failed, queued, uploaded, uploading, UnfinishedUpload (+11 more)

### Community 48 - "ShareLinkExpiry"
Cohesion: 0.12
Nodes (6): FileActionError, ShareLinkExpiry, day, hour, .title, week

### Community 49 - "Credentials Guide"
Cohesion: 0.16
Nodes (14): Connection settings (guide page), GCS service account JSON key (Storage Object User role), Keychain credential storage, GCS/SFTP drives unreadable by older UnlocalFS versions, S3 credentials (access key, secret key, session token), Test Connection (lists folder, no write check), Export rclone Config (recovery file), Exported remotes: unlocalfs (decrypted) + unlocalfs-s3 / unlocalfs-gcs / unlocalfs-sftp (storage) (+6 more)

### Community 50 - "Traffic"
Cohesion: 0.28
Nodes (4): Traffic, .total, TrafficMeter, TrafficMeterTests

### Community 51 - "Main Window Sidebar"
Cohesion: 0.12
Nodes (11): DriveManagementItems, .body, ConnectionRow, .body, .icon, .sidebar, FocusedValues, SidebarSearchField (+3 more)

### Community 52 - "Architecture: Presentation Layer"
Cohesion: 0.23
Nodes (14): ActivitySnapshot, ActivityViewModel, AppViewModel, ConnectionEditorViewModel, DriveCondition, MainView, UnlocalFSPresentation, ServerTrustChallenge (+6 more)

### Community 53 - "S3 Drive Smoke Tests"
Cohesion: 0.13
Nodes (4): S3DriveTests, S3Server, withS3Drive(), waitUntil()

### Community 54 - "README Features"
Cohesion: 0.15
Nodes (13): SetAutomaticConnectUseCase, ShareFilesUseCase, Documentation Site (Astro + Starlight), GitHub Pages Deploy (unlocalfs.luizkowalski.net), S3DriveTests, Automatic Connections, Encrypted Drives, Finder Integration (+5 more)

### Community 55 - "Drive Settings Guide"
Cohesion: 0.16
Nodes (10): Bandwidth limit (MB/s), Drive settings (guide page), Multi-connection uploads (SFTP, files >= 256 MiB over 4 connections), Parallel transfers (default 4), Read-only drive setting, S3 storage class setting, Procedure to turn off multi-connection uploads when server rejects them, Folder-scoped drive (one bucket folder per drive) (+2 more)

### Community 56 - "ConnectionDraft"
Cohesion: 0.12
Nodes (5): ConnectionDraft, .id, .isDuplicate, MountStatus, ConnectionRulesTests

### Community 57 - "withRclone"
Cohesion: 0.25
Nodes (7): BatchReply, .current, counters(), finished(), reply(), TrafficTests, withRclone()

### Community 59 - "Traffic View Model Tests"
Cohesion: 0.14
Nodes (3): SpeedRecordingTests, TrafficViewModelTests, .yesterday

### Community 60 - "Activity Status Row"
Cohesion: 0.20
Nodes (7): ActivityStatus, .body, .movingText, .progress, FailedUploadButton, .body, .details

### Community 61 - "ConnectionEditor"
Cohesion: 0.19
Nodes (6): ConnectionEditor, .advancedSection, Pane, connection, .displayName, settings

### Community 62 - "Architecture: Infrastructure Layer"
Cohesion: 0.18
Nodes (12): UnlocalFSInfrastructure, Keychain, MountCommand, rclone rcd with named remotes, RcloneRemote, SavedConnectionRepository, ServiceAccountKey, TrafficRepository (+4 more)

### Community 63 - "fetch-rclone.swift"
Cohesion: 0.36
Nodes (4): CryptoKit, FetchError, run(), setting()

### Community 64 - "ClosedRange<Date>"
Cohesion: 0.40
Nodes (4): ClosedRange<Date>, .formattedDays, DateInterval, .formattedDays

### Community 65 - "SFTP Drive Smoke Tests"
Cohesion: 0.21
Nodes (7): SFTPDriveTests, SFTPLogin, agent, key, password, protectedKey, withSFTPDrive()

### Community 67 - "Xcode Build Settings"
Cohesion: 0.15
Nodes (13): ARCHS, ASSETCATALOG_COMPILER_APPICON_NAME, CODE_SIGN_STYLE, CURRENT_PROJECT_VERSION, ENABLE_HARDENED_RUNTIME, ENABLE_USER_SCRIPT_SANDBOXING, INFOPLIST_FILE, MARKETING_VERSION (+5 more)

### Community 68 - "Testing Guide: Fakes"
Cohesion: 0.20
Nodes (10): ControlSocket, MountService, TrafficMeter, Connection.s3/.sftp/.gcs fixtures, ControlServer, rclone serve Fixture Notes, StubbedDrives, Test Strategy (+2 more)

### Community 69 - "Using Drives Guide"
Cohesion: 0.20
Nodes (11): Cloudflare R2 endpoint (ACCOUNT_ID.r2.cloudflarestorage.com, region auto), S3 storage fields (Name, Provider, Endpoint, Region, Bucket, Folder), Folder drives (guide page), Drives mount in ~/UnlocalFS, Refresh / Refresh Files (remote changes within 5 minutes), Disconnect All (stops at first failing drive), Keyboard shortcuts and sidebar search, Menu bar mode (provider icons, lock for encrypted, upload/download arrows) (+3 more)

### Community 70 - "Duplicate and Traffic Guide"
Cohesion: 0.18
Nodes (10): Cache limit (default 1 GB, LRU eviction), Duplicate on Server (Finder Service, server-side copy), Duplicating files (guide page), Finder copy naming (report copy.pdf, report copy 2.pdf), Finder Services menu entries, traffic.sqlite (per-drive daily byte counts, no file names), Traffic (guide page), Traffic card and page (30 Days, 90 Days, 12 Months, Custom; upload/download split) (+2 more)

### Community 71 - "Docs Home and Privacy"
Cohesion: 0.20
Nodes (9): Keep free on disk, Local file cache (~/Library/Application Support/UnlocalFS/cache), Supported S3 providers (Amazon S3, Cloudflare R2, MinIO, Wasabi, DigitalOcean Spaces), UnlocalFS: Your S3 bucket in Finder (home page), UnlocalFS window screenshot (R2 drive uploading), Changes upload after file close (write-back cache), Drive logs (~/Library/Logs/UnlocalFS), Privacy (guide page) (+1 more)

### Community 72 - "Backend Kinds"
Cohesion: 0.17
Nodes (10): Backend, gcs, .locksFolderAfterSave, s3Compatible, sftp, .supportsMultiThreadUploads, .supportsServerCopy, .supportsShareLinks (+2 more)

### Community 73 - "Upload Cleanup Flow"
Cohesion: 0.24
Nodes (4): AppViewModel, UploadCleanup, .message, .title

### Community 74 - "XcodeGen Project Options"
Cohesion: 0.18
Nodes (10): macOS, name, options, deploymentTarget, postGenCommand, packages, UnlocalFSCore, settings (+2 more)

### Community 75 - "Architecture: Domain Layer"
Cohesion: 0.27
Nodes (10): ConnectDriveUseCase, ConnectionField, ConnectionRepository, UnlocalFSDomain, DriveGateway, DuplicateFilesUseCase, QuitUseCase, SaveConnectionUseCase (+2 more)

### Community 76 - "Dependabot Config"
Cohesion: 0.20
Nodes (9): interval, time, timezone, updates, directory, open-pull-requests-limit, package-ecosystem, schedule (+1 more)

### Community 79 - "Xcode Configurations"
Cohesion: 0.20
Nodes (10): Debug, Release, package, product, UnlocalFS, configFiles, dependencies, platform (+2 more)

### Community 80 - "SFTP Editor Fields"
Cohesion: 0.29
Nodes (4): SFTPConnectionFields, .authenticationHelp, .authenticationSection, .body

### Community 81 - "Share Links and Troubleshooting"
Cohesion: 0.25
Nodes (8): Requests signed locally; secret key never sent, Copy Share Link (presigned URL, 1 hour / 1 day / 7 days), Sharing links (guide page), Suppress .DS_Store on network drives (DSDontWriteNetworkStores), Eject retry for 10 seconds (open files, Quick Look), Troubleshooting (guide page), Eject failure alert (Keep Connected / Try Disconnect Again), Needs reconnect state

### Community 83 - "App Quit Tests"
Cohesion: 0.24
Nodes (3): AppQuitTests, Overlap, .peak

### Community 84 - "Status Indicator"
Cohesion: 0.40
Nodes (3): .header, StatusIndicator, .body

### Community 89 - "Xcode Schemes"
Cohesion: 0.25
Nodes (8): config, targets, config, schemes, UnlocalFS, archive, build, run

### Community 91 - "Architecture: Use Cases and Smoke Tests"
Cohesion: 0.29
Nodes (7): DeleteConnectionUseCase, ExportRcloneConfigUseCase, SFTPTrustStore, GCSDriveTests, SFTPDriveTests, Storage Smoke Tests, SFTP Server Key Fingerprint Check

### Community 92 - "SFTP Connection Guide"
Cohesion: 0.33
Nodes (5): Duplicate connection, SFTP connection fields (host, port, username, remote folder, sign-in method), SFTP sign-in: Password, Private key, SSH agent, Recover an SFTP drive (known_hosts_file, key_file, host verification kept on), SFTP connection failures (unknown/changed key, key file, ssh-agent, sign-in, folder)

### Community 96 - "SwiftLint Config"
Cohesion: 0.29
Nodes (6): disabled_rules, included, line_length, trailing_comma, mandatory_comma, type_body_length

### Community 97 - "Architecture: App Target"
Cohesion: 0.33
Nodes (4): AppDelegate, UnlocalFS Application Target, MacOSDesktopServices, Drive Health Checks

### Community 98 - "Encryption Guide"
Cohesion: 0.40
Nodes (4): Encrypt files setting (fixed after save), S3 server-side encryption (Bucket default, SSE-S3, SSE-KMS), Encryption (guide page), rclone crypt (client-side content and name encryption)

### Community 101 - "QuitUseCase"
Cohesion: 0.16
Nodes (5): Decision, disconnect, quit, wait, QuitUseCase

### Community 102 - "Embed rclone Phase"
Cohesion: 0.33
Nodes (6): copyFiles, destination, subpath, buildPhase, path, sources

### Community 104 - "Post-Build Scripts"
Cohesion: 0.40
Nodes (5): basedOnDependencyAnalysis, name, script, shell, postBuildScripts

### Community 105 - "App Logo and Screenshot"
Cohesion: 0.50
Nodes (4): UnlocalFS App Logo (blue cloud over bar, macOS squircle icon), UnlocalFS Main Window Screenshot (drive sidebar, Activity upload table, Speed chart), Docs Site Favicon (copy of app logo), Docs Site App Screenshot (copy of main window screenshot)

### Community 106 - "Start Up and Retry Guide"
Cohesion: 0.50
Nodes (4): Connect on start up, Open at Login (separate from Connect on start up), Failed upload retry (up to every 5 minutes, notification with error), Activity table (failed first, then active, waiting, finished; sorted by name)

### Community 107 - "Test Scheme Targets"
Cohesion: 0.50
Nodes (4): package, config, targets, test

### Community 124 - "ActivityView"
Cohesion: 0.20
Nodes (7): ActivityTable, ActivityView, .activity, .idle, .body, ServerTrustSheet, .body

### Community 134 - "Indicator"
Cohesion: 0.40
Nodes (5): Indicator, attention, connected, idle, working

## Ambiguous Edges - Review These
- `CI and Release Pipeline` → `Test Strategy`  [AMBIGUOUS]
  README.md · relation: conceptually_related_to

## Knowledge Gaps
- **299 isolated node(s):** `.backend`, `.usesUploadTimes`, `.exportsRcloneConfig`, `.bucketPath`, `.folderPath` (+294 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 671 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **35 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Connection` connect `Connection Paths and Backends` to `.sftp`, `AppError`, `rclone Transfer Responses`, `Control Server Test Harness`, `Sendable`, `AppViewModel Drive Actions`, `Infrastructure Module Imports`, `AWS and SFTP Settings`, `TrafficStore`, `Connection Status Activity`, `.serve`, `Desktop Services (Finder)`, `Traffic Bars View Model`, `Activity View Model`, `Connection Detail View`, `Connection Editor Tests`, `App Paths`, `Connection Editor View Model`, `.mount`, `.control`, `Menu Bar App Scene`, `Test Fixture Resources`, `.write`, `.validate`, `Drive rc Control`, `Upload Cleanup Fake Storage`, `S3 Providers`, `Equatable`, `ShareLinkExpiry`, `Main Window Sidebar`, `ConnectionDraft`, `withRclone`, `Traffic View Model Tests`, `Backend Kinds`, `Upload Cleanup Flow`, `QuitUseCase`, `ActivityView`?**
  _High betweenness centrality (0.217) - this node is a cross-community bridge._
- **Are the 9 inferred relationships involving `Connection` (e.g. with `AWSSettings` and `SFTPSettings`) actually correct?**
  _`Connection` has 9 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.backend`, `.usesUploadTimes`, `.exportsRcloneConfig` to the rest of the system?**
  _299 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `.sftp` be split into smaller, more focused modules?**
  _Cohesion score 0.11085972850678733 - nodes in this community are weakly interconnected._
- **Why does `UnlocalFSDomain` connect `Infrastructure Module Imports` to `rclone Transfer Responses`, `FileActivity`, `Connection Paths and Backends`, `Drive rc Control`, `Core Test Files`, `App UI Frameworks`, `withRclone`, `App Paths Tests`?**
  _High betweenness centrality (0.056) - this node is a cross-community bridge._
- **Are the 41 inferred relationships involving `Credentials` (e.g. with `ConnectionEditorViewModel` and `.credentialsSavedBeforeEncryptionHaveNoPassword()`) actually correct?**
  _`Credentials` has 41 INFERRED edges - model-reasoned connections that need verification._

### Low-confidence Hints
_AMBIGUOUS edges — the extractor was unsure. Verify before acting on these._

- **What is the exact relationship between `CI and Release Pipeline` and `Test Strategy`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._