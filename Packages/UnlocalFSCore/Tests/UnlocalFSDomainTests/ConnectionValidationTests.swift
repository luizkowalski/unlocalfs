import Foundation
import Testing
import UnlocalFSDomain

@Suite struct ConnectionValidationTests {
    @Test(arguments: [
        (false, Credentials(), [ConnectionField.accessKey, .secretKey]),
        (true, Credentials(accessKey: "a", secretKey: "b"), [.encryptionPassword]),
        (true, Credentials(accessKey: "a", secretKey: "b", encryptionPassword: "pw"), [ConnectionField]())
    ])
    func credentialsAreValidatedPerField(encrypted: Bool, credentials: Credentials, fields: [ConnectionField]) {
        var connection = fixture()
        connection.encrypted = encrypted
        #expect(credentials.validate(for: connection).issues.map(\.field) == fields)
    }

    static let validations: [(Set<ConnectionField>, Connection)] = {
        let valid: [Connection] = [fixture(), fixture(endpoint: "http://127.0.0.1:19753"), fixture(folder: "clients/acme")]
        let names: [String] = ["", ".", "..", "a/b", "a:b", "bad\nname", String(repeating: "a", count: 121), String(repeating: "é", count: 61)]
        let endpoints: [String] = ["ftp://example.com", "https://example.com/bucket", "https://user:pass@example.com", "https://example.com?secret=value"]
        let buckets: [String] = ["", " ", ".", "..", "a/b", "a:b", "bad bucket", "bad\nbucket"]
        let folders: [String] = ["/clients", "clients/", "clients//acme", "clients/../other", "./clients", "bad\nfolder"]
        return valid.map { ([], $0) }
            + names.map { ([.name], fixture(name: $0)) }
            + endpoints.map { ([.endpoint], fixture(endpoint: $0)) }
            + buckets.map { ([.bucket], fixture(bucket: $0)) }
            + folders.map { ([.folder], fixture(folder: $0)) }
    }()

    @Test(arguments: validations)
    func validationReportsTheOffendingField(fields: Set<ConnectionField>, connection: Connection) {
        #expect(Set(connection.validate().issues.map(\.field)) == fields)
    }

