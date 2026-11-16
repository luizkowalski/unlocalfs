---
title: Getting started
description: Install UnlocalFS and connect your first drive.
---

## Install

Download the latest `UnlocalFS-<version>.dmg` from [Releases](https://github.com/luizkowalski/unlocalfs/releases), open it, and drag **UnlocalFS** to Applications. It requires macOS 15 or later and a Mac with Apple silicon (M1 or later).

The app is not notarized yet, so macOS blocks it the first time. Remove the quarantine flag:

```sh
xattr -dr com.apple.quarantine /Applications/UnlocalFS.app
```

You can also open the app once, then choose **System Settings → Privacy & Security → Open Anyway**.

## Connect a drive

1. Click **Add Connection**.
2. Choose your storage provider:

   - **SFTP:** follow [SFTP connection settings](/connection-settings/#sftp).
   - **Google Cloud Storage:** create the bucket first, then follow [Google Cloud Storage](/google-cloud-storage/).
   - **Google Drive:** follow [Google Drive](/google-drive/).
   - **S3-compatible storage:** enter a name, your provider, the bucket, the endpoint, and the region. Use the service endpoint without the bucket name. For Cloudflare R2, use `https://<ACCOUNT_ID>.r2.cloudflarestorage.com` and region `auto`. Enter your access key and secret key.

3. Click **Test Connection**, then **Save**.
4. Click **Connect**, then **Open in Finder**.

For an S3 or Google Cloud Storage bucket, leave **Folder** empty to show the whole bucket. Start with files you have copies of. See [connection settings](/connection-settings/) for help with each field.

## Open at login

Choose **Open at Login** in the menu bar to launch UnlocalFS when you log in. Turn on **Connect on start up** in each drive’s settings to connect that drive when the app opens. These are separate settings.
