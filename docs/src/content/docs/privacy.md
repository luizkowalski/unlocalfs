---
title: Privacy
description: Where credentials and files are stored.
---

- Your access key, secret key, and encryption password are stored in the macOS Keychain.
- Turn on **Encrypt files** to encrypt files and file names on your Mac before they upload. See [Encryption](/encryption/).
- UnlocalFS talks only to the storage endpoint you enter. There is no UnlocalFS server, account, analytics, or telemetry.
- Requests are signed on your Mac. Your secret key is never sent over the network, not even to your storage provider.

## Local files

Files you open are cached on your Mac in `~/Library/Application Support/UnlocalFS/cache`. Encryption protects files uploaded to your provider; the local cache contains the files your apps read and edit.

Drive logs are stored in `~/Library/Logs/UnlocalFS`. Review log contents before sharing them.
