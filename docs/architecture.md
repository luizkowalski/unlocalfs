# Clean Architecture with MVVM

The domain defines what the app does. Infrastructure implements storage and drive operations. Presentation owns observable state and user interaction. Application constructs the objects and connects them to macOS.

```mermaid
flowchart LR
    Application --> Presentation
    Application --> Infrastructure
    Presentation --> Domain
    Infrastructure --> Domain
```

## Domain

`Packages/UnlocalFSCore/Sources/UnlocalFSDomain` contains connection and credential validation, duplication, automatic-connect eligibility, upload safety rules, and workflows:

| Use case | Behavior |
| --- | --- |
| SaveConnectionUseCase | Validates current saved names and credentials, prepares credentials, then saves |
| DeleteConnectionUseCase | Refuses active drives, removes the saved connection and cache |
| ToggleDriveUseCase | Uses current drive status to connect, disconnect, or reconnect |
| ShareFilesUseCase | Resolves selected files to drives and creates links; identifies the failed file |
| ExportRcloneConfigUseCase | Refuses unencrypted drives, reads credentials only when the export includes them, then writes the rclone config |
| QuitUseCase | Refuses quit during an operation or while a drive remains active |

`ValidationResult<Field>` collects ordered, typed issues for any domain model. Connection and credential validation own their rules; the editor owns focus order. `ConnectionField` names each reported field, so the editor maps errors to inputs without string matching. `ConnectionRepository` and `DriveGateway` are the domain's integration contracts. Simple status, test, refresh, and activity operations use the gateway directly. The domain imports Foundation and has no remote package, UI, Security, subprocess, or filesystem implementation dependencies.

## Infrastructure

`UnlocalFSInfrastructure` depends on Domain. `SavedConnectionRepository` combines `ConnectionStore` and `CredentialStorage`. The application shares one repository instance. A lock serializes complete repository transactions. A failed credential save restores the previous JSON connection or removes a new connection. Delete removes the JSON connection before its credentials, so a failed write keeps both. `Keychain` implements credential storage.

`MountService` implements `DriveGateway`. It owns rclone commands, response decoding, process lifetime, and mount paths. `RcloneRemote` describes how rclone reaches a connection's storage: the target, S3 options, and environment. `MountCommand` builds the `nfsmount` arguments and environment from a remote and `AppPaths`. It checks upload safety before ejecting and again before stopping the service. These checks stay at the integration boundary because uploads can change between operations.

JSON and Keychain encoding remain compatible with existing installations. Foundation Codable conformance stays on the value types to avoid duplicating unchanged schemas.

## Presentation and Application

`UnlocalFSPresentation` contains the view models and depends only on Domain. `AppViewModel` holds connection selection, observed statuses, errors, and busy state. Views read this state and cannot change it directly; they call intent methods such as `toggle`, `delete`, and `checkAgain`. `AppViewModel` also derives the status text, indicator, and notices that views display. It runs domain use cases and translates their results into UI state and desktop feedback.

`ViewModelFactory` creates `ConnectionEditorViewModel` and `ActivityViewModel` with their dependencies. Views get the factory from the environment, so they do not know about repositories, gateways, or use cases. The feature view models have internal initializers.

`UnlocalFS/Presentation` contains the SwiftUI views. `AppDependencies.live()` constructs live dependencies and loads initial connections. `MacOSDesktopServices` implements the presentation's desktop interface. `AppDelegate` owns app polling, network monitoring, sleep/wake events, termination, and Finder services. Views own focus, layout, sheet dismissal, and activity task lifetime.

## Verification

`scripts/test.sh` runs the Domain, Infrastructure, and Presentation SwiftPM tests. `INTEGRATION=1` enables real rclone and isolated Keychain tests. Default tests use real repositories and drive services with stubs at process, credential, or macOS boundaries. `scripts/lint.sh` checks all layers.

For a new workflow, place its rules in Domain, implement required integration behavior in Infrastructure, and inject it from Application. Keep view models responsible for the state the UI displays, and add a factory method when a view needs a new feature view model. Add abstractions when a real boundary requires them.
