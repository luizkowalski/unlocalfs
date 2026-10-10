import Foundation

public struct CopyName: Sendable {
    private let base: String
    private let pathExtension: String
    private let word = String(localized: .copyWord)

    public init(of fileName: String) {
        let name = fileName as NSString
        base = name.deletingPathExtension
        pathExtension = name.pathExtension
    }

    public func attempt(_ attempt: Int) -> String {
        let name = attempt == 1 ? "\(base) \(word)" : "\(base) \(word) \(attempt)"
        return pathExtension.isEmpty ? name : "\(name).\(pathExtension)"
    }
}
