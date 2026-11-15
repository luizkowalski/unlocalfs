---
title: Google Cloud Storage
description: Create a bucket and connect it with your Google account.
---

UnlocalFS connects to a bucket that already exists. It does not create buckets. Create the bucket in the Google Cloud console first, then sign in from UnlocalFS.

## Create a bucket

1. Open the [Google Cloud console](https://console.cloud.google.com/) and choose a project, or create one. Cloud Storage needs a project with billing turned on.
2. Open **Cloud Storage → Buckets** and click **Create**.
3. Enter a bucket name. The name must be unique across all of Google Cloud and use lowercase letters, numbers, dashes, underscores, and dots.
4. Choose a location near you. Keep the other default settings, then click **Create**.

If you created the bucket in your own project, your Google account already has access. Skip to [Connect the bucket](#connect-the-bucket).

## Give another account access

To let another Google account use the bucket, open the bucket, click **Permissions**, then **Grant access**. Add the account's email address and choose the role **Storage Object User**. That role lets UnlocalFS list, read, write, rename, and delete files. It does not let UnlocalFS change the bucket's settings.

## Connect the bucket

1. In UnlocalFS, click **Add Connection** and choose **Google Cloud Storage**.
2. Enter a name for the drive and the bucket name. To show only one folder of the bucket, enter it in **Folder**.
3. Keep **Sign in with** set to **Google account** and click **Sign in with Google**. Your browser opens.
4. Choose the Google account that has access to the bucket, allow access, and go back to UnlocalFS.
5. Click **Test Connection**, then **Save** and **Connect**.

If the test fails, check the bucket name and the account's role. See [Troubleshooting](/troubleshooting/#a-google-cloud-storage-connection-fails).

To use a key file instead of your Google account, see [Service account key](/connection-settings/#service-account-key).
