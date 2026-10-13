---
title: Using drives
description: Manage file activity, refresh files, and disconnect safely.
---

Drives mount in `~/UnlocalFS`. Files you open are cached on your Mac, so apps can read and edit them at local speed. Changes upload to your bucket after you close the file. The app shows pending uploads and will not disconnect a drive until they finish.

Select a connected drive to see its activity. When nothing is moving, the empty Activity table tells you that all changes are uploaded. While files move, it shows how many files are uploading and the current speed, above a table of up to 10 files with their folder, status, and size. Failed uploads come first, then the other files sorted by name. A failed upload shows **Upload failed**; click it to see the error from the storage server and when UnlocalFS tries again. Failed uploads do not count in the uploading total. A file that uploads again after a failure shows an orange retry icon next to its progress. Uploads and downloads show their own progress when available. A finished upload, or a download that got the whole file, stays in the table as Uploaded or Downloaded for 10 seconds, so small files that move in less than a second still show. A download gets only the parts of a file that an app reads. Finder and Quick Look read parts of files to show previews, so files you did not open can show as downloading for a few seconds and stop before 100%. The list refreshes four times a second while files move. The bottom of the window shows how much the drive caches on your Mac. When the cache is full, the oldest copies are cleared. Deletions are not shown because rclone does not report Finder deletions in its activity data. Disconnect the drive yourself when you are finished.

UnlocalFS sends a notification when files on a drive cannot upload, with the error when the storage server reports one. While uploads fail, the drive page shows the latest error below its status. UnlocalFS tries again on its own, up to every 5 minutes, while the drive stays connected. If you click **Disconnect** while uploads are pending, a system alert explains that the drive will stay connected until uploads finish. Choose **OK** to keep working. Its status shows the pending upload count, and the activity list shows progress. The app tells you when uploads finish, so you know it is safe to try disconnecting again. Downloads remain visible in the activity list; they do not add a separate disconnect restriction.

If macOS cannot eject a drive, a system alert asks you to close files and stop apps using it. Choose **Keep Connected** to leave it mounted, or **Try Disconnect Again** after closing the files. Retrying only disconnects; it does not reconnect a drive that has already been disconnected. Other connection problems show their explanation below the drive status as plain text. **Disconnect All** starts without confirmation and stops at the first drive it cannot disconnect and selects that drive. Resolve the problem, then try again to disconnect the remaining drives.

Changes made to the bucket from other apps or Macs show within 5 minutes. To see them sooner, click **Refresh** in the app, or choose **Refresh Files** in the sidebar menu or the menu bar.

If a drive shows **Needs reconnect**, click **Reconnect** in the app or menu bar. UnlocalFS tries a normal eject, waits for the old service to stop, and connects again using the same cache. Recovery stops if the drive cannot eject or the old service cannot be stopped. Wake and network changes refresh drive health; reconnecting stays manual.

The activity table shows each file’s name, folder, transfer status, and size. When you switch drives, the table shows **Checking activity…** until it receives that drive’s activity. Drag the column headers’ dividers to adjust their widths. Click **Upload failed** to see the error and retry time.

## Menu bar and quitting

Each drive in the menu shows its provider icon. Encrypted drives also show a lock after their name.

Closing the window removes UnlocalFS from the Dock and keeps it in the menu bar, where you can connect, disconnect, and open drives. Choose **Open UnlocalFS** to show the window and Dock icon again. The menu-bar icon shows turning yellow arrows while uploads are pending and a blue arrow while files download. With Reduce Motion enabled, the upload arrows stay still. Finder previews also count as downloads. If a menu-bar disconnect is blocked by pending uploads or an eject failure, the main window opens to show its alert. When you quit with drives connected, choose **Disconnect All and Quit** to try to disconnect them first, or **Cancel** to keep the app running. The app tries every active drive and quits even if some cannot disconnect. Those drives keep running and are picked up when you open the app again. If the app closes unexpectedly, the drives keep running and the app picks them up again the next time it opens.

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
