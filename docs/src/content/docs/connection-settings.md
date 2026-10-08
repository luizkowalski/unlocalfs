---
title: Connection settings
description: Understand the storage and credential fields for a drive.
---

Choose **Add Connection**, or select a disconnected drive and choose **Edit**. The **Connection** tab describes the storage to connect. Choose **SFTP** to connect a server or **Google Cloud Storage** to connect a GCS bucket; the S3 sections below do not apply to them.

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

## Google Cloud Storage

| Field | What to enter |
| --- | --- |
| Bucket | The bucket name, without a folder path. |
| Folder | An optional path inside the bucket, such as `clients/acme`. Leave empty for the whole bucket. |
| Service account key | Click **Import key…** and choose the JSON key file you downloaded from Google Cloud. |

To create the key, open **IAM & Admin → Service Accounts** in the Google Cloud console, create a service account, and give it the **Storage Object User** role on the bucket. Then choose **Keys → Add key → Create new key → JSON**. That role is enough to list, read, write, rename, and delete files. UnlocalFS does not need access to the bucket's settings.

UnlocalFS stores the key in your Mac's Keychain and shows only the service account's email. Delete the downloaded file after you import it. Anyone with the key can use the service account.

**Test Connection** lists the folder. It shows that you can reach the bucket, not that you can write to it. Links are not available for Google Cloud Storage drives. Drives saved with Google Cloud Storage cannot be opened by older versions of UnlocalFS.

## SFTP

| Field | What to enter |
| --- | --- |
| Host and port | The server's host name or IP address, and its SSH port. The default is 22. |
| Username | The account to sign in with. |
| Remote folder | An optional folder. Leave it empty for your home folder. Start with `/` for a path from the server's root. Spaces and slashes are kept as you type them. |
| Sign in with | **Password**, **Private key**, or **SSH agent**. Only the selected option is used. |
| Private key | The path to your key file, and its passphrase if it has one. UnlocalFS reads the file and never copies it. |
| Agent socket | Optional. Leave empty to use the agent your Mac started. |

Passwords and key passphrases are stored in your Mac's Keychain. Key files stay where they are.

The first test or connection shows the server's SHA256 key fingerprint. Check it with your server administrator, then choose **Trust and connect**. UnlocalFS saves the approved keys in `~/Library/Application Support/UnlocalFS/known_hosts` and checks them every time you connect. It does not read or change your Mac's SSH files, such as `~/.ssh/known_hosts`. If the key changes, UnlocalFS stops the connection and asks you to approve the new key. Find out why it changed before you accept it. When you delete the last drive for a server, UnlocalFS removes that server's keys from the file.

Drives saved with an earlier version of UnlocalFS used a trusted-hosts file that you chose. They now use the UnlocalFS file, so their next connection asks you to approve the server key once.

Private keys in OpenSSH format are supported, with or without a passphrase. UnlocalFS has been checked with ed25519 keys. SSH config files, jump hosts, and interactive logins such as multi-factor prompts are not supported.

**Test Connection** lists the folder. It shows that you can reach the folder, not that you can write to it. If a server refuses a write, the drive's activity list shows the failed upload.

After you save an SFTP drive, you cannot change its folder or encryption. Choose **Duplicate** to connect another folder. You can still change the host, port, username, and how you sign in. Before you point a drive at a different server, make sure the files in its cache belong there, because pending uploads go to the new server. Drives saved with SFTP cannot be opened by older versions of UnlocalFS.

## Test and save

Click **Test Connection** to check the connection, then **Save**. Testing does not save the drive or mount it in Finder. Click **Connect** after saving.

You can edit a drive only while it is disconnected. Choose **Duplicate** to reuse its settings and credentials for another drive.
