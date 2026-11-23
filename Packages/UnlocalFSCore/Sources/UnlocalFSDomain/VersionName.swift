import Foundation

public struct VersionName: Sendable {
    public let fileName: String?

    public init(of name: String) {
        let pathExtension = (name as NSString).pathExtension
        let stem = (name as NSString).deletingPathExtension
        guard let match = stem.wholeMatch(of: /(.+)-v\d{4}-\d{2}-\d{2}-\d{6}-\d{3}/) else {
            fileName = nil
            return
        }
        fileName = pathExtension.isEmpty ? String(match.1) : "\(match.1).\(pathExtension)"
    }
}
