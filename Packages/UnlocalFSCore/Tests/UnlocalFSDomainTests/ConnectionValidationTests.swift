import Foundation
import Testing
@testable import UnlocalFSDomain
import UnlocalFSTestSupport

private let emptyName = String(localized: .nameEmpty)
private let badName = String(localized: .nameHasForbiddenCharacters)
private let longName = String(localized: .nameTooLong)
private let invalidURL = String(localized: .endpointInvalidURL)
private let badEndpoint = String(localized: .endpointNotDirect)
private let emptyBucket = String(localized: .bucketEmpty)
private let badBucket = String(localized: .bucketHasPath)
private let badFolder = String(localized: .folderPathInvalid)

@Suite struct ConnectionValidationTests {
    @Test(arguments: [
        (false, Credentials(), [ConnectionField.accessKey, .secretKey]),
        (true, Credentials(accessKey: " \t", secretKey: "\n", encryptionPassword: " "), [.accessKey, .secretKey, .encryptionPassword]),
        (true, Credentials(accessKey: "a", secretKey: "b"), [.encryptionPassword]),
        (true, Credentials(accessKey: "a", secretKey: "b", encryptionPassword: "pw"), [ConnectionField]()),
    ])
    func credentialsAreValidatedPerField(encrypted: Bool, credentials: Credentials, fields: [ConnectionField]) {
        let connection = Connection.s3 { $0.encrypted = encrypted }
        #expect(credentials.validate(for: connection).issues.map(\.field) == fields)
    }

    @Test(arguments: [
        Connection.s3(), Connection.s3(endpoint: "http://127.0.0.1:19753"), Connection.s3(folder: "clients/acme"),
        Connection.s3(endpoint: "https://s3.example.com/", folder: " clients/café "),
        Connection.s3(name: String(repeating: "a", count: 120)), Connection.s3(name: String(repeating: "é", count: 60)), Connection.s3(name: " My files "),
    ])
    func validConnectionHasNoIssues(connection: Connection) {
        #expect(connection.validate().isValid)
    }

    @Test(arguments: [
        (ConnectionField.name, Connection.s3(name: ""), [emptyName]),
        (.name, Connection.s3(name: " "), [emptyName]),
        (.name, Connection.s3(name: " \t\n"), [emptyName, badName]),
        (.name, Connection.s3(name: "."), [badName]),
        (.name, Connection.s3(name: ".."), [badName]),
        (.name, Connection.s3(name: "a/b"), [badName]),
        (.name, Connection.s3(name: "a:b"), [badName]),
        (.name, Connection.s3(name: "bad\nname"), [badName]),
        (.name, Connection.s3(name: String(repeating: "a", count: 121)), [longName]),
        (.name, Connection.s3(name: String(repeating: "é", count: 61)), [longName]),
        (.endpoint, Connection.s3(endpoint: ""), [invalidURL, badEndpoint]),
        (.endpoint, Connection.s3(endpoint: "example.com"), [invalidURL, badEndpoint]),
        (.endpoint, Connection.s3(endpoint: "https:example.com"), [invalidURL, badEndpoint]),
        (.endpoint, Connection.s3(endpoint: "https://["), [invalidURL, badEndpoint]),
        (.endpoint, Connection.s3(endpoint: "https://"), [invalidURL, badEndpoint]),
        (.endpoint, Connection.s3(endpoint: "ftp://example.com"), [badEndpoint]),
        (.endpoint, Connection.s3(endpoint: "https://example.com/bucket"), [badEndpoint]),
        (.endpoint, Connection.s3(endpoint: "https://user:pass@example.com"), [badEndpoint]),
        (.endpoint, Connection.s3(endpoint: "https://example.com?secret=value"), [badEndpoint]),
        (.endpoint, Connection.s3(endpoint: "https://example.com#fragment"), [badEndpoint]),
        (.bucket, Connection.s3(bucket: ""), [emptyBucket]),
        (.bucket, Connection.s3(bucket: " "), [emptyBucket, badBucket]),
        (.bucket, Connection.s3(bucket: "."), [badBucket]),
        (.bucket, Connection.s3(bucket: ".."), [badBucket]),
        (.bucket, Connection.s3(bucket: "a/b"), [badBucket]),
        (.bucket, Connection.s3(bucket: "a:b"), [badBucket]),
        (.bucket, Connection.s3(bucket: "bad bucket"), [badBucket]),
        (.bucket, Connection.s3(bucket: "bad\nbucket"), [badBucket]),
        (.folder, Connection.s3(folder: "/clients"), [badFolder]),
        (.folder, Connection.s3(folder: "clients/"), [badFolder]),
        (.folder, Connection.s3(folder: "clients//acme"), [badFolder]),
        (.folder, Connection.s3(folder: "clients/../other"), [badFolder]),
        (.folder, Connection.s3(folder: "./clients"), [badFolder]),
        (.folder, Connection.s3(folder: "bad\nfolder"), [badFolder]),
    ])
    func invalidInputKeepsEveryMessageInOrder(field: ConnectionField, connection: Connection, messages: [String]) {
        let issues = connection.validate().issues
        #expect(issues.map(\.field) == Array(repeating: field, count: messages.count))
        #expect(issues.map(\.message) == messages)
    }

    @Test func paddedCredentialsAreValidAndConfirmationMatchesExactly() {
        let connection = Connection.s3 { $0.encrypted = true }
        let credentials = Credentials(accessKey: " key ", secretKey: " secret ", encryptionPassword: " password ")
        #expect(connection.validate(credentials: credentials, confirmation: " password ", against: []).isValid)
        #expect(connection.validate(credentials: credentials, confirmation: "password", against: []).issues.map(\.field) == [.confirmation])
    }
}

