import Foundation
import UnlocalFSDomain

public extension AppViewModel {
    func run() async {
        await refresh()
        await connectAutomatically()
        while !Task.isCancelled {
            await refresh()
            do {
                try await Task.sleep(for: .seconds(3))
            } catch { return }
        }
    }

    func refresh() async {
        guard !sleeping else { return }
        if refreshing {
            refreshRequested = true
            return
        }
        refreshing = true
        defer { refreshing = false }
        repeat {
            refreshRequested = false
            let checked = connections.filter { !busy.contains($0.id) }
            await withTaskGroup(of: (Connection, MountStatus).self) { group in
                for connection in checked {
                    group.addTask { [drives] in await (connection, drives.status(connection)) }
                }
                for await (connection, status) in group {
                    guard !sleeping, !refreshRequested, !busy.contains(connection.id) else { continue }
                    update(status, for: connection)
                }
            }
        } while refreshRequested && !sleeping
    }

    func willSleep() { sleeping = true }

    func didWake() async {
        sleeping = false
        await refresh()
    }

    func networkChanged(available: Bool) async {
        networkAvailable = available
        await refresh()
    }

    internal func recordSpeed(_ sample: SpeedSample, for id: UUID) {
        var samples = speeds[id, default: []]
        samples.removeAll { !(0 ..< Self.speedWindow).contains(sample.date.timeIntervalSince($0.date)) }
        if let last = samples.last, floor(last.date.timeIntervalSinceReferenceDate) == floor(sample.date.timeIntervalSinceReferenceDate) {
            if last.upload == sample.upload, last.download == sample.download { return }
            samples.removeLast()
        }
        samples.append(sample)
        speeds[id] = samples
    }

    internal func update(_ status: MountStatus, for connection: Connection) {
        if status.failedUploads > 0, notifiedFailures.insert(connection.id).inserted {
            let body = status.uploadError.map { String(localized: .uploadsFailedReason($0)) } ?? String(localized: .uploadsFailedBody)
            desktop.notify(title: String(localized: .uploadsFailed(connection.name)), body: body, fallbackToAlert: false)
        }
        if status.isServing, status.pendingUploads == 0, status.failedUploads == 0 {
            notifiedFailures.remove(connection.id)
            if waitingToDisconnect.remove(connection.id) != nil {
                desktop.notify(title: String(localized: .finishedUploading(connection.name)), body: String(localized: .canDisconnectNow), fallbackToAlert: false)
            }
        }
        if statuses[connection.id] != status { statuses[connection.id] = status }
        if status.isServing {
            recordSpeed(SpeedSample(status, at: .now), for: connection.id)
        } else if !status.isRunning, speeds[connection.id] != nil {
            speeds[connection.id] = nil
        }
    }
}
