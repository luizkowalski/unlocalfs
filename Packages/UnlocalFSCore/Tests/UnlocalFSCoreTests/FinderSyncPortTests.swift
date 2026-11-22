import Foundation
import Synchronization
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure

@MainActor @Suite(.timeLimit(.minutes(1))) struct FinderSyncPortTests {
    private let name = "unlocalfs-tests.finder.\(UUID().uuidString)"
    private let snapshot = FinderSnapshot(drives: [.init(mount: URL(filePath: "/Users/me/UnlocalFS/Photos"), uploads: ["a.jpg": .failed])])

    @Test func snapshotRequestsGetTheHandlersReply() async throws {
        let port = try FinderSyncPort(name: name) { [snapshot] request in
            request == .snapshot(since: snapshot.version) ? .unchanged : .snapshot(snapshot, version: snapshot.version)
        }

        #expect(try await send(.snapshot(since: snapshot.version)) == .unchanged)
        #expect(try await send(.snapshot(since: nil)) == .snapshot(snapshot, version: snapshot.version))
        _ = port
    }

    @Test func commandsReachTheHandlerWithTheirFiles() async throws {
        let received = Mutex<[FinderSyncRequest]>([])
        let port = try FinderSyncPort(name: name) { request in
            received.withLock { $0.append(request) }
            return .accepted
        }
        let file = URL(filePath: "/Users/me/UnlocalFS/Photos/a b.jpg")

        #expect(try await send(.run(.copyShareLink(.week), files: [file])) == .accepted)
        #expect(received.withLock { $0 } == [.run(.copyShareLink(.week), files: [file])])
        _ = port
    }

    @Test func unreadableRequestsFailAndThePortKeepsAnswering() async throws {
        let port = try FinderSyncPort(name: name) { _ in .menu([]) }

        #expect(try await FinderSyncMessage.decode(FinderSyncReply.self, from: sendRaw(Data("garbage".utf8))) == .failed)
        let newer = Data(#"{"version":2,"body":{"snapshot":{}}}"#.utf8)
        #expect(try await FinderSyncMessage.decode(FinderSyncReply.self, from: sendRaw(newer)) == .unsupported)
        #expect(try await send(.menu([])) == .menu([]))
        _ = port
    }

    private func send(_ request: FinderSyncRequest) async throws -> FinderSyncReply {
        try await FinderSyncMessage.decode(FinderSyncReply.self, from: sendRaw(FinderSyncMessage.encode(request)))
    }

    private func sendRaw(_ data: Data) async throws -> Data {
        try await Task.detached { [name] in
            let remote = try #require(CFMessagePortCreateRemote(nil, name as CFString))
            var reply: Unmanaged<CFData>?
            let status = CFMessagePortSendRequest(remote, 0, data as CFData, 2, 2, CFRunLoopMode.defaultMode.rawValue, &reply)
            try #require(status == kCFMessagePortSuccess)
            return try #require(reply).takeRetainedValue() as Data
        }.value
    }
}
