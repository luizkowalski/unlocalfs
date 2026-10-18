import Foundation
import UnlocalFSInfrastructure

public struct StubbedDrives: Sendable {
    public let root: URL
    public let paths: AppPaths
    public let service: MountService

    public init(_ name: String, rclone script: (URL) -> String = { _ in "" }) throws {
        root = URL(filePath: "/tmp/uf-\(name)-\(UUID().uuidString.prefix(8))")
        paths = AppPaths(config: root.appending(path: "config.json"), support: root, mounts: root.appending(path: "drives"), logs: root.appending(path: "logs"))
        try paths.prepare()
        let executable = root.appending(path: "rclone")
        try """
        #!/bin/sh
        printf '%s\\n' "$1" >> '\(root.path)/process-calls'
        if [ "$1" = 'obscure' ]; then cat >/dev/null; fi
        \(script(root))
        """.write(to: executable, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: executable.path)
        service = MountService(executable: executable, helperDirectory: root, paths: paths)
    }

    public var rcloneCalls: [String] {
        guard let calls = try? String(contentsOf: root.appending(path: "process-calls"), encoding: .utf8) else { return [] }
        return calls.split(separator: "\n").map(String.init)
    }

    public func remove() { try? FileManager.default.removeItem(at: root) }
}
