---
title: Sharing links
description: Copy temporary download links from Finder.
---

Right-click a file in a connected drive, choose **Services**, then **Copy Share Link (1 Hour)**, **Copy Share Link (1 Day)**, or **Copy Share Link (7 Days)**. UnlocalFS copies a presigned link to the clipboard and sends a notification. Anyone with the link can download the file until the link expires. They do not need your keys. If you select more than one file, you get one link on each line.

- Links are not available for SFTP drives. UnlocalFS tells you so before it reads any credentials.
- Links are not available for encrypted drives, because the link would point to encrypted data. The Services entries still show for these drives, but UnlocalFS tells you why it did not copy a link.
- Wait until a file finishes uploading before you copy its link. If the drive shows **Needs reconnect**, reconnect it first.
- You cannot cancel a link before it expires. To stop all links early, replace the access key.
- A link includes your access key ID, but never your secret key. If you use temporary credentials, the link stops working when the credentials expire.
- If the entries do not show, open UnlocalFS once. You can turn them on and add keyboard shortcuts in **System Settings → Keyboard → Keyboard Shortcuts → Services → Files and Folders**.
