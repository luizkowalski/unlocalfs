import Foundation
import Synchronization
import Testing
import UnlocalFSDomain
import UnlocalFSFinderLink

@MainActor @Suite(.timeLimit(.minutes(1))) struct FinderSyncPortTests {
    private let name = "unlocalfs-tests.finder.\(UUID().uuidString)"

    @Test func requestsAndRepliesCrossThePortUnchanged() async throws {
        let snapshot = FinderSnapshot(drives: [.init(mount: URL(filePath: "/Users/me/UnlocalFS/Photos"), uploads: ["a.jpg": .failed])])
        let reply = FinderSyncReply.snapshot(snapshot, version: snapshot.version, checkedAt: Date(timeIntervalSinceReferenceDate: 1000))
        let request = FinderSyncRequest.run(.copyShareLink(.week), files: [URL(filePath: "/Users/me/UnlocalFS/Photos/a b.jpg")])
        let received = Mutex<[FinderSyncRequest]>([])
        let port = try FinderSyncPort(name: name) { request in
            received.withLock { $0.append(request) }
            return reply
        }

        #expect(await send(request) == reply)
        #expect(received.withLock { $0 } == [request])
        _ = port
    }

    @Test func unreadableRequestsFailAndThePortKeepsAnswering() async throws {
        let port = try FinderSyncPort(name: name) { _ in .menu([]) }

        #expect(try await sendRaw(Data("garbage".utf8)) == .failed)
        #expect(try await sendRaw(Data(#"{"version":2,"body":{"snapshot":{}}}"#.utf8)) == .failed)
        #expect(await send(.menu([])) == .menu([]))
        _ = port
    }

    private func send(_ request: FinderSyncRequest) async -> FinderSyncReply? {
        await Task.detached { [name] in FinderSyncClient(name: name)?.send(request, timeout: 2) }.value
    }

    private func sendRaw(_ data: Data) async throws -> FinderSyncReply {
        try await Task.detached { [name] in
            let remote = try #require(CFMessagePortCreateRemote(nil, name as CFString))
            var reply: Unmanaged<CFData>?
            try #require(CFMessagePortSendRequest(remote, 0, data as CFData, 2, 2, CFRunLoopMode.defaultMode.rawValue, &reply) == kCFMessagePortSuccess)
            return try FinderSyncMessage.decode(FinderSyncReply.self, from: #require(reply).takeRetainedValue() as Data)
        }.value
    }
}
