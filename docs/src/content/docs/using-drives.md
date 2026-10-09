---
title: Using drives
description: Manage file activity, refresh files, and disconnect safely.
---

Drives mount in `~/UnlocalFS`. Files you open are cached on your Mac, so apps can read and edit them at local speed. Changes upload to your bucket after you close the file. The app shows pending uploads and will not disconnect a drive until they finish.

Select a connected drive to see its activity. When nothing is moving, it tells you that all changes are uploaded. While files move, it shows how many files are uploading, how much is left, the current speed, about how long the uploads will take, and the first 10 files: active uploads and downloads with progress when available, then uploads waiting to retry, then queued uploads. Only uploads count toward how much is left: an upload always sends the whole file, but a download gets only the parts an app reads. Finder and Quick Look read parts of files to show previews, so files you did not open can show as downloading for a few seconds and stop before 100%. The list refreshes every few seconds. The bottom of the window shows how much the drive caches on your Mac. When the cache is full, the oldest copies are cleared. Deletions are not shown because rclone does not report Finder deletions in its activity data. Disconnect the drive yourself when you are finished.

UnlocalFS sends a notification when files on a drive cannot upload. If you click **Disconnect** while uploads are pending, it also tells you when they finish, so you know it is safe to disconnect.

Changes made to the bucket from other apps or Macs show within 5 minutes. To see them sooner, click **Refresh** in the app, or choose **Refresh Files** in the sidebar menu or the menu bar.

If a drive shows **Needs reconnect**, click **Reconnect** in the app or menu bar. UnlocalFS tries a normal eject, waits for the old service to stop, and connects again using the same cache. Recovery stops if the drive cannot eject or the old service cannot be stopped. Wake and network changes refresh drive health; reconnecting stays manual.

## Menu bar and quitting

Closing the window removes UnlocalFS from the Dock and keeps it in the menu bar, where you can connect, disconnect, and open drives. Choose **Open UnlocalFS** to show the window and Dock icon again. UnlocalFS will not quit while a drive is connected, so pending uploads are never cut off. Disconnect your drives first. If the app closes unexpectedly, the drives keep running and the app picks them up again the next time it opens.

## Shortcuts

| Action | Shortcut |
|---|---|
| New connection | ⌘N |
| Edit the selected connection | ⌘, |
| Duplicate the selected connection | ⌘D |
| Delete the selected connection | ⌘⌫ |

Right-click a drive in the sidebar to open it in Finder, edit, duplicate, or delete it. You can only edit or delete a drive while it is disconnected.

## Finder files and dates

S3 has no real folders, so folders show the time the drive connected as their modification date. Files show their own dates.

Finder can write `.DS_Store` files, and macOS can add `._` files when copying files with extended attributes. These files upload like other files. See [troubleshooting](/troubleshooting/) for the Finder setting.
