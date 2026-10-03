---
title: Encryption
description: Encrypt file contents and names before they reach your storage provider.
---

Turn on **Encrypt files** when you add a drive. UnlocalFS encrypts the content and the names of your files on your Mac before they upload, so your storage provider sees only random names and data. It uses [rclone crypt](https://rclone.org/crypt/) with the default settings, so you can also read the files with rclone and the same password.

- Keep the password in a safe place. If you lose it, nobody can read the files, including you.
- You cannot turn encryption on or off after you add a drive. To encrypt files you already have, add an encrypted drive with an empty folder and copy the files to it.
- If the top folder of the drive has names that the password cannot decrypt, the drive does not connect. This happens when the password is wrong or when the folder also has files that are not encrypted.
- Encrypted names are longer than the original names. Some providers limit the length of a file path.

## Recover files without UnlocalFS

You can read an encrypted drive with [rclone](https://rclone.org/) alone. This works on any computer, also when UnlocalFS or this Mac is no longer available. Make the recovery file now and keep it in a safe place.

1. In UnlocalFS, right-click the drive and choose **Export rclone Config…**, or click **Export** in the drive toolbar.
2. Choose where to save the file. Select **Include keys and password** only if you want a file that works without anything else. Anyone with that file can read the drive, so store it like a password. rclone only obscures the password in the file. It does not encrypt it.
3. Install rclone on the computer you use for recovery. On a Mac, run `brew install rclone`, or follow the [rclone install guide](https://rclone.org/install/).
4. If you did not include the keys and password, add them now. The `read -s` commands keep them off the screen and out of your shell history:

   ```sh
   printf 'Access key: '; IFS= read -rs key; echo
   printf 'Secret key: '; IFS= read -rs secret; echo
   printf 'Encryption password: '; IFS= read -rs password; echo
   rclone config update unlocalfs-s3 "access_key_id=$key" "secret_access_key=$secret" --config "My files rclone.conf"
   rclone config update unlocalfs "password=$password" --obscure --config "My files rclone.conf"
   ```

5. List the files, then copy them to a folder on your computer:

   ```sh
   rclone lsf unlocalfs: --config "My files rclone.conf"
   rclone copy unlocalfs: ~/Recovered --progress --config "My files rclone.conf"
   ```

Replace `My files rclone.conf` with the path to your file. The `unlocalfs` remote is the drive with its files decrypted. The `unlocalfs-s3` remote is the storage with the encrypted data.

- If the drive used temporary credentials with a session token, the token in the file expires. Add new keys as in step 4. Then set the new session token with `rclone config update unlocalfs-s3 "session_token=$token" --config "My files rclone.conf"`, or clear it with `session_token=` if the new keys have none.
- Every exported file uses the same remote names. To put several drives in one rclone config, rename the sections first, for example to `photos` and `photos-s3`, and change the `remote` line of the crypt section to match.
