---
title: Drive settings
description: Choose how a drive connects, caches files, and transfers data.
---

Open a connection’s **Settings** tab. You can edit a drive while it is disconnected.

## General

| Setting | Default | Effect |
| --- | --- | --- |
| Read-only | Off | Blocks apps from creating, changing, or deleting files through this drive. Use read-only storage credentials too when access must be restricted at the provider. |
| Connect on start up | Off | Connects this drive when UnlocalFS opens. Use **Open at Login** in the menu bar to launch the app at login. |

## Encryption

**Encrypt files** is off by default. Enable it when adding a drive to encrypt file contents and names before upload. Enter and confirm an encryption password.

You cannot change this option after saving a new drive. Keep the password somewhere safe: losing it means losing access to the encrypted files. Read the [encryption guide](/encryption/) before using it.

## Amazon S3

These settings appear only when the provider is **Amazon S3**. S3-compatible providers do not use them.

| Setting | Default | Choices |
| --- | --- | --- |
| Storage class | Standard | Standard, Intelligent-Tiering, Standard-IA, One Zone-IA, Glacier Instant Retrieval |
| Server-side encryption | Bucket default | Bucket default, S3-managed keys (SSE-S3), AWS KMS (SSE-KMS) |
| KMS key | Empty | A key ID, an `alias/` name, or a key ARN. Shown only for AWS KMS. |

Changes apply to files that upload after you connect the drive again. Files already in the bucket keep their storage class and encryption.

**Storage class** sets where AWS stores new files and how it bills them:

- **Intelligent-Tiering** moves files between access tiers based on use. AWS adds a small monitoring fee for each object.
- **Standard-IA**, **One Zone-IA**, and **Glacier Instant Retrieval** cost less to store but more to read. AWS bills a minimum object size and a minimum storage time. Each time you save a file, the drive uploads it again, so files you edit often cost more.
- When you rename or move a file or folder, the drive copies the objects on the server and deletes the originals. In these classes, AWS bills those deletes as early deletions.
- Glacier Flexible Retrieval and Deep Archive are not offered. Files in those classes cannot be opened until they are restored.

**Server-side encryption** sets how AWS encrypts new files at rest:

- **Bucket default** sends no encryption setting, so the bucket's default encryption applies. Keep it when the bucket already uses the key your team requires.
- **S3-managed keys (SSE-S3)** uses keys that AWS manages.
- **AWS KMS (SSE-KMS)** uses a key in AWS KMS. Leave **KMS key** empty to use the AWS-managed key `aws/s3`. A key in another AWS account needs its full ARN. Your credentials need `kms:GenerateDataKey` and `kms:Decrypt` on the key.

**Test Connection** does not upload a file, so it does not check the KMS key. If the key or permission is wrong, uploads fail and the drive shows **Upload needs attention**.

## Cache

Files you open are cached in `~/Library/Application Support/UnlocalFS/cache`.

| Setting | Default | Choices |
| --- | --- | --- |
| Cache limit | 1 GB | 128 MB, 512 MB, 1 GB, 5 GB, 10 GB, 50 GB |
| Keep free on disk | Off | Off, 1 GB, 5 GB, 10 GB, 20 GB |

**Cache limit** sets the target maximum size for this drive’s cache. Increase it if you often reopen large files and have disk space available. Files you have not opened for the longest time are removed first.

**Keep free on disk** lets the cache remove older files to keep the selected amount of local disk space available. Enable it if local disk space is limited.

Open files and pending uploads stay in the cache. These limits are not hard caps: the cache can exceed them while files are in use or waiting to upload. Never delete the cache while uploads are pending.

## Advanced

| Setting | Default | Choices |
| --- | --- | --- |
| Bandwidth limit | Off | Off, 1 MB/s, 5 MB/s, 10 MB/s, 25 MB/s, 50 MB/s, 100 MB/s |
| Parallel transfers | 4 | 1, 2, 4, 8, 16, 32 |

**Bandwidth limit** limits uploads and downloads for this drive. Leave it off for no configured limit. Lower it when transfers compete with other work on your network. Values are in megabytes per second, not megabits per second.

**Parallel transfers** controls how many files can transfer at once. Start with the default. Lower it to reduce concurrent transfers, or try a higher value for workloads with many files. More transfers do not guarantee higher throughput.