@Suite struct SFTPValidationTests {
    @Test(arguments: ["", "uploads", "/srv/files", "~/files", " spaced path /"])
    func validSFTPConnectionHasNoIssues(remotePath: String) {
        let connection = Connection.sftp { $0.sftp.remotePath = remotePath }
        #expect(connection.validate(credentials: Credentials(password: "secret"), confirmation: "", against: []).isValid)
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
    ])
    func invalidSFTPInputNamesTheField(field: ConnectionField, settings: SFTPSettings) {
        let connection = Connection.sftp { $0.sftp = settings }
        #expect(connection.validate().issues.map(\.field) == [field])
    }

    @Test func passwordModeRequiresAPasswordButOtherModesDoNot() {
        var connection = Connection.sftp()
        #expect(Credentials().validate(for: connection).issues.map(\.field) == [.password])
        connection.sftp.authentication = .privateKey
        connection.sftp.keyFile = "/Users/me/.ssh/id_ed25519"
        #expect(Credentials().validate(for: connection).isValid)
        connection.sftp.authentication = .agent
        #expect(Credentials().validate(for: connection).isValid)
    }

    @Test func inactiveAuthenticationInputsAreIgnored() {
        let connection = Connection.sftp {
            $0.sftp.authentication = .agent
            $0.sftp.keyFile = "not a path"
        }
        #expect(connection.validate(credentials: Credentials(), confirmation: "", against: []).isValid)
    }

    @Test func switchingBackToS3RestoresS3Validation() {
        let connection = Connection.sftp { $0.provider = .other }
        #expect(connection.validate(credentials: Credentials(), confirmation: "", against: []).issues.map(\.field) == [.endpoint, .endpoint, .bucket, .accessKey, .secretKey])
    }
}

@Suite struct AWSValidationTests {
    @Test(arguments: [
        "", "1234abcd-12ab-34cd-56ef-1234567890ab", "mrk-1234abcd12ab34cd56ef1234567890ab", "alias/compliance",
        "arn:aws:kms:us-east-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab",
        "arn:aws-us-gov:kms:us-gov-west-1:111122223333:alias/compliance",
    ])
    func kmsKeyAcceptsKeyIDsAliasesAndARNs(key: String) {
        #expect(awsFixture(kmsKeyID: key).validate().isValid)
    }

    @Test(arguments: ["my key", "compliance", "alias/compliance\n"])
    func malformedKMSKeyNamesTheField(key: String) {
        #expect(awsFixture(kmsKeyID: key).validate().issues.map(\.field) == [.kmsKey])
    }

    @Test func kmsKeyIsIgnoredWithoutKMSOrOutsideAWS() {
        var connection = awsFixture(kmsKeyID: "my key")
        connection.aws.serverSideEncryption = .s3Managed
        #expect(connection.validate().isValid)
        connection.aws.serverSideEncryption = .kms
        connection.provider = .minio
        #expect(connection.validate().isValid)
    }
}

@Suite struct GCSValidationTests {
    @Test(arguments: [
        "", "not json", "[]",
        #"{"type":"authorized_user","client_email":"a@b.c","private_key":"k"}"#,
        #"{"type":"service_account","private_key":"k"}"#,
        #"{"type":"service_account","client_email":"a@b.c"}"#,
        #"{"type":"service_account","client_email":"","private_key":"k"}"#,
    ])
    func filesThatAreNotServiceAccountKeysAreRejected(json: String) {
        #expect(throws: AppError.self) { try ServiceAccountKey(importing: Data(json.utf8)) }
    }

    @Test func validKeyShowsItsEmailAndCompactsToOneLineKeepingEveryField() throws {
        let key = try ServiceAccountKey(importing: Data(serviceAccountJSON.utf8))
        #expect(key.email == "drive@demo.iam.gserviceaccount.com")
        #expect(!key.json.contains("\n"))
        let fields = try #require(try JSONSerialization.jsonObject(with: Data(key.json.utf8)) as? [String: String])
        #expect(fields["project_id"] == "demo" && fields["token_uri"] == "https://oauth2.googleapis.com/token")
        #expect(fields["private_key"] == "-----BEGIN PRIVATE KEY-----\nabc\n-----END PRIVATE KEY-----\n")
        #expect(ServiceAccountKey(json: key.json)?.email == key.email)
    }

    @Test func connectionNeedsABucketAndAKeyButNoEndpoint() throws {
        var connection = Connection.gcs()
        #expect(connection.validate().isValid)
        #expect(Credentials().validate(for: connection).issues.map(\.field) == [.serviceAccountKey])
        let key = try ServiceAccountKey(importing: Data(serviceAccountJSON.utf8))
        #expect(Credentials(serviceAccountKey: key.json).validate(for: connection).isValid)
        connection.bucket = "a/b"
        #expect(connection.validate().issues.map(\.field) == [.bucket])
    }
}

private func sftpSettings(_ change: (inout SFTPSettings) -> Void) -> SFTPSettings {
    var settings = Connection.sftp().sftp
    change(&settings)
    return settings
}

private func awsFixture(kmsKeyID: String) -> Connection {
    Connection.s3 {
        $0.provider = .aws
        $0.aws.serverSideEncryption = .kms
        $0.aws.kmsKeyID = kmsKeyID
    }
}

let serviceAccountJSON = """
{
  "type": "service_account",
  "project_id": "demo",
  "private_key": "-----BEGIN PRIVATE KEY-----\\nabc\\n-----END PRIVATE KEY-----\\n",
  "client_email": "drive@demo.iam.gserviceaccount.com",
  "token_uri": "https://oauth2.googleapis.com/token"
}
"""