    @Test(arguments: [
        (ConnectionField.name, "", ["Name cannot be empty"]),
        (.name, " ", ["Name cannot be empty"]),
        (.name, " \t\n", ["Name cannot be empty", "Enter a drive name without slashes, colons, or control characters."]),
        (.name, ".", ["Enter a drive name without slashes, colons, or control characters."]),
        (.name, "..", ["Enter a drive name without slashes, colons, or control characters."]),
        (.name, "a/b", ["Enter a drive name without slashes, colons, or control characters."]),
        (.name, "a:b", ["Enter a drive name without slashes, colons, or control characters."]),
        (.name, "bad\nname", ["Enter a drive name without slashes, colons, or control characters."]),
        (.name, String(repeating: "a", count: 121), ["Enter a shorter drive name. The limit is 120 bytes."]),
        (.name, String(repeating: "é", count: 61), ["Enter a shorter drive name. The limit is 120 bytes."]),
        (.endpoint, "", ["Endpoint must be a valid URL", "Enter an HTTP or HTTPS service endpoint without a bucket, credentials, or query."]),
        (.endpoint, "example.com", ["Endpoint must be a valid URL", "Enter an HTTP or HTTPS service endpoint without a bucket, credentials, or query."]),
        (.endpoint, "https:example.com", ["Endpoint must be a valid URL", "Enter an HTTP or HTTPS service endpoint without a bucket, credentials, or query."]),
        (.endpoint, "https://[", ["Endpoint must be a valid URL", "Enter an HTTP or HTTPS service endpoint without a bucket, credentials, or query."]),
        (.endpoint, "https://", ["Endpoint must be a valid URL", "Enter an HTTP or HTTPS service endpoint without a bucket, credentials, or query."]),
        (.endpoint, "ftp://example.com", ["Enter an HTTP or HTTPS service endpoint without a bucket, credentials, or query."]),
        (.endpoint, "https://example.com/bucket", ["Enter an HTTP or HTTPS service endpoint without a bucket, credentials, or query."]),
        (.endpoint, "https://user:pass@example.com", ["Enter an HTTP or HTTPS service endpoint without a bucket, credentials, or query."]),
        (.endpoint, "https://example.com?secret=value", ["Enter an HTTP or HTTPS service endpoint without a bucket, credentials, or query."]),
        (.endpoint, "https://example.com#fragment", ["Enter an HTTP or HTTPS service endpoint without a bucket, credentials, or query."]),
        (.bucket, "", ["Bucket cannot be empty"]),
        (.bucket, " ", ["Bucket cannot be empty", "Enter the bucket name, without a path."]),
        (.bucket, ".", ["Enter the bucket name, without a path."]),
        (.bucket, "..", ["Enter the bucket name, without a path."]),
        (.bucket, "a/b", ["Enter the bucket name, without a path."]),
        (.bucket, "a:b", ["Enter the bucket name, without a path."]),
        (.bucket, "bad bucket", ["Enter the bucket name, without a path."]),
        (.bucket, "bad\nbucket", ["Enter the bucket name, without a path."]),
        (.folder, "/clients", ["Enter a folder path like clients/acme, or leave it empty to use the whole bucket."]),
        (.folder, "clients/", ["Enter a folder path like clients/acme, or leave it empty to use the whole bucket."]),
        (.folder, "clients//acme", ["Enter a folder path like clients/acme, or leave it empty to use the whole bucket."]),
        (.folder, "clients/../other", ["Enter a folder path like clients/acme, or leave it empty to use the whole bucket."]),
        (.folder, "./clients", ["Enter a folder path like clients/acme, or leave it empty to use the whole bucket."]),
        (.folder, "bad\nfolder", ["Enter a folder path like clients/acme, or leave it empty to use the whole bucket."])
    ])
    func invalidInputKeepsEveryMessageInOrder(field: ConnectionField, value: String, messages: [String]) {
        var connection = fixture()
        switch field {
        case .name: connection.name = value
        case .endpoint: connection.endpoint = value
        case .bucket: connection.bucket = value
        case .folder: connection.folder = value
        default: Issue.record("Unexpected connection field")
        }
        let errors = connection.validate()
        #expect(errors.issues.map(\.field) == Array(repeating: field, count: messages.count))
        #expect(errors.issues.map(\.message) == messages)
    }

    @Test(arguments: [String(repeating: "a", count: 120), String(repeating: "é", count: 60), " My files "])
    func allowedNameBytesAndSpacesStayUnchanged(name: String) {
        let connection = fixture(name: name)
        #expect(connection.validate().isValid)
        #expect(connection.name == name)
    }

    @Test func endpointSlashAndUnicodeFolderAreAllowed() {
        #expect(fixture(endpoint: "https://s3.example.com/", folder: " clients/café ").validate().isValid)
    }

    @Test func blankCredentialsReportAllMessagesInOrder() {
        var connection = fixture()
        connection.encrypted = true
        let credentials = Credentials(accessKey: " \t", secretKey: "\n", encryptionPassword: " ")
        let errors = credentials.validate(for: connection)
        #expect(errors.issues.map(\.field) == [.accessKey, .secretKey, .encryptionPassword])
        #expect(errors.issues.map(\.message) == ["Access key cannot be empty", "Secret key cannot be empty", "Encryption password cannot be empty"])
    }

    @Test func allowedCredentialSpacesStayUnchanged() {
        var connection = fixture()
        connection.encrypted = true
        let credentials = Credentials(accessKey: " key ", secretKey: " secret ", encryptionPassword: " password ")
        #expect(connection.validate(credentials: credentials, confirmation: " password ", against: []).isValid)
        #expect(credentials.encryptionPassword == " password ")
        #expect(credentials.accessKey == " key ")
        #expect(credentials.secretKey == " secret ")
        #expect(connection.validate(credentials: credentials, confirmation: "password", against: []).issues.map(\.field) == [.confirmation])
    }

    @Test func completeSaveErrorKeepsBothBucketMessages() {
        let errors = fixture(bucket: " ").validate()
        #expect { try errors.requireValid() } throws: { error in
            (error as? AppError)?.errorDescription == "Bucket cannot be empty\nEnter the bucket name, without a path."
        }
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
