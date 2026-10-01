---
title: Encryption
description: Encrypt file contents and names before they reach your storage provider.
---

Turn on **Encrypt files** when you add a drive. UnlocalFS encrypts the content and the names of your files on your Mac before they upload, so your storage provider sees only random names and data. It uses [rclone crypt](https://rclone.org/crypt/) with the default settings, so you can also read the files with rclone and the same password.

- Keep the password in a safe place. If you lose it, nobody can read the files, including you.
- You cannot turn encryption on or off after you add a drive. To encrypt files you already have, add an encrypted drive with an empty folder and copy the files to it.
- If the top folder of the drive has names that the password cannot decrypt, the drive does not connect. This happens when the password is wrong or when the folder also has files that are not encrypted.
- Encrypted names are longer than the original names. Some providers limit the length of a file path.
