<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/logo.png">
    <img src="assets/logo.png" alt="UnlocalFS app icon: a blue cloud above a bar, like the macOS eject symbol" width="220">
  </picture>
</p>

<h1 align="center">UnlocalFS</h1>

UnlocalFS puts your S3 or Google Cloud Storage bucket, or your SFTP server, in Finder. Add a connection once, click **Connect**, and it shows up as a drive you can browse, open, and save to like any other folder on your Mac. You can connect the whole bucket, or just one folder of it as its own drive.

It works with Amazon S3, Cloudflare R2, MinIO, Wasabi, DigitalOcean Spaces, any other S3-compatible storage, Google Cloud Storage, and SFTP servers.

## Features

- **Finder integration:** Open, edit, and save files in your bucket or on your SFTP server like any other folder on your Mac.
- **Encrypted drives:** Encrypt file contents and names before upload, so your storage provider can’t read them. Export an rclone config to get your files back without UnlocalFS.
- **Google Cloud Storage:** Sign in with a service-account key. UnlocalFS keeps it in your Keychain.
- **SFTP servers:** Sign in with a password, a private key, or ssh-agent. UnlocalFS only connects to servers listed in your trusted-hosts file.
- **Mount a folder as a drive:** Turn one folder in a bucket or on a server into its own drive.
- **Read-only drives:** Open files while blocking apps from changing or deleting them through the drive.
- **Automatic connections:** Open UnlocalFS at login and connect your chosen drives automatically.
- **Safe disconnects:** Prevent a drive from disconnecting while uploads are pending or need a retry.
- **Drive health:** Check drives after wake and network changes. Reconnect an unavailable drive while keeping its cache.
- **Notifications:** Get told when uploads fail, and when a drive you tried to disconnect finishes uploading.
- **Sharing links:** Right-click a file on an S3 drive in Finder to copy a link that expires after 1 hour, 1 day, or 7 days.
- **Refresh files:** See changes made from other apps or Macs right away.
- **Duplicate connections:** Reuse a drive’s settings and credentials to connect another folder quickly.
- **No tracking:** Connect directly to your storage provider, with no UnlocalFS account, analytics, or telemetry.

## Documentation

Read the [user guide](https://unlocalfs.luizkowalski.net) for installation, connection and drive settings, encryption, sharing links, and troubleshooting.

## Install

Download the latest `UnlocalFS-<version>.dmg` from [Releases](https://github.com/luizkowalski/unlocalfs/releases), open it, and drag **UnlocalFS** to Applications. It needs macOS 15 or later and runs on Apple silicon and Intel Macs.

The app is not notarized yet, so macOS blocks it the first time. Remove the quarantine flag:

```sh
xattr -dr com.apple.quarantine /Applications/UnlocalFS.app
```

You can also open the app once, then choose **System Settings → Privacy & Security → Open Anyway**.

## Build from source

You need Xcode and [Mise](https://mise.jdx.dev/getting-started.html):

```sh
mise install
mise app                 # builds dist/UnlocalFS.app
swiftlint lint --strict  # runs SwiftLint
mise xcode               # opens the project in Xcode
```

Run all tests, including drives mounted against local S3 and SFTP servers and Keychain:

```sh
cd Packages/UnlocalFSCore
xcodebuild test -scheme UnlocalFSCore-Package -destination platform=macOS
```

The tests use `xcodebuild` and not `swift test`, because before Xcode 27 only `xcodebuild` generates the Swift symbols for the String Catalogs.

CI runs these same commands. It runs every test on macOS 15, 26, and 27, then lints and builds the app, for every pull request and every push to `main`. Publishing a GitHub release builds the app with `mise app` and attaches a DMG to the release. The release tag sets the app version.

Builds use ad-hoc signing by default. To use the same development certificate for local Debug and Release builds, including Xcode's Cmd+R, create `Signing.local.xcconfig` in the repository root:

```xcconfig
CODE_SIGN_IDENTITY = Apple Development: Your Name (CERTIFICATE_ID)
DEVELOPMENT_TEAM = YOUR_TEAM_ID
```

Find the certificate name with `security find-identity -v -p codesigning` and your Team ID in Xcode's account settings. This file is ignored by Git. Run `mise xcode` once to regenerate the project; later edits to the file apply on the next build.

Releases use the signing certificate configured in GitHub.

The app uses Clean Architecture with MVVM and Observation:

- `UnlocalFSDomain` owns connection rules, repository and drive interfaces, and save, delete, toggle, share, and quit use cases.
- `UnlocalFSInfrastructure` implements JSON persistence, Keychain storage, rclone commands, and filesystem operations. It depends on Domain.
- `UnlocalFSPresentation` contains the view models. It depends only on Domain. `AppViewModel` shares window and menu bar state; `ViewModelFactory` creates the editor and activity models.
- `UnlocalFS/Presentation` contains the SwiftUI views.
- `UnlocalFS/Application` constructs dependencies and handles macOS lifecycle events, Finder, clipboard, notifications, and login registration.

SwiftPM target dependencies enforce the core boundary. App polling follows the app lifecycle; activity polling follows the view lifecycle. Existing configuration and Keychain formats remain compatible. See [the architecture guide](docs/architecture.md).

## Documentation development

See [docs/README.md](docs/README.md) to run the documentation site locally and add screenshots.

## License

UnlocalFS bundles rclone, which is released under the [MIT License](https://github.com/rclone/rclone/blob/master/COPYING). See `packaging/THIRD_PARTY_NOTICES.txt`.
