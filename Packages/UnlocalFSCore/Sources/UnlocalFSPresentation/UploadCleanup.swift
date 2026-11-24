import Foundation
import UnlocalFSDomain

public struct UploadCleanup: Equatable, Sendable {
    public let connection: Connection
    public let abandoned: Int
    public let inFlight: Int

    public var title: String { String(localized: .removeUnfinishedUploads(abandoned)) }

    public var message: String { Self.describe(String(localized: .abandonedUploadsExplanation), keeping: inFlight) }

    static func describe(_ text: String, keeping inFlight: Int) -> String {
        inFlight == 0 ? text : "\(text) \(String(localized: .recentUploadsKept(inFlight)))"
    }
}
