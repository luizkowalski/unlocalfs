import SwiftUI
import UnlocalFSDomain

extension Provider {
    var logoIsSymbol: Bool { self == .other || self == .googleCloudStorage }

    var logo: Image {
        switch self {
        case .other: Image(systemName: "server.rack")
        case .sftp: Image(.sftp)
        case .googleCloudStorage: Image(systemName: "cloud")
        case .aws: Image(.amazonS3)
        case .cloudflare: Image(.cloudflare)
        case .minio: Image(.minio)
        case .wasabi: Image(.wasabi)
        case .digitalOcean: Image(.digitalOcean)
        }
    }
}
