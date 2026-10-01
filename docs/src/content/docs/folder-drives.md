---
title: Folder drives
description: Connect one folder of a bucket as its own drive.
---

A drive can show one folder of a bucket instead of the whole bucket. Enter the folder path in **Folder**, for example `clients/acme`, and the drive opens straight into that folder. This is handy for a big shared bucket: make one drive per project, client, or type of file.

To add another folder from the same bucket, select a drive and choose **Duplicate**. The copy keeps the endpoint, bucket, and credentials, so you only change the name and the folder.

A folder limits what the drive shows. It does not limit access: the keys can still reach the whole bucket. To block writes, turn on **Read-only** in the drive settings. Apps then cannot create, change, or delete files on the drive. For full protection, use keys that only have read access. If two drives show the same files, a change in one shows in the other within 5 minutes or when you choose **Refresh Files**, and saving the same file from both at once can overwrite one of the edits.
