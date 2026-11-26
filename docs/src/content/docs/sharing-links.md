---
title: Sharing links
description: Copy temporary download links from Finder.
---

Right-click a file in a connected drive and choose **Copy Share Link (1 Hour)**, **Copy Share Link (1 Day)**, or **Copy Share Link (7 Days)**. These items need the UnlocalFS Finder extension; see [Finder badges and menu](/using-drives/#finder-badges-and-menu). UnlocalFS copies a presigned link to the clipboard and sends a notification. Anyone with the link can download the file until the link expires. They do not need your keys. If you select more than one file, you get one link on each line.

- Links are not available for SFTP, Google Cloud Storage, or Google Drive connections. UnlocalFS tells you so before it reads any credentials.
- Links are not available for encrypted drives, because the link would point to encrypted data. The Finder extension does not show the items for these drives.
- Wait until a file finishes uploading before you copy its link. If the drive shows **Needs reconnect**, reconnect it first.
- You cannot cancel a link before it expires. To stop all links early, replace the access key.
- A link includes your access key ID, but never your secret key. If you use temporary credentials, the link stops working when the credentials expire.
