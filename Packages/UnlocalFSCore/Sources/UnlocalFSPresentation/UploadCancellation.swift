import Foundation
import UnlocalFSDomain

public struct UploadCancellation: Sendable {
    public let connection: Connection
    public let path: String

    var fileName: String { (path as NSString).lastPathComponent }
    public var title: String { String(localized: .stopUploading(fileName)) }
    public var message: String { String(localized: .stopUploadWarning) }
}
