import Foundation
import Synchronization
import Testing
import UnlocalFSDomain
@testable import UnlocalFSInfrastructure
@testable import UnlocalFSPresentation
import UnlocalFSTestSupport

@MainActor @Suite(.timeLimit(.minutes(1))) final class CancelUploadTests {
    let fixture: ViewModelFixture
    let connection = Connection.s3()

    init() throws { fixture = try ViewModelFixture() }

    deinit { fixture.remove() }

    @Test func cancellingANewFileDeletesItAndClearsItsRow() async throws {
        let drive = try serve(pending: "photos/new.jpg")
        let viewModel = fixture.factory(fixture.app()).makeActivity()
        await viewModel.refresh(connection)
        let upload = try #require(viewModel.summary?.files.first)

        await viewModel.reviewCancel(upload, in: connection)
        let cancellation = try #require(viewModel.cancellation)
        #expect(cancellation.message == String(localized: .stopUploadDeletesFile))
        await viewModel.cancelUpload(cancellation)

        #expect(!drive.contains("photos/new.jpg"))
        #expect(viewModel.summary == nil)
        #expect(viewModel.alert == nil)
    }

    @Test(arguments: [ServerCopy.present, .unreachable])
    func cancellingWarnsWhenTheServerCopyMayBeDeleted(_ serverCopy: ServerCopy) async throws {
        try serve(pending: "report.pdf", serverCopy: serverCopy)
        let viewModel = fixture.factory(fixture.app()).makeActivity()
        await viewModel.refresh(connection)

        try await viewModel.reviewCancel(#require(viewModel.summary?.files.first), in: connection)

        #expect(viewModel.cancellation?.message == String(localized: .stopUploadDeletesServerCopy))
    }

    @Test func uploadThatFinishesBeforeTheConfirmationKeepsTheFile() async throws {
        let drive = try serve(pending: "report.pdf", serverCopy: .present)
        let viewModel = fixture.factory(fixture.app()).makeActivity()
        await viewModel.refresh(connection)
        try await viewModel.reviewCancel(#require(viewModel.summary?.files.first), in: connection)
        let cancellation = try #require(viewModel.cancellation)

        drive.finishUploads()
        await viewModel.cancelUpload(cancellation)

        #expect(drive.contains("report.pdf"))
        #expect(viewModel.alert == String(localized: .uploadAlreadyFinished("report.pdf")))
    }

    @Test func onlyUploadsCanBeCancelled() {
        let states: [FileActivity.State] = [.queued, .uploading, .failed(nextAttempt: .now), .downloading, .uploaded(.now), .downloaded(.now)]

        let cancellable = states.map { FileActivity(path: "file", size: 1, state: $0, bytesTransferred: nil).isCancellable }

        #expect(cancellable == [true, true, true, false, false, false])
    }

    enum ServerCopy {
        case absent, present, unreachable
    }

    @discardableResult
    private func serve(pending path: String, serverCopy: ServerCopy = .absent) throws -> FakeDrive {
        let drive = try FakeDrive(mount: fixture.paths.mount(connection), pending: path)
        try fixture.serve(connection) { request in
            switch request.method {
            case "operations/stat":
                switch serverCopy {
                case .absent: return #"{"item":null}"#
                case .present: return #"{"item":{"Path":"\#(path)"}}"#
                case .unreachable: throw ControlFailure("connection refused")
                }
            case "vfs/queue":
                return drive.queue()
            default:
                return #"{"results":[{"diskCache":{"uploadsQueued":0,"uploadsInProgress":0,"bytesUsed":0}},\#(drive.queue()),{\#(rcloneCounters)}]}"#
            }
        }
        return drive
    }
}

private final class FakeDrive: Sendable {
    private let mount: URL
    private let pending: Mutex<Set<String>>

    init(mount: URL, pending path: String) throws {
        self.mount = mount
        pending = Mutex([path])
        let file = mount.appending(path: path)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("changed".utf8).write(to: file)
    }

    func contains(_ path: String) -> Bool { FileManager.default.fileExists(atPath: mount.appending(path: path).path) }

    func finishUploads() { pending.withLock { $0.removeAll() } }

    func queue() -> String {
        let items = pending.withLock { $0 }.filter(contains).map { #"{"name":"\#($0)","id":1,"size":7,"expiry":3,"tries":0,"delay":5,"uploading":false}"# }
        return #"{"queue":[\#(items.joined(separator: ","))]}"#
    }
}
