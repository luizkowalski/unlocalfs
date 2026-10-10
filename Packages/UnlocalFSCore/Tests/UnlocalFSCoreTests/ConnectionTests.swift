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
        connection.provider = .aws
        connection.aws.storageClass = .intelligentTiering
        connection.aws.serverSideEncryption = .kms
        connection.aws.kmsKeyID = "arn:aws:kms:us-east-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
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
        #expect(connection.cacheLimit == 1_000_000_000)
        #expect(connection.minimumFreeSpace == 0)
        #expect(!connection.readOnly)
        #expect(!connection.connectsAutomatically)
        #expect(!connection.encrypted)
        #expect(connection.bandwidthLimit == 0)
        #expect(connection.transfers == 4)
        #expect(connection.aws == AWSSettings())
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

    @Test func currentReleaseConnectionAndCredentialsStayS3() throws {
        let url = configURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let id = UUID()
        try Data("""
        {"connections":[{"bandwidthLimit":0,"bucket":"my-bucket","cacheLimit":512000000,"connectsAutomatically":true,"encrypted":true,
        "endpoint":"https://s3.example.com","folder":"clients","id":"\(id)","minimumFreeSpace":0,"name":"My files",
        "provider":"Cloudflare","readOnly":true,"region":"auto","transfers":8}]}
        """.utf8).write(to: url)
        let store = ConnectionStore(url: url)
        let connection = try #require(try store.all().first)
        #expect(connection.provider == .cloudflare)
        #expect(connection.endpoint == "https://s3.example.com" && connection.bucket == "my-bucket" && connection.folder == "clients")
        #expect(connection.encrypted && connection.readOnly && connection.connectsAutomatically)
        #expect(connection.sftp == SFTPSettings())
        try store.save(connection)
        #expect(try store.all() == [connection])
        let credentials = try JSONDecoder().decode(Credentials.self, from: Data(
            #"{"accessKey":"a","secretKey":"b","sessionToken":"c","encryptionPassword":"d","obscuredEncryptionPassword":"e"}"#.utf8))
        #expect(credentials == { var expected = Credentials(accessKey: "a", secretKey: "b", sessionToken: "c", encryptionPassword: "d")
            expected.obscuredEncryptionPassword = "e"
            return expected }())
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

func sftpFixture(name: String = "Server") -> Connection {
    var connection = Connection()
    connection.name = name
    connection.provider = .sftp
    connection.sftp.host = "files.example.com"
    connection.sftp.username = "me"
    return connection
}

func gcsFixture(name: String = "Bucket") -> Connection {
    var connection = Connection()
    connection.name = name
    connection.provider = .googleCloudStorage
    connection.bucket = "my-bucket"
    return connection
}

let serviceAccountJSON = """
{
  "type": "service_account",
  "project_id": "demo",
  "client_email": "drive@demo.iam.gserviceaccount.com",
  "token_uri": "https://oauth2.googleapis.com/token",
  "private_key": "-----BEGIN PRIVATE KEY-----\\nnot-a-real-key\\n-----END PRIVATE KEY-----\\n"
}
"""

private func configURL() -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)/config.json")
}
