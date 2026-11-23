import Foundation
import notify
import UnlocalFSDomain

public struct FinderSyncClient {
    private let port: CFMessagePort

    public init?(name: String = FinderSyncMessage.portName) {
        guard let port = CFMessagePortCreateRemote(nil, name as CFString) else { return nil }
        self.port = port
    }

    public func send(_ request: FinderSyncRequest, timeout: CFTimeInterval = 0.5) -> FinderSyncReply? {
        guard let data = try? FinderSyncMessage.encode(request) else { return nil }
        var reply: Unmanaged<CFData>?
        guard CFMessagePortSendRequest(port, 0, data as CFData, timeout, timeout, CFRunLoopMode.defaultMode.rawValue, &reply) == kCFMessagePortSuccess,
              let reply
        else { return nil }
        return (try? FinderSyncMessage.decode(FinderSyncReply.self, from: reply.takeRetainedValue() as Data)) ?? .failed
    }

    public static func observeChanges(on queue: DispatchQueue, _ handler: @escaping @Sendable () -> Void) {
        var token: Int32 = 0
        notify_register_dispatch(FinderSyncMessage.changedNotification, &token, queue) { _ in handler() }
    }
}
