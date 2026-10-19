import Foundation
import UnlocalFSDomain

public struct UploadCleanup: Equatable, Sendable {
    public let connection: Connection
    public let abandoned: Int
    public let inFlight: Int

    public var title: String { String(localized: .removeUnfinishedUploads(abandoned)) }

    public var message: String {
        let explanation = String(localized: .abandonedUploadsExplanation)
        return inFlight == 0 ? explanation : "\(explanation) \(String(localized: .recentUploadsKept(inFlight)))"
    }
}
