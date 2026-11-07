import Foundation
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

    @Test func stoppingAnUploadOnADisconnectedDriveKeepsTheFile() async throws {
        let drive = try serve(pending: "photos/new.jpg")
        let viewModel = fixture.factory(fixture.app()).makeActivity()
        await viewModel.refresh(connection)
        try viewModel.prepareCancellation(of: #require(viewModel.summary?.files.first), in: connection)

        try await viewModel.stopUpload(#require(viewModel.cancellation))

        #expect(drive.contains("photos/new.jpg"))
        #expect(viewModel.alert == String(localized: .reconnectToStopUpload))
    }

    @Test func onlyUploadsCanBeCancelled() {
        let states: [FileActivity.State] = [.queued, .uploading, .failed(nextAttempt: .now), .downloading, .uploaded(.now), .downloaded(.now)]

        let cancellable = states.map { FileActivity(path: "file", size: 1, state: $0, bytesTransferred: nil).isCancellable }

        #expect(cancellable == [true, true, true, false, false, false])
    }

    @discardableResult
    private func serve(pending path: String) throws -> FakeDrive {
        let drive = try FakeDrive(mount: fixture.paths.mount(connection), pending: path)
        try fixture.serve(connection) { request in
            switch request.method {
            case "vfs/queue":
                drive.queue()
            default:
                statusBatch(queue: drive.queue())
            }
        }
        return drive
    }
}

private final class FakeDrive: Sendable {
    private let mount: URL
    private let pending: String

    init(mount: URL, pending path: String) throws {
        self.mount = mount
        pending = path
        let file = mount.appending(path: path)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("changed".utf8).write(to: file)
    }

    func contains(_ path: String) -> Bool { FileManager.default.fileExists(atPath: mount.appending(path: path).path) }

    func queue() -> String {
        let item = #"{"name":"\#(pending)","id":1,"size":7,"expiry":3,"tries":0,"delay":5,"uploading":false}"#
        return #"{"queue":[\#(contains(pending) ? item : "")]}"#
    }
}
