---
title: Google Drive
description: Connect a Google Drive folder with your Google account.
---

UnlocalFS shows a folder in your Google Drive as a drive in Finder. It asks Google only for access to the files that UnlocalFS makes. So the drive starts empty, and files that you already have in Google Drive do not show in it.

## Connect Google Drive

1. In UnlocalFS, click **Add Connection** and choose **Google Drive**.
2. Enter a name for the drive. In **Folder**, enter a new folder name such as `UnlocalFS`, or leave it empty to use the top of My Drive.
3. Click **Sign in with Google**. Your browser opens. Choose your Google account, allow access, and go back to UnlocalFS.
4. Click **Test Connection**, then **Save** and **Connect**.

UnlocalFS makes the folder when you copy the first file into the drive. The files you copy show in that folder on [drive.google.com](https://drive.google.com).

## What the drive shows

- **Only what UnlocalFS made.** The drive shows the files and folders that you made through UnlocalFS. Files that you make or upload on drive.google.com, or with another app, do not show in it.
- **A folder name that already exists.** If My Drive already has a folder with the name you entered, UnlocalFS cannot see it and makes a second folder with the same name. Use a new name.
- **Deleted files.** Files that you delete in Finder go to the Google Drive trash. Empty the trash on drive.google.com to remove them.
- **Upload limit.** Google lets each account upload about 750 GB a day. After that, uploads fail until the next day. UnlocalFS keeps them in the queue and the drive does not disconnect while they wait.

## Sign in again

If Google ends the sign-in, for example because you removed access in your Google account, the drive shows **Needs Google sign-in**. Click **Sign In Again…** on the drive page and choose the same Google account. The drive stays connected, and the uploads that wait go on.

UnlocalFS checks the account. If you choose a different account, it shows an error and keeps the old sign-in, because the drive's files are in the first account.

## Remove access

Removing the connection deletes the sign-in from your Mac. It does not remove the access UnlocalFS has in your Google account, and it does not delete your files in Google Drive. To remove the access, open [Third-party apps & services](https://myaccount.google.com/connections) in your Google account and remove UnlocalFS.

Links are not available for Google Drive drives.
