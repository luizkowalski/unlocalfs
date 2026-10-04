import Foundation

/// English text is the localization key; the en table is empty, so English
/// output is the key itself. Test suites pin `bundle` to the module's
/// `en.lproj` sub-bundle so string assertions pass on any host locale.
enum L10n {
    nonisolated(unsafe) static var bundle: Bundle = .module

    static func text(_ key: String.LocalizationValue) -> String {
        String(localized: key, table: "Localizable", bundle: bundle)
    }

    /// The module's `en.lproj` sub-bundle, used by tests to pin English output.
    static var englishBundle: Bundle {
        if let url = bundle.url(forResource: "en", withExtension: "lproj"), let english = Bundle(url: url) {
            return english
        }
        return bundle
    }

    // MARK: Connection validation

    static var nameEmpty: String { text("Name cannot be empty") }
    static var nameHasForbiddenCharacters: String { text("Enter a drive name without slashes, colons, or control characters.") }
    static var nameTooLong: String { text("Enter a shorter drive name. The limit is 120 bytes.") }
    static var endpointInvalidURL: String { text("Endpoint must be a valid URL") }
    static var endpointNotDirect: String { text("Enter an HTTP or HTTPS service endpoint without a bucket, credentials, or query.") }
    static var bucketEmpty: String { text("Bucket cannot be empty") }
    static var bucketHasPath: String { text("Enter the bucket name, without a path.") }
    static var folderPathInvalid: String { text("Enter a folder path like clients/acme, or leave it empty to use the whole bucket.") }
    static var nameAlreadyExists: String { text("A drive with that name already exists.") }
    static var passwordsDoNotMatch: String { text("The passwords do not match.") }
    static var accessKeyEmpty: String { text("Access key cannot be empty") }
    static var secretKeyEmpty: String { text("Secret key cannot be empty") }
    static var passwordEmpty: String { text("Password cannot be empty") }
    static var importServiceAccountKey: String { text("Import a service-account key") }
    static var encryptionPasswordEmpty: String { text("Encryption password cannot be empty") }

    // MARK: Duplicate-name suffix

    static func duplicateName(_ name: String) -> String {
        String(format: text("%1$@ copy"), name)
    }

    // MARK: Provider titles

    static var providerS3Compatible: String { text("S3 compatible") }
    static var providerAmazonS3: String { text("Amazon S3") }
    static var providerCloudflareR2: String { text("Cloudflare R2") }
    static var providerMinIO: String { text("MinIO") }
    static var providerWasabi: String { text("Wasabi") }
    static var providerDigitalOceanSpaces: String { text("DigitalOcean Spaces") }
    static var providerSFTP: String { text("SFTP") }
    static var providerGoogleCloudStorage: String { text("Google Cloud Storage") }

    // MARK: ConnectionField display labels

    static var fieldName: String { text("Name") }
    static var fieldEndpoint: String { text("Endpoint") }
    static var fieldBucket: String { text("Bucket") }
    static var fieldFolder: String { text("Folder") }
    static var fieldAccessKey: String { text("Access key") }
    static var fieldSecretKey: String { text("Secret key") }
    static var fieldServiceAccountKey: String { text("Service account key") }
    static var fieldHost: String { text("Host") }
    static var fieldPort: String { text("Port") }
    static var fieldUsername: String { text("Username") }
    static var fieldRemoteFolder: String { text("Remote folder") }
    static var fieldPassword: String { text("Password") }
    static var fieldPrivateKey: String { text("Private key") }
    static var fieldTrustedHosts: String { text("Trusted hosts") }
    static var fieldEncryptionPassword: String { text("Encryption password") }
    static var fieldConfirmPassword: String { text("Confirm password") }

    // MARK: SFTP authentication titles

    static var authenticationPassword: String { text("Password") }
    static var authenticationPrivateKey: String { text("Private key") }
    static var authenticationAgent: String { text("SSH agent") }

    // MARK: SFTPSettings validation

    static var hostMissing: String { text("Enter the server's host name or IP address.") }
    static var portOutOfRange: String { text("Enter a port from 1 to 65535.") }
    static var usernameMissing: String { text("Enter the username for this server.") }
    static var remotePathInvalid: String { text("Enter a folder path without control characters, or leave it empty for your home folder.") }
    static var keyFileNotFullPath: String { text("Enter the full path of your private key file, for example ~/.ssh/id_ed25519.") }
    static func trustedHostsNotFullPath(_ example: String) -> String {
        text("Enter the full path of your trusted-hosts file, for example \(example).")
    }

    // MARK: Use-case refusals

    static var duplicateChangesLockedAttributes: String { text("Duplicate this drive to change its protocol, folder, or encryption.") }
    static var encryptionPasswordImmutable: String { text("You cannot change the encryption password of a saved drive. Duplicate the drive to use a new password.") }
    static var disconnectBeforeDelete: String { text("Disconnect this drive before deleting it.") }
    static var fileNotInDrive: String { text("The file is not in an UnlocalFS drive.") }
    static func linksUnavailable(for providerTitle: String) -> String {
        text("Links aren't available for \(providerTitle) drives.")
    }
    static var linksUnavailableEncrypted: String { text("Links aren't available for encrypted drives because they would point to encrypted data.") }
    static var waitBeforeQuitting: String { text("Wait for the current operation to finish before quitting.") }
    static var disconnectBeforeQuitting: String {
        text("Disconnect your drives before quitting. This keeps pending uploads safe. Closing the window leaves UnlocalFS in the menu bar.")
    }
    static var onlyEncryptedExportConfig: String { text("Only encrypted drives can export an rclone config.") }

    // MARK: Service account keys

    static var notAServiceAccountKey: String { text("Not a service-account key. Choose the JSON key you downloaded from Google Cloud.") }

    // MARK: Mount lifecycle

    static var uploadsPending: String { text("Uploads are still in progress. Wait for them to finish before disconnecting.") }
    static var failedUploadsNeedRetry: String { text("Some files could not upload and need a retry. Keep UnlocalFS running until uploads finish.") }

    // MARK: Share-link expiry

    static var oneHour: String { text("1 hour") }
    static var oneDay: String { text("1 day") }
    static var sevenDays: String { text("7 days") }
}
