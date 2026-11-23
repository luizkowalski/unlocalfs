import Foundation

public extension URL {
    func path(inside folder: URL) -> String? {
        let components = standardizedFileURL.pathComponents
        let root = folder.standardizedFileURL.pathComponents
        guard components.starts(with: root) else { return nil }
        return components.dropFirst(root.count).joined(separator: "/")
    }
}
