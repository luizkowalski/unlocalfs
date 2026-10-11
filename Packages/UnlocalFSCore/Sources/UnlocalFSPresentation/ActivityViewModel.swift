import Foundation
import Observation
import UnlocalFSDomain

@MainActor @Observable public final class ActivityViewModel {
    public private(set) var activity: Result<[FileActivity], any Error>?
    private let drives: any DriveGateway
    private let isBusy: (UUID) -> Bool

    init(drives: any DriveGateway, isBusy: @escaping (UUID) -> Bool) {
        self.drives = drives
        self.isBusy = isBusy
    }

    public var summary: TransferSummary? {
        guard case .success(let files) = activity else { return nil }
        return TransferSummary(files, now: .now)
    }

    var refreshInterval: Duration { summary == nil ? .seconds(1) : .milliseconds(250) }

    public func observe(_ connection: Connection) async {
        activity = nil
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
            activity = .success(files)
        } catch where !Task.isCancelled {
            activity = .failure(error)
        } catch {}
    }
}
