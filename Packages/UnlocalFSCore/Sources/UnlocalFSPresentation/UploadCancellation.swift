import Foundation
import UnlocalFSDomain

public struct UploadCancellation: Equatable, Sendable {
    public let connection: Connection
    public let path: String
    public let deletesServerCopy: Bool

    public var title: String { String(localized: .stopUploading((path as NSString).lastPathComponent)) }

    public var message: String {
        deletesServerCopy ? String(localized: .stopUploadDeletesServerCopy) : String(localized: .stopUploadDeletesFile)
    }
}
