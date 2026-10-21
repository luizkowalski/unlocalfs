import Darwin
import Foundation
import OSLog
import UnlocalFSDomain

struct TrafficTracker {
    var meter: TrafficMeter
    var uploads: UploadTally
}

struct UploadTally {
    let process: RcloneProcess
    private var finished: Int64 = 0
    private var uploaded: Int64 = 0
    private var counted: Set<FinishedTransfer> = []
    private var network: Int64 = 0

    init(process: RcloneProcess) { self.process = process }

    mutating func read(_ snapshot: ControlSnapshot) -> Int64 {
        guard snapshot.networkBytes >= network else { return uploaded }
        network = snapshot.networkBytes
        let finishedUploads = snapshot.finished.filter { $0.isUpload && !$0.isServerSide }
        for transfer in finishedUploads where !counted.contains(transfer) {
            finished += transfer.bytes
        }
        counted = Set(finishedUploads)
        let finishedNames = Set(finishedUploads.map(\.name))
        let inFlight = snapshot.transfers.filter { $0.isUpload && !$0.isServerSide && !finishedNames.contains($0.name) }.reduce(0) { $0 + ($1.bytes ?? 0) }
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

    func savedPID(_ connection: Connection) -> pid_t? {
        guard let saved = try? String(contentsOf: paths.pidFile(connection), encoding: .utf8), let pid = pid_t(saved), pid > 0 else { return nil }
        return pid
    }

    func recordTraffic(_ snapshot: ControlSnapshot, for connection: Connection) -> Traffic {
        guard let pid = savedPID(connection), let process = Self.process(pid: pid) else { return Traffic() }
        do {
            var tracker = try trackers[connection.id]
                ?? TrafficTracker(meter: TrafficMeter(checkpoint: traffic.checkpoint(for: connection.id)), uploads: UploadTally(process: process))
            if tracker.uploads.process != process { tracker.uploads = UploadTally(process: process) }
            let reading = TrafficReading(process: process, network: snapshot.networkBytes, uploaded: tracker.uploads.read(snapshot), date: .now)
            if let save = tracker.meter.read(reading, calendar: .current) { try traffic.save(save, for: connection) }
            trackers[connection.id] = tracker
            return tracker.meter.unsaved
        } catch {
            Logger().error("Could not record traffic: \(error, privacy: .public)")
            return trackers[connection.id]?.meter.unsaved ?? Traffic()
        }
    }

    func saveTraffic(_ connection: Connection) {
        guard var tracker = trackers[connection.id], let save = tracker.meter.save(calendar: .current) else { return }
        do {
            try traffic.save(save, for: connection)
        } catch {
            Logger().error("Could not save traffic: \(error, privacy: .public)")
            return
        }
        trackers[connection.id] = tracker
    }
}
