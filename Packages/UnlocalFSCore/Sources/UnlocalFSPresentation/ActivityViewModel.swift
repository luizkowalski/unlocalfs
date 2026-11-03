import Foundation
import Observation
import UnlocalFSDomain

@MainActor @Observable public final class ActivityViewModel {
    public private(set) var activity: Result<[FileActivity], any Error>?
    public private(set) var summary: TransferSummary?
    public var cancellation: UploadCancellation?
    public var alert: String?
    private let drives: any DriveGateway
    private let isBusy: (UUID) -> Bool
    private let recordSpeed: (SpeedSample, UUID) -> Void

    init(drives: any DriveGateway, isBusy: @escaping (UUID) -> Bool, recordSpeed: @escaping (SpeedSample, UUID) -> Void) {
        self.drives = drives
        self.isBusy = isBusy
        self.recordSpeed = recordSpeed
    }

    var refreshInterval: Duration {
        guard let summary, summary.fileCount > 0 else { return .seconds(2) }
        return .milliseconds(500)
    }

    public func observe(_ connection: Connection) async {
        show(nil)
        while !Task.isCancelled {
            await refresh(connection)
            do {
                try await Task.sleep(for: refreshInterval)
            } catch { return }
        }
    }

    func refresh(_ connection: Connection) async {
        guard !isBusy(connection.id) else { return }
        do {
            let files = try await drives.activity(connection)
            try Task.checkCancellation()
            show(.success(files))
            recordSpeed(SpeedSample(files, at: .now), connection.id)
        } catch where !Task.isCancelled {
            show(.failure(error))
        } catch {}
    }

    public func prepareCancellation(of activity: FileActivity, in connection: Connection) {
        cancellation = UploadCancellation(connection: connection, path: activity.path)
    }

    public func stopUpload(_ cancellation: UploadCancellation) async {
        do {
            try await drives.deleteFileToStopUpload(cancellation.path, in: cancellation.connection)
        } catch {
            alert = error.localizedDescription
        }
    }

    private func show(_ result: Result<[FileActivity], any Error>?) {
        activity = result
        switch result {
        case let .success(files): summary = TransferSummary(files, now: .now)
        case .failure, nil: summary = nil
        }
    }
}

public extension FileActivity {
    var isCancellable: Bool {
        switch state {
        case .queued, .uploading, .failed: true
        case .downloading, .uploaded, .downloaded: false
        }
    }
}
