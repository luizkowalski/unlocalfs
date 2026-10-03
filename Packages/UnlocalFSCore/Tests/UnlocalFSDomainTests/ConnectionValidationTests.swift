import Foundation
import Testing
import UnlocalFSDomain

private let emptyName = "Name cannot be empty"
private let badName = "Enter a drive name without slashes, colons, or control characters."
private let longName = "Enter a shorter drive name. The limit is 120 bytes."
private let invalidURL = "Endpoint must be a valid URL"
private let badEndpoint = "Enter an HTTP or HTTPS service endpoint without a bucket, credentials, or query."
private let emptyBucket = "Bucket cannot be empty"
private let badBucket = "Enter the bucket name, without a path."
private let badFolder = "Enter a folder path like clients/acme, or leave it empty to use the whole bucket."

@Suite struct ConnectionValidationTests {
    @Test(arguments: [
        (false, Credentials(), [ConnectionField.accessKey, .secretKey]),
        (true, Credentials(accessKey: " \t", secretKey: "\n", encryptionPassword: " "), [.accessKey, .secretKey, .encryptionPassword]),
        (true, Credentials(accessKey: "a", secretKey: "b"), [.encryptionPassword]),
        (true, Credentials(accessKey: "a", secretKey: "b", encryptionPassword: "pw"), [ConnectionField]())
    ])
    func credentialsAreValidatedPerField(encrypted: Bool, credentials: Credentials, fields: [ConnectionField]) {
        var connection = fixture()
        connection.encrypted = encrypted
        #expect(credentials.validate(for: connection).issues.map(\.field) == fields)
    }

    @Test(arguments: [
        fixture(), fixture(endpoint: "http://127.0.0.1:19753"), fixture(folder: "clients/acme"),
        fixture(endpoint: "https://s3.example.com/", folder: " clients/café "),
        fixture(name: String(repeating: "a", count: 120)), fixture(name: String(repeating: "é", count: 60)), fixture(name: " My files ")
    ])
    func validConnectionHasNoIssues(connection: Connection) {
        #expect(connection.validate().isValid)
    }

    @Test(arguments: [
        (ConnectionField.name, fixture(name: ""), [emptyName]),
        (.name, fixture(name: " "), [emptyName]),
        (.name, fixture(name: " \t\n"), [emptyName, badName]),
        (.name, fixture(name: "."), [badName]),
        (.name, fixture(name: ".."), [badName]),
        (.name, fixture(name: "a/b"), [badName]),
        (.name, fixture(name: "a:b"), [badName]),
        (.name, fixture(name: "bad\nname"), [badName]),
        (.name, fixture(name: String(repeating: "a", count: 121)), [longName]),
        (.name, fixture(name: String(repeating: "é", count: 61)), [longName]),
        (.endpoint, fixture(endpoint: ""), [invalidURL, badEndpoint]),
        (.endpoint, fixture(endpoint: "example.com"), [invalidURL, badEndpoint]),
        (.endpoint, fixture(endpoint: "https:example.com"), [invalidURL, badEndpoint]),
        (.endpoint, fixture(endpoint: "https://["), [invalidURL, badEndpoint]),
        (.endpoint, fixture(endpoint: "https://"), [invalidURL, badEndpoint]),
        (.endpoint, fixture(endpoint: "ftp://example.com"), [badEndpoint]),
        (.endpoint, fixture(endpoint: "https://example.com/bucket"), [badEndpoint]),
        (.endpoint, fixture(endpoint: "https://user:pass@example.com"), [badEndpoint]),
        (.endpoint, fixture(endpoint: "https://example.com?secret=value"), [badEndpoint]),
        (.endpoint, fixture(endpoint: "https://example.com#fragment"), [badEndpoint]),
        (.bucket, fixture(bucket: ""), [emptyBucket]),
        (.bucket, fixture(bucket: " "), [emptyBucket, badBucket]),
        (.bucket, fixture(bucket: "."), [badBucket]),
        (.bucket, fixture(bucket: ".."), [badBucket]),
        (.bucket, fixture(bucket: "a/b"), [badBucket]),
        (.bucket, fixture(bucket: "a:b"), [badBucket]),
        (.bucket, fixture(bucket: "bad bucket"), [badBucket]),
        (.bucket, fixture(bucket: "bad\nbucket"), [badBucket]),
        (.folder, fixture(folder: "/clients"), [badFolder]),
        (.folder, fixture(folder: "clients/"), [badFolder]),
        (.folder, fixture(folder: "clients//acme"), [badFolder]),
        (.folder, fixture(folder: "clients/../other"), [badFolder]),
        (.folder, fixture(folder: "./clients"), [badFolder]),
        (.folder, fixture(folder: "bad\nfolder"), [badFolder])
    ])
    func invalidInputKeepsEveryMessageInOrder(field: ConnectionField, connection: Connection, messages: [String]) {
        let issues = connection.validate().issues
        #expect(issues.map(\.field) == Array(repeating: field, count: messages.count))
        #expect(issues.map(\.message) == messages)
    }

    @Test func paddedCredentialsAreValidAndConfirmationMatchesExactly() {
        var connection = fixture()
        connection.encrypted = true
        let credentials = Credentials(accessKey: " key ", secretKey: " secret ", encryptionPassword: " password ")
        #expect(connection.validate(credentials: credentials, confirmation: " password ", against: []).isValid)
        #expect(connection.validate(credentials: credentials, confirmation: "password", against: []).issues.map(\.field) == [.confirmation])
    }
}

