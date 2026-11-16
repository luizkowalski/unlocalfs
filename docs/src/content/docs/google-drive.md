---
title: Google Drive
description: Connect a Google Drive folder with your Google account.
---

UnlocalFS shows a folder in your Google Drive as a drive in Finder. It asks Google only for access to the files that UnlocalFS makes. A new folder starts empty. Files made outside UnlocalFS do not show in the drive.

## Connect Google Drive

1. In UnlocalFS, click **Add Connection** and choose **Google Drive**.
2. Enter a name for the drive. In **Folder**, enter a new folder name such as `UnlocalFS`, reuse a folder that UnlocalFS made, or leave it empty to use the top of My Drive.
3. Click **Sign in with Google**. Your browser opens. Choose your Google account, allow access, and go back to UnlocalFS.
4. Click **Test Connection**, then **Save** and **Connect**.

If the folder does not exist, UnlocalFS makes it when you copy the first file into the drive. The files you copy also show on [drive.google.com](https://drive.google.com).

## What the drive shows

- **Only what UnlocalFS made.** The drive shows the files and folders that you made through UnlocalFS. Files that you make or upload on drive.google.com, or with another app, do not show in it.
- **A folder name that already exists.** If UnlocalFS made the folder, you can use it again. If you made it on drive.google.com or with another app, UnlocalFS cannot see it and makes a second folder with the same name. Use a new name to avoid this.
- **Deleted files.** Files that you delete in Finder go to the Google Drive trash. Empty the trash on drive.google.com to remove them.
- **Upload limit.** [Google limits Workspace users to 750 GB of uploads and copies in 24 hours](https://developers.google.com/workspace/drive/api/guides/limits#additional_constraints). If you reach the limit, uploads stay queued and retry automatically. Google may block more uploads for 24 hours. The drive does not disconnect while uploads wait.

## Sign in again

If Google ends the sign-in, for example because you removed access in your Google account, waiting uploads fail and the drive shows **Needs Google sign-in**. Click **Sign In Again…** on the drive page and choose the same Google account. The drive stays connected, and waiting uploads resume.

If no uploads wait, Finder can show read errors without a sign-in notice. Disconnect and connect the drive. UnlocalFS then asks you to sign in again.

On the drive page, **Sign In Again…** rejects a different Google account and keeps the saved sign-in. In the connection editor, you cannot save a different Google account for an existing connection. Its files are in the original account.

## Remove access

Removing the connection deletes the sign-in from your Mac. It does not remove the access UnlocalFS has in your Google account, and it does not delete your files in Google Drive. To remove the access, open [Third-party apps & services](https://myaccount.google.com/connections) in your Google account and remove UnlocalFS.

Share links are not available for Google Drive connections.
