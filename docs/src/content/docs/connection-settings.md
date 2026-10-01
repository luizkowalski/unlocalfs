---
title: Connection settings
description: Understand the storage and credential fields for a drive.
---

Choose **Add Connection**, or select a disconnected drive and choose **Edit**. The **Connection** tab describes the storage to connect.

## Storage

| Field | What to enter |
| --- | --- |
| Name | A unique drive name. It is used for the folder under `~/UnlocalFS`. Do not use slashes or colons. |
| Provider | Your storage provider, or **S3 compatible** for another service. |
| Endpoint | The HTTP or HTTPS service URL, without a bucket name, path, credentials, or query. |
| Region | The region from your provider. The default is `auto`; Cloudflare R2 uses `auto`. |
| Bucket | The bucket name, without a folder path. |
| Folder | An optional path inside the bucket, such as `clients/acme`. Leave empty for the whole bucket. Do not add leading or trailing slashes. |

For Cloudflare R2, the endpoint is `https://<ACCOUNT_ID>.r2.cloudflarestorage.com`. Use the account ID from your Cloudflare account.

A folder changes what the drive shows. It does not restrict what your credentials can access. See [folder drives](/folder-drives/).

## Credentials

| Field | What to enter |
| --- | --- |
| Access key | The access key ID issued by your provider. |
| Secret key | The secret paired with that access key. |
| Session token | Required when using temporary credentials that include a token. Otherwise leave empty. |

Credentials are stored in your Mac’s Keychain. Temporary credentials stop working when they expire; update them in the connection before connecting again.

## Test and save

Click **Test Connection** to check the connection, then **Save**. Testing does not save the drive or mount it in Finder. Click **Connect** after saving.

You can edit a drive only while it is disconnected. Choose **Duplicate** to reuse its settings and credentials for another drive.
