---
title: Privacy
description: Where credentials and files are stored.
---

- Your access key, secret key, encryption password, and Google sign-in are stored in the macOS Keychain.
- Turn on **Encrypt files** to encrypt files and file names on your Mac before they upload. See [Encryption](/encryption/).
- UnlocalFS talks only to the storage endpoint you enter, and to Google's sign-in service when you use a Google account. There is no UnlocalFS server, account, analytics, or telemetry.
- Google sign-in happens in your browser. UnlocalFS never sees your Google password. It asks Google only for read and write access to Cloud Storage, and receives the sign-in on your Mac at `127.0.0.1`.
- Requests are signed on your Mac. Your secret key is never sent over the network, not even to your storage provider.

## Local files

Files you open are cached on your Mac in `~/Library/Application Support/UnlocalFS/cache`. Encryption protects files uploaded to your provider; the local cache contains the files your apps read and edit.

Drive logs are stored in `~/Library/Logs/UnlocalFS`. Review log contents before sharing them.

[Traffic](/traffic/) is stored in `~/Library/Application Support/UnlocalFS/traffic.sqlite`: each drive's name and the bytes it uploaded and downloaded each day. It holds no file names and never leaves your Mac.
