import Foundation
import Testing
import UnlocalFSCore

@Suite struct ConnectionTests {
    @Test func savedConnectionsSurviveReopenUpdateAndDelete() throws {
        let url = configURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = ConnectionStore(url: url)
        var connection = fixture()
        try store.save(connection)
        connection.region = "auto"
        connection.folder = "clients/acme"
        connection.readOnly = true
        connection.connectsAutomatically = true
        connection.encrypted = true
        try store.save(connection)
        let reopened = ConnectionStore(url: url)
        #expect(try reopened.all() == [connection])
        try reopened.delete(connection.id)
        #expect(try store.all().isEmpty)
    }

    @Test func connectionsSavedBeforeNewSettingsUseTheDefaults() throws {
        let url = configURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("""
        {"connections":[{"bucket":"my-bucket","endpoint":"https://s3.example.com","id":"\(UUID())","name":"My files","provider":"Other","region":"us-east-1"}]}
        """.utf8).write(to: url)
        let connection = try #require(try ConnectionStore(url: url).all().first)
        #expect(connection.cacheLimit == 128_000_000)
        #expect(connection.minimumFreeSpace == 0)
        #expect(!connection.readOnly)
        #expect(!connection.connectsAutomatically)
        #expect(!connection.encrypted)
        #expect(connection.bandwidthLimit == 0)
        #expect(connection.transfers == 4)
    }

    @Test func transferSettingsSurviveReopenAndUpdate() throws {
        let url = configURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("""
        {"connections":[{"bandwidthLimit":10000000,"bucket":"my-bucket",
        "endpoint":"https://s3.example.com","id":"\(UUID())","name":"My files",
        "provider":"Other","region":"auto","transfers":8}]}
        """.utf8).write(to: url)
        let store = ConnectionStore(url: url)
        let connection = try #require(try store.all().first)
        #expect(connection.bandwidthLimit == 10_000_000)
        #expect(connection.transfers == 8)
        try store.save(connection)
        #expect(try ConnectionStore(url: url).all() == [connection])
    }

    @Test func credentialsSavedBeforeEncryptionHaveNoPassword() throws {
        let credentials = try JSONDecoder().decode(Credentials.self, from: Data(#"{"accessKey":"a","secretKey":"b","sessionToken":""}"#.utf8))
        #expect(credentials == Credentials(accessKey: "a", secretKey: "b"))
    }

    @Test func driveNamesAreUniqueRegardlessOfCase() throws {
        let url = configURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = ConnectionStore(url: url)
        try store.save(fixture())
        var duplicate = fixture()
        duplicate.name = "my files"
        #expect(throws: AppError.self) { try store.save(duplicate) }
        #expect(try duplicate.validate(against: store.all()).map(\.field) == ["Name"])
        #expect(try store.all().count == 1)
    }

    @Test(arguments: [
        (false, Credentials(), ["Access key", "Secret key"]),
        (true, Credentials(accessKey: "a", secretKey: "b"), ["Encryption password"]),
        (true, Credentials(accessKey: "a", secretKey: "b", encryptionPassword: "pw"), [])
    ])
    func credentialsAreValidatedPerField(encrypted: Bool, credentials: Credentials, fields: [String]) {
        var connection = fixture()
        connection.encrypted = encrypted
        #expect(credentials.validate(for: connection).map(\.field) == fields)
    }

    static let validations: [(Set<String>, Connection)] = {
        let valid: [Connection] = [fixture(), fixture(endpoint: "http://127.0.0.1:19753"), fixture(folder: "clients/acme")]
        let names: [String] = ["", ".", "..", "a/b", "a:b", "bad\nname", String(repeating: "a", count: 121), String(repeating: "é", count: 61)]
        let endpoints: [String] = ["ftp://example.com", "https://example.com/bucket", "https://user:pass@example.com", "https://example.com?secret=value"]
        let buckets: [String] = ["", " ", ".", "..", "a/b", "a:b", "bad bucket", "bad\nbucket"]
        let folders: [String] = ["/clients", "clients/", "clients//acme", "clients/../other", "./clients", "bad\nfolder"]
        return valid.map { ([], $0) }
            + names.map { (["Name"], fixture(name: $0)) }
            + endpoints.map { (["Endpoint"], fixture(endpoint: $0)) }
            + buckets.map { (["Bucket"], fixture(bucket: $0)) }
            + folders.map { (["Folder"], fixture(folder: $0)) }
    }()

    @Test(arguments: validations)
    func validationReportsTheOffendingField(fields: Set<String>, connection: Connection) {
        #expect(Set(connection.validate().map(\.field)) == fields)
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

private func configURL() -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)/config.json")
}
