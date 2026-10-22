import SwiftUI
import UnlocalFSDomain

extension Provider {
    var logo: Image {
        switch self {
        case .other: Image(systemName: "cylinder.split.1x2")
        case .sftp: Image(.sftp)
        case .googleCloudStorage: Image(.gcs)
        case .aws: Image(.amazonS3)
        case .cloudflare: Image(.cloudflare)
        case .minio: Image(.minio)
        case .wasabi: Image(.wasabi)
        case .digitalOcean: Image(.digitalOcean)
        }
    }
}

struct ProviderIcon: View {
    let provider: Provider
    let size: CGFloat

    var body: some View {
        Group {
            if provider == .other {
                provider.logo.font(.system(size: size * 0.9))
            } else {
                provider.logo.renderingMode(.template).resizable().scaledToFit()
            }
        }
        .frame(width: size, height: size)
    }
}
