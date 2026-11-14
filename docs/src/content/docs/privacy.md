---
title: Privacy
description: Where credentials and files are stored.
---

- Your storage credentials, including Google sign-in tokens and Google Cloud service-account keys, and encryption password are stored in the macOS Keychain.
- Turn on **Encrypt files** to encrypt files and file names on your Mac before they upload. See [Encryption](/encryption/).
- UnlocalFS connects directly to your storage provider and its authentication services. There is no UnlocalFS server, account, analytics, or telemetry.
- S3 requests are signed on your Mac. Your S3 secret key is never sent over the network, not even to your storage provider.

## Google Cloud Storage

UnlocalFS uses your Google sign-in or the service-account key you import to authenticate with Google and access the bucket and folder you configure. Google sign-in asks for one permission, `https://www.googleapis.com/auth/devstorage.read_write`: read and write access to Cloud Storage. UnlocalFS does not ask for your name, email address, or other Google Account data.

**Data accessed.** File and folder names, metadata (size, dates, and content type), and file contents in the bucket and folder you configure, and the access and refresh tokens that Google gives at sign-in.

**Data use.** UnlocalFS uses this data only to show your bucket as a drive in Finder. It lists folders and opens files. It uploads, renames, and deletes files only when you do those actions in Finder or another app. UnlocalFS does not make aggregated or anonymized data from Google user data. It does not use Google user data for advertising, for credit or lending decisions, or to develop, improve, or train AI or machine learning models.

**Data sharing.** UnlocalFS does not sell, share, or transfer Google user data to any person or company. Data goes directly between your Mac and Google. There is no UnlocalFS server, and the developer never receives your files or tokens. Other apps on your Mac can read the files you open from the drive, as with any disk.

**Data protection.** Google sign-in happens in your browser, so UnlocalFS never sees your Google password. Google sends the sign-in to your Mac at `127.0.0.1`. Tokens and service-account keys are stored in the macOS Keychain. All requests to Google use HTTPS.

**Retention and deletion.** UnlocalFS keeps tokens in the Keychain and files you open in the local cache until you remove the connection. When you remove a connection, UnlocalFS deletes its tokens from the Keychain and deletes its local cache. Drive logs can contain file names; each drive keeps at most three log files of 3 MB, and older entries are deleted. To stop access at Google, revoke UnlocalFS in your [Google Account](https://myaccount.google.com/connections), or revoke the service-account key or its permissions in Google Cloud. Removing a connection does not delete your files in Google Cloud Storage.

## Limited Use Disclosure

UnlocalFS's use and transfer to any other app of information received from Google APIs will adhere to the [Google API Services User Data Policy](https://developers.google.com/terms/api-services-user-data-policy#additional_requirements_for_specific_api_scopes), including the Limited Use requirements.

## Local files

Files you open are cached on your Mac in `~/Library/Application Support/UnlocalFS/cache`. Encryption protects files uploaded to your provider; the local cache contains the files your apps read and edit.

Drive logs are stored in `~/Library/Logs/UnlocalFS`. Review log contents before sharing them.

[Traffic](/traffic/) is stored in `~/Library/Application Support/UnlocalFS/traffic.sqlite`: each drive's name and the bytes it uploaded and downloaded each day. It holds no file names and never leaves your Mac.
