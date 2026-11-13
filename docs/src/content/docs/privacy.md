---
title: Privacy
description: Where credentials and files are stored.
---

- Your storage credentials, including Google Cloud service-account keys, and encryption password are stored in the macOS Keychain.
- Turn on **Encrypt files** to encrypt files and file names on your Mac before they upload. See [Encryption](/encryption/).
- UnlocalFS connects directly to your storage provider and its authentication services. There is no UnlocalFS server, account, analytics, or telemetry.
- S3 requests are signed on your Mac. Your S3 secret key is never sent over the network, not even to your storage provider.

## Google Cloud Storage

UnlocalFS uses the service-account key you import to authenticate with Google and access the bucket and folder you configure. It reads file names, metadata, and file contents to show your drive in Finder and open files. It uploads, renames, and deletes files when you request those actions in Finder or another app.

Your service-account key stays in your Mac's Keychain. Files you open are cached locally as described below. Google Cloud Storage data passes directly between your Mac and Google; it does not pass through an UnlocalFS server. Other apps on your Mac can access files you open from the mounted drive.

UnlocalFS does not sell Google user data or use it for advertising. To stop access, disconnect the drive and remove its saved connection. You can also revoke the service-account key or its permissions in Google Cloud. Removing a connection does not delete your files in Google Cloud Storage.

## Limited Use Disclosure

UnlocalFS's use and transfer to any other app of information received from Google APIs will adhere to the [Google API Services User Data Policy](https://developers.google.com/terms/api-services-user-data-policy#additional_requirements_for_specific_api_scopes), including the Limited Use requirements.

## Local files

Files you open are cached on your Mac in `~/Library/Application Support/UnlocalFS/cache`. Encryption protects files uploaded to your provider; the local cache contains the files your apps read and edit.

Drive logs are stored in `~/Library/Logs/UnlocalFS`. Review log contents before sharing them.

[Traffic](/traffic/) is stored in `~/Library/Application Support/UnlocalFS/traffic.sqlite`: each drive's name and the bytes it uploaded and downloaded each day. It holds no file names and never leaves your Mac.
