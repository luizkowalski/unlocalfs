---
title: Troubleshooting
description: Resolve connection, upload, and Finder issues.
---

## macOS blocks the app

The app is not notarized yet. Follow the first-launch steps in [Getting started](/getting-started/#install).

## A connection test fails

Check the endpoint, region, bucket, and credentials in [Connection settings](/connection-settings/). Use the service endpoint without the bucket or a folder path. Include the session token when your credentials require one.

Check that your credentials have access to the bucket and that your storage endpoint is reachable.

For encrypted drives, an incorrect password or unencrypted names in the top folder can prevent connection. See [Encryption](/encryption/).

## A drive needs reconnecting

Click **Reconnect** in the app or menu bar. UnlocalFS tries a normal eject, waits for the old service to stop, and connects using the same cache. Recovery stops if the drive cannot eject or the old service cannot stop. Close files open on the drive before trying again.

Wake and network changes refresh drive health. Reconnecting stays manual.

## Uploads fail or disconnect is blocked

Select the drive to see pending uploads and retries. UnlocalFS sends a notification when files cannot upload. Restore network access and check that the credentials still allow writes.

The app will not disconnect while uploads are pending or need a retry. If you tried to disconnect, it sends a notification when uploads finish. Do not delete the cache while uploads are pending.

Click **Log** in the drive toolbar to inspect the drive log. Logs are in `~/Library/Logs/UnlocalFS`.

## Changes from another app do not appear

Changes made through another app, drive, or Mac normally appear within 5 minutes. Click **Refresh** in the app, or choose **Refresh Files** in the sidebar menu or menu bar, to see them sooner.

Avoid editing the same file through two drives at once: one save can overwrite the other.

## Share link services are missing

Open UnlocalFS once. Enable the entries in **System Settings → Keyboard → Keyboard Shortcuts → Services → Files and Folders**. Links require a connected, unencrypted drive and an uploaded file.

## Finder adds .DS_Store files

To stop Finder from writing `.DS_Store` files on network drives, run:

```sh
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
killall Finder
```

This setting applies to all network drives. macOS can still add `._` files when copying files with extended attributes.
