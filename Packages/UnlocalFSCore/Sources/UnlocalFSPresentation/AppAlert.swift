public struct AppAlert: Equatable, Sendable {
    public let title: String
    public let message: String

    init(_ title: String, _ message: String) {
        self.title = title
        self.message = message
    }

    init(_ title: String, _ error: any Error) {
        self.init(title, error.localizedDescription)
    }
}
