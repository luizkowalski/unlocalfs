import UnlocalFSDomain

extension Connection {
    public static func s3(
        name: String = "My files", endpoint: String = "https://s3.example.com", bucket: String = "my-bucket", folder: String = "",
        _ change: (inout Connection) -> Void = { _ in }
    ) -> Connection {
        var connection = Connection()
        connection.name = name
        connection.endpoint = endpoint
        connection.bucket = bucket
        connection.folder = folder
        change(&connection)
        return connection
    }

    public static func sftp(name: String = "Server", _ change: (inout Connection) -> Void = { _ in }) -> Connection {
        var connection = Connection()
        connection.name = name
        connection.provider = .sftp
        connection.sftp.host = "files.example.com"
        connection.sftp.username = "me"
        change(&connection)
        return connection
    }

    public static func gcs(name: String = "Bucket", _ change: (inout Connection) -> Void = { _ in }) -> Connection {
        var connection = Connection()
        connection.name = name
        connection.provider = .googleCloudStorage
        connection.bucket = "my-bucket"
        change(&connection)
        return connection
    }
}
