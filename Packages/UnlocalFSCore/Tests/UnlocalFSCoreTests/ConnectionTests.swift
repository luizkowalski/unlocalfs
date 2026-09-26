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
    }

    @Test func driveNamesAreUniqueRegardlessOfCase() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConnectionStore(url: directory.appendingPathComponent("config.json"))
        try store.save(fixture())
        var duplicate = fixture()
        duplicate.name = "my files"
        #expect(throws: (any Error).self) { try store.save(duplicate) }
    }

    @Test(arguments: ["", ".", "..", "a/b", "a:b", "bad\nname"])
    func invalidMountNamesAreRejected(name: String) {
        var connection = fixture()
        connection.name = name
        #expect(throws: (any Error).self) { try connection.validate() }
    }

    @Test(arguments: ["ftp://example.com", "https://example.com/bucket", "https://user:pass@example.com", "https://example.com?secret=value"])
    func invalidS3EndpointsAreRejected(endpoint: String) {
        var connection = fixture()
        connection.endpoint = endpoint
        #expect(throws: (any Error).self) { try connection.validate() }
    }

    @Test func localS3EndpointsAreAccepted() throws {
        var connection = fixture()
        connection.endpoint = "http://127.0.0.1:19753"
        try connection.validate()
    }
}

func fixture() -> Connection {
    var connection = Connection()
    connection.name = "My files"
    connection.endpoint = "https://s3.example.com"
    connection.bucket = "my-bucket"
    return connection
}
