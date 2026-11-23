---
title: File versions and Recently Deleted
description: Open and restore earlier versions of a file, and get back deleted files, on S3 drives.
---

When versioning is on for an S3 bucket, the bucket keeps every saved version of a file. UnlocalFS lets you open those versions and restore them from Finder. A file that you delete on a drive does not go to the Trash: macOS deletes files on network drives at once. With versioning, the bucket still keeps the last saved version, so you can get the file back.

These items need the UnlocalFS Finder extension; see [Finder badges and menu](/using-drives/#finder-badges-and-menu).

## Earlier versions of a file

Right-click one file in a connected drive and choose **Show Versions…**. A window lists the versions, newest first, with the time of each save and the size. The first row is the current file.

- **Open** downloads the version and shows it in Quick Look. Double-click a row to do the same.
- **Restore** copies the version over the current file. The server copies it, so nothing downloads or uploads. The current file becomes an earlier version, so you lose nothing.
- **Restore as Copy** copies the version next to the current file, as "report copy.pdf".

## Recently Deleted

Right-click a folder, or the empty area of a folder window or of the drive, and choose **Show Recently Deleted…**. The window lists the files deleted in that folder, newest deletion first. **Restore** brings a file back with the content of its last save.

## Limits

- Versions are available for Amazon S3 and other S3-compatible storage, also when the drive is encrypted. They are not available for Google Cloud Storage, Google Drive, or SFTP drives.
- UnlocalFS does not turn versioning on. Turn it on in your storage provider's console. The items do not show when versioning is off for the bucket. When versioning is paused, the window shows the old versions, but new saves do not keep a version.
- Recently Deleted shows the files of one folder, not of its subfolders. You cannot reach files in a deleted folder, because Finder cannot show that folder.
- Wait until a file finishes uploading before you restore a version of it.
- Read-only drives show versions and **Open**, but not **Restore**.
- To list versions, the storage lists every version of every file in the folder. In a folder with many files and many saves, the window can take some seconds to fill. Closing the window stops the list.
- The drive's access key needs these permissions: `s3:ListBucketVersions`, `s3:GetObjectVersion`, and `s3:GetBucketVersioning`.
- Old versions use storage space. Your provider's lifecycle rules decide how long it keeps them.
