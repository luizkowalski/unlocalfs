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
        #expect(credentials.validate(for: connection).map(\.connectionField) == fields)
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
        #expect(Set(connection.validate().map(\.connectionField)) == fields)
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