func fixture(name: String = "My files", endpoint: String = "https://s3.example.com", bucket: String = "my-bucket", folder: String = "") -> Connection {
    var connection = Connection()
    connection.name = name
    connection.endpoint = endpoint
    connection.bucket = bucket
    connection.folder = folder
    return connection
}

@Suite struct SFTPValidationTests {
    @Test(arguments: ["", "uploads", "/srv/files", "~/files", " spaced path /"])
    func validSFTPConnectionHasNoIssues(remotePath: String) {
        var connection = sftpFixture()
        connection.sftp.remotePath = remotePath
        #expect(connection.validate(credentials: Credentials(password: "secret"), confirmation: "", against: []).isValid)
    }

    @Test func sftpDoesNotRequireStorageCredentials() {
        let connection = sftpFixture()
        let issues = connection.validate(credentials: Credentials(password: "secret"), confirmation: "", against: []).issues
        #expect(issues.isEmpty)
    }

    @Test(arguments: [
        (ConnectionField.host, sftpSettings { $0.host = " " }),
        (.host, sftpSettings { $0.host = "bad host" }),
        (.port, sftpSettings { $0.port = 0 }),
        (.port, sftpSettings { $0.port = 65_536 }),
        (.username, sftpSettings { $0.username = "" }),
        (.remotePath, sftpSettings { $0.remotePath = "bad\nfolder" }),
        (.keyFile, sftpSettings { $0.authentication = .privateKey; $0.keyFile = "" }),
        (.keyFile, sftpSettings { $0.authentication = .privateKey; $0.keyFile = "id_ed25519" }),
        (.trustedHosts, sftpSettings { $0.trustedHostsFile = "" }),
        (.trustedHosts, sftpSettings { $0.trustedHostsFile = "none" }),
        (.trustedHosts, sftpSettings { $0.trustedHostsFile = "known_hosts" })
    ])
    func invalidSFTPInputNamesTheField(field: ConnectionField, settings: SFTPSettings) {
        var connection = sftpFixture()
        connection.sftp = settings
        #expect(connection.validate().issues.map(\.field) == [field])
    }

    @Test func passwordModeRequiresAPasswordButOtherModesDoNot() {
        var connection = sftpFixture()
        #expect(Credentials().validate(for: connection).issues.map(\.field) == [.password])
        connection.sftp.authentication = .privateKey
        connection.sftp.keyFile = "/Users/me/.ssh/id_ed25519"
        #expect(Credentials().validate(for: connection).isValid)
        connection.sftp.authentication = .agent
        #expect(Credentials().validate(for: connection).isValid)
    }

    @Test func inactiveAuthenticationInputsAreIgnored() {
        var connection = sftpFixture()
        connection.sftp.authentication = .agent
        connection.sftp.keyFile = "not a path"
        #expect(connection.validate(credentials: Credentials(), confirmation: "", against: []).isValid)
    }

    @Test func switchingBackToS3RestoresS3Validation() {
        var connection = sftpFixture()
        connection.provider = .other
        #expect(connection.validate(credentials: Credentials(), confirmation: "", against: []).issues.map(\.field) == [.endpoint, .endpoint, .bucket, .accessKey, .secretKey])
    }

    @Test func prunedCredentialsKeepOnlyTheActiveMode() {
        var connection = sftpFixture()
        var credentials = Credentials(
            accessKey: "key", secretKey: "secret", sessionToken: "token", encryptionPassword: "crypt", password: "ssh", keyPassphrase: "phrase")
        credentials.obscuredPassword = "obscured-ssh"
        credentials.obscuredKeyPassphrase = "obscured-phrase"
        credentials.obscuredEncryptionPassword = "obscured-crypt"

        var pruned = credentials.pruned(for: connection)
        #expect(pruned == Credentials(encryptionPassword: "crypt", password: "ssh").obscured(password: "obscured-ssh"))

        connection.sftp.authentication = .privateKey
        pruned = credentials.pruned(for: connection)
        #expect(pruned == Credentials(encryptionPassword: "crypt", keyPassphrase: "phrase").obscured(passphrase: "obscured-phrase"))

        connection.sftp.authentication = .agent
        pruned = credentials.pruned(for: connection)
        #expect(pruned == Credentials(encryptionPassword: "crypt").obscured())

        connection.provider = .other
        pruned = credentials.pruned(for: connection)
        #expect(pruned == Credentials(accessKey: "key", secretKey: "secret", sessionToken: "token", encryptionPassword: "crypt").obscured())
    }
}

private func sftpSettings(_ change: (inout SFTPSettings) -> Void) -> SFTPSettings {
    var settings = sftpFixture().sftp
    change(&settings)
    return settings
}

private extension Credentials {
    func obscured(password: String = "", passphrase: String = "") -> Credentials {
        var credentials = self
        credentials.obscuredPassword = password
        credentials.obscuredKeyPassphrase = passphrase
        credentials.obscuredEncryptionPassword = "obscured-crypt"
        return credentials
    }
}

func sftpFixture(name: String = "Server") -> Connection {
    var connection = Connection()
    connection.name = name
    connection.provider = .sftp
    connection.sftp.host = "files.example.com"
    connection.sftp.username = "me"
    return connection
}
