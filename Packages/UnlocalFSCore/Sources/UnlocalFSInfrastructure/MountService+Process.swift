import Darwin
import Foundation
import UnlocalFSDomain

enum RcloneState { case running, stopped, untracked }

extension MountService {
    func rcloneState(_ connection: Connection) -> RcloneState {
        guard let pid = savedPID(connection) else { return processes[connection.id].map { $0.isRunning ? .running : .stopped } ?? .untracked }
        if let process = processes[connection.id], process.processIdentifier == pid { return process.isRunning ? .running : .stopped }
        let saved = try? paths.pidFile(connection).resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
        guard let process = Self.process(pid: pid), let saved else { return .stopped }
        return process.startedAt <= saved ? .running : .stopped
    }

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
}
