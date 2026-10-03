---
title: Connection settings
description: Understand the storage and credential fields for a drive.
---

Choose **Add Connection**, or select a disconnected drive and choose **Edit**. The **Connection** tab describes the storage to connect. Choose **SFTP** as the provider to connect a server; the S3 sections below do not apply to it.

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

## SFTP

| Field | What to enter |
| --- | --- |
| Host and port | The server's host name or IP address, and its SSH port. The default is 22. |
| Username | The account to sign in with. |
| Remote folder | An optional folder. Leave it empty for your home folder. Start with `/` for a path from the server's root. Spaces and slashes are kept as you type them. |
| Sign in with | **Password**, **Private key**, or **SSH agent**. Only the selected option is used. |
| Private key | The path to your key file, and its passphrase if it has one. UnlocalFS reads the file and never copies it. |
| Agent socket | Optional. Leave empty to use the agent your Mac started. |
| Trusted hosts | The file that lists the servers you trust. The default is `~/.ssh/known_hosts`. |

Passwords and key passphrases are stored in your Mac's Keychain. Key files stay where they are.

UnlocalFS checks the server against the trusted-hosts file every time you test or connect. If the server is unknown or its key changed, the connection fails. UnlocalFS never adds to or changes the file. To trust a new server, connect once with `ssh user@host`, check that the fingerprint is the one your server administrator gave you, and accept it. If a trusted server's key changed, find out why before you edit the file.

Private keys in OpenSSH format are supported, with or without a passphrase. UnlocalFS has been checked with ed25519 keys. SSH config files, jump hosts, and interactive logins such as multi-factor prompts are not supported.

**Test Connection** lists the folder. It shows that you can reach the folder, not that you can write to it. If a server refuses a write, the drive's activity list shows the failed upload.

After you save an SFTP drive, you cannot change its server, port, username, folder, or encryption. Choose **Duplicate** to connect another server or folder. You can still change how you sign in and the trusted-hosts file. Drives saved with SFTP cannot be opened by older versions of UnlocalFS.

## Test and save

Click **Test Connection** to check the connection, then **Save**. Testing does not save the drive or mount it in Finder. Click **Connect** after saving.

You can edit a drive only while it is disconnected. Choose **Duplicate** to reuse its settings and credentials for another drive.
