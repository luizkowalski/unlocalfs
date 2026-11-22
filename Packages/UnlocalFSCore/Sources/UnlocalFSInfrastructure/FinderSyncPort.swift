import Foundation
import UnlocalFSDomain

@MainActor public final class FinderSyncPort {
    public typealias Handler = @MainActor (FinderSyncRequest) -> FinderSyncReply

    public struct Unavailable: LocalizedError {
        public let name: String
        public var errorDescription: String? { "Finder extension port \(name) is in use" }
    }

    private let handler: Handler
    private nonisolated(unsafe) var port: CFMessagePort?

    public init(name: String, handler: @escaping Handler) throws {
        self.handler = handler
        var context = CFMessagePortContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil)
        var shouldFree: DarwinBoolean = false
        port = CFMessagePortCreateLocal(nil, name as CFString, { _, _, data, info in
            let server = Unmanaged<FinderSyncPort>.fromOpaque(info!).takeUnretainedValue()
            let request = (data as Data?) ?? Data()
            let reply = MainActor.assumeIsolated { server.respond(to: request) }
            return Unmanaged.passRetained(reply as CFData)
        }, &context, &shouldFree)
        guard let port else { throw Unavailable(name: name) }
        CFMessagePortSetDispatchQueue(port, .main)
    }

    deinit {
        if let port { CFMessagePortInvalidate(port) }
    }

    private func respond(to data: Data) -> Data {
        let reply: FinderSyncReply
        do {
            reply = try handler(FinderSyncMessage.decode(FinderSyncRequest.self, from: data))
        } catch is FinderSyncMessage.UnsupportedVersion {
            reply = .unsupported
        } catch {
            reply = .failed
        }
        return (try? FinderSyncMessage.encode(reply)) ?? Data()
    }
}
