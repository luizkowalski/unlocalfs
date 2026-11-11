import Foundation
import UnlocalFSDomain

extension MountService {
    func serve(_ command: MountCommand, in process: Process) async throws {
        let connection = command.remote.connection
        try await wait(for: process) {
            do {
                _ = try await control(connection, "rc/noop")
                return true
            } catch is ControlUnreachable {
                return false
            }
        }
        for remote in command.remote.namedRemotes {
            _ = try await control(connection, "config/create", body: JSONEncoder().encode(CreateRemote(remote)))
        }
        _ = try await control(connection, "mount/mount", command.mountParameters, timeout: .seconds(20))
        try await wait(for: process) { isMounted(paths.mount(connection)) }
    }

    func stopsAfterEject(_ connection: Connection) async -> Bool {
        guard let mounts = try? await control(LiveMounts.self, connection, "mount/listmounts"), mounts.mountPoints.isEmpty else { return false }
        saveTraffic(connection)
        return await (try? stop(connection, askingToQuit: true)) != nil
    }

    private func wait(for process: Process, until ready: () async throws -> Bool) async throws {
        for _ in 0 ..< 60 {
            if try await ready() { return }
            guard process.isRunning else { throw AppError(String(localized: .couldNotMount)) }
            try await Task.sleep(for: .milliseconds(250))
        }
        throw AppError(String(localized: .mountTimedOut))
    }
}
