---
title: Duplicating files
description: Copy files inside a drive without downloading them.
---

When you duplicate or copy a file inside a drive in Finder, Finder downloads the whole file and uploads it again. A large file takes a long time, uses your network, and fills the cache. **Duplicate on Server** tells your storage to copy the file itself. Nothing downloads to your Mac and nothing uploads from it.

Right-click files in a connected drive, choose **Services**, then **Duplicate on Server**. Each copy goes in the same folder and gets the name that Finder uses: "report copy.pdf", then "report copy 2.pdf". UnlocalFS sends a notification when the copies are ready, and they show in Finder a few seconds later.

- Duplicate on Server works on Amazon S3, other S3-compatible storage, and Google Cloud Storage, also when the drive is encrypted.
- It is not available for SFTP drives, because the server cannot copy files for UnlocalFS. It is not available for read-only drives.
- Wait until a file finishes uploading before you duplicate it.
- Select files, not folders.
- Large files can take a minute or more. The drive does not disconnect while a copy runs.
- Finder's own **Duplicate** and copy and paste still download and upload the file.
- If the entry does not show, open UnlocalFS once. You can turn it on and add a keyboard shortcut in **System Settings → Keyboard → Keyboard Shortcuts → Services → Files and Folders**.
