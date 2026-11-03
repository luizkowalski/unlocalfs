import Foundation
import UnlocalFSDomain

public struct UploadCancellation: Sendable {
    public let connection: Connection
    public let path: String

    public var title: String { String(localized: .stopUploading((path as NSString).lastPathComponent)) }
    public var message: String { String(localized: .stopUploadWarning) }
}
