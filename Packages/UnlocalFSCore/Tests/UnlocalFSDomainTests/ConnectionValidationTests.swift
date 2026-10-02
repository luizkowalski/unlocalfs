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
