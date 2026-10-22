import Darwin
import Foundation
import UnlocalFSDomain

extension MountService {
    func eject(_ connection: Connection, force: Bool) async throws {
        let (executable, flags) = force ? ("/sbin/umount", ["-f"]) : ("/usr/sbin/diskutil", ["unmount"])
        let arguments = flags + [paths.mount(connection).path]
        let deadline = ContinuousClock.now.advanced(by: Self.ejectRetryTime)
        while true {
            do {
                _ = try await Command.run(URL(filePath: executable), arguments, timeout: .seconds(60))
                break
            } catch where ContinuousClock.now < deadline {
                try await Task.sleep(for: .seconds(1))
            } catch {
                throw DriveEjectError()
            }
        }
        for _ in 0..<20 {
            if !isMounted(paths.mount(connection)) { return }
            try await Task.sleep(for: .milliseconds(100))
        }
        throw DriveEjectError()
    }

    func stop(_ connection: Connection, askingToQuit: Bool) async throws {
        var quitError: any Error = AppError(String(localized: .driveStillStopping))
        if askingToQuit {
            do {
                _ = try await control(connection, "core/quit")
            } catch {
                quitError = error
            }
            if try await waitForStop(connection) { return }
        }
        if let pid = savedPID(connection) {
            _ = kill(pid, SIGTERM)
            if try await waitForStop(connection) { return }
            _ = kill(pid, SIGKILL)
        }
        guard try await waitForStop(connection) else { throw quitError }
    }

    func waitForStop(_ connection: Connection) async throws -> Bool {
        for _ in 0..<20 {
            let running = isRunning(connection)
            let socket = paths.socket(connection)
            if running != true, !isMounted(paths.mount(connection)) {
                if !FileManager.default.fileExists(atPath: socket.path) { return true }
                if running == false {
                    try FileManager.default.removeItem(at: socket)
                    return true
                }
            }
            try await Task.sleep(for: .milliseconds(100))
        }
        return false
    }
}
