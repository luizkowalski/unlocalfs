import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

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
