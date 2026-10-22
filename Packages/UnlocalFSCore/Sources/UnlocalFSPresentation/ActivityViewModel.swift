import Foundation
import Observation
import UnlocalFSDomain

@MainActor @Observable public final class ActivityViewModel {
    public private(set) var activity: Result<[FileActivity], any Error>?
    public private(set) var summary: TransferSummary?
    private let drives: any DriveGateway
    private let isBusy: (UUID) -> Bool
    private let recordSpeed: (SpeedSample, UUID) -> Void

    init(drives: any DriveGateway, isBusy: @escaping (UUID) -> Bool, recordSpeed: @escaping (SpeedSample, UUID) -> Void) {
        self.drives = drives
        self.isBusy = isBusy
        self.recordSpeed = recordSpeed
    }

    var refreshInterval: Duration { summary == nil ? .seconds(1) : .milliseconds(250) }

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

    private func show(_ result: Result<[FileActivity], any Error>?) {
        activity = result
        switch result {
        case .success(let files): summary = TransferSummary(files, now: .now)
        case .failure, nil: summary = nil
        }
    }
}
