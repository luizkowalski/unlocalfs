import Foundation
import Testing
import UnlocalFSCore

@Suite struct ConnectionTests {
    @Test func savedConnectionsSurviveReopenUpdateAndDelete() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("config.json")
        let store = ConnectionStore(url: url)
        var connection = fixture()
        try store.save(connection)
        connection.region = "auto"
        connection.folder = "clients/acme"
        connection.readOnly = true
        connection.connectsAutomatically = true
        try store.save(connection)
        let reopened = ConnectionStore(url: url)
        #expect(try reopened.all() == [connection])
        try reopened.delete(connection.id)
        #expect(try store.all().isEmpty)
    }

    @Test func connectionsSavedBeforeCacheLimitsUseTheDefaults() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("config.json")
        try Data("""
        {"connections":[{"bucket":"my-bucket","endpoint":"https://s3.example.com","id":"\(UUID())","name":"My files","provider":"Other","region":"us-east-1"}]}
        """.utf8).write(to: url)
        let connection = try #require(try ConnectionStore(url: url).all().first)
        #expect(connection.cacheLimit == 128_000_000)
        #expect(connection.minimumFreeSpace == 0)
        #expect(!connection.readOnly)
        #expect(!connection.connectsAutomatically)
    }

    @Test func driveNamesAreUniqueRegardlessOfCase() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConnectionStore(url: directory.appendingPathComponent("config.json"))
        try store.save(fixture())
        var duplicate = fixture()
        duplicate.name = "my files"
        #expect(throws: (any Error).self) { try store.save(duplicate) }
        #expect(try duplicate.validate(against: store.all()).map(\.field) == ["Name"])
    }

    @Test func missingCredentialsAreReportedPerField() {
        #expect(Credentials().validate().map(\.field) == ["Access key", "Secret key"])
    }

    static let invalidConnections: [(String, Connection)] =
        ["", ".", "..", "a/b", "a:b", "bad\nname", String(repeating: "a", count: 121), String(repeating: "é", count: 61)].map { ("Name", fixture(name: $0)) } +
        ["ftp://example.com", "https://example.com/bucket", "https://user:pass@example.com", "https://example.com?secret=value"].map { ("Endpoint", fixture(endpoint: $0)) } +
        ["", " ", ".", "..", "a/b", "a:b", "bad bucket", "bad\nbucket"].map { ("Bucket", fixture(bucket: $0)) } +
        ["/clients", "clients/", "clients//acme", "clients/../other", "./clients", "bad\nfolder"].map { ("Folder", fixture(folder: $0)) }

    @Test(arguments: invalidConnections)
    func invalidConnectionsAreNotSaved(field: String, connection: Connection) throws {
        let store = ConnectionStore(url: FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)/config.json"))
        #expect(Set(connection.validate().map(\.field)) == [field])
        #expect(throws: AppError.self) { try store.save(connection) }
        #expect(try store.all().isEmpty)
    }

    @Test func localS3EndpointsAreAccepted() throws {
        var connection = fixture()
        connection.endpoint = "http://127.0.0.1:19753"
        #expect(connection.validate().isEmpty)
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
