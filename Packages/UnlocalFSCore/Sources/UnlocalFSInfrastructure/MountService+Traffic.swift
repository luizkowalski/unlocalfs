import Darwin
import Foundation
import UnlocalFSDomain

struct UploadTally {
    let process: RcloneProcess
    private var finished: Int64
    private var uploaded: Int64
    private var since: Date?
    private var counted: Set<String> = []

    init(process: RcloneProcess, checkpoint: TrafficCheckpoint?) {
        self.process = process
        let resumed = checkpoint?.process == process ? checkpoint : nil
        finished = resumed?.uploaded ?? 0
        uploaded = finished
        since = resumed?.savedAt
    }

    mutating func read(_ snapshot: ControlSnapshot) -> Int64 {
        let finishedUploads = snapshot.finished.filter { $0.isUpload && !$0.isServerSide }
        for transfer in finishedUploads where !counted.contains(transfer.key) && since.map({ transfer.completedAt > $0 }) ?? true {
            finished += transfer.bytes
        }
        counted = Set(finishedUploads.map(\.key))
        let inFlight = snapshot.transfers.filter { $0.isUpload && !$0.isServerSide }.reduce(0) { $0 + ($1.bytes ?? 0) }
        uploaded = max(uploaded, finished + inFlight)
        return uploaded
    }
}

extension MountService {
    static func process(pid: pid_t) -> RcloneProcess? {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var name = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        guard sysctl(&name, 4, &info, &size, nil, 0) == 0, size > 0 else { return nil }
        let start = info.kp_proc.p_un.__p_starttime
        return RcloneProcess(pid: pid, startedAt: Date(timeIntervalSince1970: Double(start.tv_sec) + Double(start.tv_usec) / 1_000_000))
    }

    func recordTraffic(_ snapshot: ControlSnapshot, for connection: Connection) -> Traffic {
        guard let saved = try? String(contentsOf: paths.pidFile(connection), encoding: .utf8),
              let pid = pid_t(saved), let process = Self.process(pid: pid) else { return Traffic() }
        do {
            var meter = try meters[connection.id] ?? TrafficMeter(checkpoint: traffic.checkpoint(for: connection.id))
            var tally = uploadTallies[connection.id].flatMap { $0.process == process ? $0 : nil }
                ?? UploadTally(process: process, checkpoint: meter.checkpoint)
            let reading = TrafficReading(process: process, network: snapshot.networkBytes, uploaded: tally.read(snapshot), date: .now)
            if let save = meter.read(reading, calendar: .current) { try traffic.save(save, for: connection) }
            meters[connection.id] = meter
            uploadTallies[connection.id] = tally
            return meter.unsaved
        } catch {
            return meters[connection.id]?.unsaved ?? Traffic()
        }
    }

    func saveTraffic(_ connection: Connection) {
        guard var meter = meters[connection.id], let save = meter.save(calendar: .current),
              (try? traffic.save(save, for: connection)) != nil else { return }
        meters[connection.id] = meter
    }
}

private extension FinishedTransfer {
    var key: String { "\(name)\n\(completedAt.timeIntervalSinceReferenceDate)" }
}
