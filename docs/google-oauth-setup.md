# Google sign-in setup

Google Cloud Storage drives sign in through `rclone authorize gcs` with the UnlocalFS Google client. This page records that client and the checks before a release.

## Record

| Item | Value |
| --- | --- |
| Google Cloud project | `<project-id>` |
| Owner | `<owner>` |
| Support contact | `<support email>` |
| OAuth client | Desktop app, `<client name>` |
| Consent screen | External, `<Testing or In production>` |
| Verification | `<category of devstorage.read_write and review status>` |

## Create the client

1. Create a Google Cloud project that UnlocalFS owns.
2. Enable the Cloud Storage JSON API.
3. Configure the OAuth consent screen as **External**. Add the app name, the support contact, the homepage, the privacy policy, and the verified domain.
4. Add the scope `https://www.googleapis.com/auth/devstorage.read_write`. UnlocalFS asks for no other scope.
5. Create an OAuth client of type **Desktop app**. rclone receives the reply at `http://127.0.0.1:53682/`. Desktop clients accept loopback addresses, so no redirect URI is registered.
6. Find the verification category of the scope in the console and finish the review before a public release. Until then, the consent screen shows a warning, only test users can sign in, and a grant made in **Testing** expires after 7 days.

## Give the client to the build

The build reads `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` and puts them in `Info.plist`. `Signing.xcconfig` sets both empty. A build with an empty client ID shows that Google sign-in is not available and never starts rclone for it, because rclone would use its own client.

- For a local build, add both lines to `Signing.local.xcconfig`, which Git ignores:

  ```
  GOOGLE_CLIENT_ID = <client-id>.apps.googleusercontent.com
  GOOGLE_CLIENT_SECRET = <client-secret>
  ```

- For a release, add the GitHub secrets `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET`. The release workflow writes them next to the signing settings and stops when the built `Info.plist` has no client ID.

Google does not treat a desktop client secret as confidential. It stays out of Git so that secret scanning does not flag it.

## Release checks

Use a disposable bucket and a test Google account. Record results without tokens. The app reads the real config and Keychain, so use a new connection and remove it afterwards.

- [ ] Sign in, test, save, and connect a new drive. Download, upload, and delete a file.
- [ ] Cancel a sign-in in the editor; the earlier account still saves and connects.
- [ ] An account without object permissions signs in but fails the connection test with a permission error.
- [ ] Keep a drive connected past the access token's expiry (about one hour); files still open and upload.
- [ ] Quit, wait past the expiry, open the app; the drive connects with no browser.
- [ ] Remove UnlocalFS in the account's third-party connections while an upload waits. The drive shows **Needs Google sign-in** and opens no browser by itself. **Sign In Again…** finishes the upload and the drive never disconnects.
- [ ] Two connections with separate sign-ins work at the same time.
- [ ] A second sign-in with the same account still returns a refresh token.
- [ ] Repeat the first check on macOS 15.
- [ ] Review Google's branding rules for the **Sign in with Google** button.
