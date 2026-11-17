import Foundation

public struct ValidationResult: Equatable, Sendable {
    public struct Issue: Equatable, Sendable {
        public let field: ConnectionField
        public let message: String

        public init(field: ConnectionField, message: String) {
            self.field = field
            self.message = message
        }
    }

    public var issues: [Issue] = []

    public init() {}

    public var isValid: Bool { issues.isEmpty }

    public var fieldErrors: [ConnectionField: String] {
        Dictionary(issues.map { ($0.field, $0.message) }, uniquingKeysWith: { first, _ in first })
    }

    public mutating func check(_ condition: Bool, field: ConnectionField, message: String) {
        if !condition { issues.append(Issue(field: field, message: message)) }
    }

    public func requireValid() throws {
        if !isValid { throw AppError(issues.map(\.message).joined(separator: "\n")) }
    }
}

extension String {
    var isBlank: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}
