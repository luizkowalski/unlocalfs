<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/logo.png">
    <img src="assets/logo.png" alt="UnlocalFS app icon: a blue cloud above a bar, like the macOS eject symbol" width="220">
  </picture>
</p>

<h1 align="center">UnlocalFS</h1>

UnlocalFS puts your S3 bucket in Finder. Add a bucket once, click **Connect**, and it shows up as a drive you can browse, open, and save to like any other folder on your Mac.

It works with Amazon S3, Cloudflare R2, MinIO, Wasabi, DigitalOcean Spaces, and any other S3-compatible storage.

## How it works

UnlocalFS runs [rclone](https://rclone.org), the open-source cloud storage tool, and connects it to the NFS client that is built into macOS. There is no kernel extension, no FUSE driver, and no administrator password. rclone is bundled inside the app, so there is nothing else to install.

Drives mount in `~/UnlocalFS`. Files you open are cached on your Mac, so apps can read and edit them at local speed. Changes upload to your bucket after you close the file. The app shows pending uploads and will not disconnect a drive until they finish.

Select a connected drive to see its activity: queued uploads, uploads waiting to retry, and active uploads and downloads with progress when available. The list refreshes every few seconds. Deletions are not shown because rclone does not report Finder deletions in its activity data. Disconnect the drive yourself when you are finished.

## Privacy

- Your access key and secret key are stored in the macOS Keychain.
- UnlocalFS talks only to the storage endpoint you enter. There is no UnlocalFS server, account, analytics, or telemetry.
- Requests are signed on your Mac. Your secret key is never sent over the network, not even to your storage provider.

## Install

Download the latest `UnlocalFS-<version>.zip` from [Releases](https://github.com/luizkowalski/unlocalfs/releases), unzip it, and move **UnlocalFS** to Applications. It needs macOS 15 or later and runs on Apple silicon and Intel Macs.

The app is not notarized yet, so macOS blocks it the first time. Remove the quarantine flag:

```sh
xattr -dr com.apple.quarantine /Applications/UnlocalFS.app
```

You can also open the app once, then choose **System Settings → Privacy & Security → Open Anyway**.

## Use

1. Click **Add Connection**.
2. Enter a name, your provider, the bucket, the endpoint, and the region. Use the service endpoint without the bucket name. For Cloudflare R2, use `https://<ACCOUNT_ID>.r2.cloudflarestorage.com` and region `auto`.
3. Enter your access key and secret key, then click **Test Connection** and **Save**.
4. Click **Connect**, then **Open in Finder**.

Closing the window removes UnlocalFS from the Dock and keeps it in the menu bar, where you can connect, disconnect, and open drives. Choose **Open UnlocalFS** to show the window and Dock icon again. UnlocalFS will not quit while a drive is connected, so pending uploads are never cut off. Disconnect your drives first. If the app closes unexpectedly, the drives keep running and the app picks them up again the next time it opens.

## Good to know

- S3 is not a local disk. Saving a large file takes as long as uploading it. Try UnlocalFS with files you have copies of first.
- Each drive has a cache limit (default 128 MB) and an optional amount of disk space to keep free. When the cache is over the limit, rclone removes the files you have not opened for the longest time. Open files and pending uploads stay, so the cache can go over the limit for a short time. The cache lives in `~/Library/Application Support/UnlocalFS/cache`. Do not delete it while uploads are pending.
- Finder writes `.DS_Store` files to folders you open, and they upload to your bucket like other files. To stop Finder from writing them on network drives, run the commands below. This setting applies to all network drives, not only UnlocalFS. macOS can also add `._` files when you copy files that have extended attributes. UnlocalFS cannot stop these files.

  ```sh
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
  killall Finder
  ```

- Drives do not connect automatically at login.
- Logs are in `~/Library/Logs/UnlocalFS`. Click **Open Log** in the app to see the log of a drive.

## Build from source

You need Xcode and [Mise](https://mise.jdx.dev/getting-started.html):

```sh
mise install
mise app      # builds dist/UnlocalFS.app
mise test     # runs the tests
mise lint     # runs SwiftLint
mise xcode    # opens the project in Xcode
```

CI lints, tests, and builds every push. Pushing a tag such as `v0.2.0` builds the app and publishes a GitHub release with it. The tag sets the app version.

## License

UnlocalFS bundles rclone, which is released under the [MIT License](https://github.com/rclone/rclone/blob/master/COPYING). See `packaging/THIRD_PARTY_NOTICES.txt`.
