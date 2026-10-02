public struct ValidationResult<Field: Hashable & Sendable>: Equatable, Sendable {
    public struct Issue: Equatable, Sendable {
        public let field: Field
        public let message: String

        public init(field: Field, message: String) {
            self.field = field
            self.message = message
        }
    }

    public var issues: [Issue] = []

    public init() {}

    public var isValid: Bool { issues.isEmpty }

    public var fieldErrors: [Field: String] {
        Dictionary(issues.map { ($0.field, $0.message) }, uniquingKeysWith: { first, _ in first })
    }

    public mutating func check(_ condition: Bool, field: Field, message: String) {
        if !condition { issues.append(Issue(field: field, message: message)) }
    }

    public func requireValid() throws {
        if !isValid { throw AppError(issues.map(\.message).joined(separator: "\n")) }
    }
}
