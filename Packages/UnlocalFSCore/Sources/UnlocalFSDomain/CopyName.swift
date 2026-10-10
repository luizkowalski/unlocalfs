import Foundation

public struct CopyName: Sendable {
    private let base: String
    private let pathExtension: String
    private let word: String

    public init(of fileName: String) {
        self.init(of: fileName, word: String(localized: .copyWord))
    }

    public init(of fileName: String, word: String) {
        let name = fileName as NSString
        base = name.deletingPathExtension
        pathExtension = name.pathExtension
        self.word = word
    }

    public func attempt(_ attempt: Int) -> String {
        let name = attempt == 1 ? "\(base) \(word)" : "\(base) \(word) \(attempt)"
        return pathExtension.isEmpty ? name : "\(name).\(pathExtension)"
    }
}
