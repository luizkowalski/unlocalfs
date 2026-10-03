import SwiftUI
import UnlocalFSDomain

extension Provider {
    var logo: Image {
        switch self {
        case .other, .sftp: Image(systemName: "server.rack")
        case .aws: Image(.amazonS3)
        case .cloudflare: Image(.cloudflare)
        case .minio: Image(.minio)
        case .wasabi: Image(.wasabi)
        case .digitalOcean: Image(.digitalOcean)
        }
    }
}
