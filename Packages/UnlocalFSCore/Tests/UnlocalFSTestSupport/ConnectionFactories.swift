import UnlocalFSDomain

public extension Connection {
    static func s3(
        name: String = "My files", endpoint: String = "https://s3.example.com", bucket: String = "my-bucket", folder: String = "",
        _ change: (inout Connection) -> Void = { _ in },
    ) -> Connection {
        var connection = Connection()
        connection.name = name
        connection.endpoint = endpoint
        connection.bucket = bucket
        connection.folder = folder
        change(&connection)
        return connection
    }

    static func sftp(name: String = "Server", _ change: (inout Connection) -> Void = { _ in }) -> Connection {
        var connection = Connection()
        connection.name = name
        connection.provider = .sftp
        connection.sftp.host = "files.example.com"
        connection.sftp.username = "me"
        change(&connection)
        return connection
    }

    static func gcs(
        name: String = "Bucket", authentication: GCSAuthentication = .serviceAccount, _ change: (inout Connection) -> Void = { _ in },
    ) -> Connection {
        var connection = Connection()
        connection.name = name
        connection.provider = .googleCloudStorage
        connection.bucket = "my-bucket"
        connection.gcs.authentication = authentication
        change(&connection)
        return connection
    }
}

public extension Credentials {
    static func s3() -> Credentials { Credentials(accessKey: "key", secretKey: "secret") }
    static func google(_ token: String = googleTokenJSON) -> Credentials { Credentials(googleToken: token) }
}

public let newTokenJSON = #"{"access_token":"ya29.new","token_type":"Bearer","refresh_token":"1//new-refresh","expiry":"2026-11-12T02:00:00Z"}"#

public let googleTokenJSON = #"{"access_token":"ya29.saved-access","token_type":"Bearer","refresh_token":"1//saved-refresh","expiry":"2026-11-12T01:00:00Z"}"#
