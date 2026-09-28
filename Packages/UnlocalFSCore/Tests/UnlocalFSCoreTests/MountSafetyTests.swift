import Foundation
import Testing
import UnlocalFSCore

@Suite struct MountSafetyTests {
    @Test(arguments: [
        "\"uploadsQueued\":1,\"uploadsInProgress\":0,\"erroredFiles\":0",
        "\"uploadsQueued\":0,\"uploadsInProgress\":1,\"erroredFiles\":0",
        "\"uploadsQueued\":0,\"uploadsInProgress\":0,\"erroredFiles\":1"
    ])
    func unmountRefusesQueuedOrFailedUploads(cache: String) async throws {
        try await withFixture(script: "#!/bin/sh\nprintf '%s' '{\"diskCache\":{\(cache),\"bytesUsed\":42}}'\n") { service, connection in
            let status = try await service.status(connection)
            #expect(status.isRunning)
            await #expect { try await service.unmount(connection) } throws: { error in
                error is AppError && error.localizedDescription.contains("upload")
            }
        }
    }

    @Test func uploadsQueuedDuringEjectKeepTheServiceAlive() async throws {
        try await withFixture { root in
            """
            #!/bin/sh
            pending=0
            if [ -f '\(root.path)/checked' ]; then pending=1; fi
            touch '\(root.path)/checked'
            printf '{"diskCache":{"uploadsQueued":%s,"uploadsInProgress":0,"erroredFiles":0,"bytesUsed":42}}' "$pending"
            """
        } operation: { service, connection, _ in
            await #expect { try await service.unmount(connection) } throws: { error in
                error is AppError && error.localizedDescription.contains("upload")
            }
        }
    }

    @Test(arguments: ["before", "during", "after"])
    func disconnectSucceedsWhenRcloneExitsDuringShutdown(phase: String) async throws {
        try await withFixture { shutdownScript(phase: phase, root: $0) } operation: { service, connection, _ in
            try await service.unmount(connection)
            let status = try await service.status(connection)
            #expect(!status.isMounted && !status.isRunning)
        }
    }

    @Test func disconnectReportsQuitFailuresWhileRcloneRemainsRunning() async throws {
        try await withFixture { shutdownScript(phase: "running", root: $0) } operation: { service, connection, _ in
            await #expect { try await service.unmount(connection) } throws: { error in
                error is AppError && error.localizedDescription.contains("Quit failed")
            }
            let status = try await service.status(connection)
            #expect(status.isRunning)
        }
    }

    @Test(arguments: [(Int64(0), "off"), (Int64(5_000_000_000), "5000000000B")])
    func connectingLimitsTheCache(minimumFreeSpace: Int64, flag: String) async throws {
        try await withFixture { root in
            """
            #!/bin/sh
            case "$1" in
                lsf) exit 0 ;;
                nfsmount) echo "$@" > '\(root.path)/arguments'; exit 1 ;;
                *) exit 1 ;;
            esac
            """
        } operation: { service, connection, root in
            var connection = connection
            connection.cacheLimit = 512_000_000
            connection.minimumFreeSpace = minimumFreeSpace
            await #expect(throws: AppError.self) { try await service.mount(connection, credentials: Credentials(accessKey: "a", secretKey: "b")) }
            let arguments = try String(contentsOf: root.appendingPathComponent("arguments"), encoding: .utf8)
            #expect(arguments.contains("--vfs-cache-max-size 512000000B"))
            #expect(arguments.contains("--vfs-cache-min-free-space \(flag)"))
        }
    }

    @Test(arguments: [true, false])
    func readOnlyDrivesMountWithReadOnlyAccess(readOnly: Bool) async throws {
        try await withFixture { root in
            """
            #!/bin/sh
            case "$1" in
                lsf) exit 0 ;;
                nfsmount) echo "$@" > '\(root.path)/arguments'; exit 1 ;;
                *) exit 1 ;;
            esac
            """
        } operation: { service, connection, root in
            var connection = connection
            connection.readOnly = readOnly
            await #expect(throws: AppError.self) { try await service.mount(connection, credentials: Credentials(accessKey: "a", secretKey: "b")) }
            let arguments = try String(contentsOf: root.appendingPathComponent("arguments"), encoding: .utf8)
            #expect(arguments.contains("--read-only") == readOnly)
        }
    }

    @Test func connectionErrorsDoNotExposeCredentials() async throws {
        let script = """
        #!/bin/sh
        case "$1" in
            obscure) printf 'obscured-token' ;;
            lsf)
                printf '%s' "Denied $RCLONE_S3_ACCESS_KEY_ID $RCLONE_S3_SECRET_ACCESS_KEY $RCLONE_S3_SESSION_TOKEN $RCLONE_CRYPT_PASSWORD private-password"
                exit 1 ;;
        esac
        """
        try await withFixture(script: script) { service, connection in
            var connection = connection
            connection.encrypted = true
            let credentials = Credentials(
                accessKey: "private-access", secretKey: "private-secret", sessionToken: "private-token", encryptionPassword: "private-password"
            )
            await #expect { try await service.test(connection, credentials: credentials) } throws: { error in
                !error.localizedDescription.contains("private-") && !error.localizedDescription.contains("obscured-") && error.localizedDescription.contains("Denied")
            }
        }
    }
}

private func shutdownScript(phase: String, root: URL) -> String {
    """
    #!/bin/sh
    if [ "$4" = 'core/quit' ]; then
        if [ '\(phase)' = 'after' ]; then rm "$3"; fi
        echo 'Quit failed'
        exit 1
    fi
    if [ '\(phase)' = 'before' ] || { [ '\(phase)' = 'during' ] && [ -f '\(root.path)/checked' ]; }; then
        rm "$3"
    fi
    touch '\(root.path)/checked'
    printf '%s' '{"diskCache":{"uploadsQueued":0,"uploadsInProgress":0,"erroredFiles":0,"bytesUsed":0}}'
    """
}

private func withFixture(script: String, operation: (MountService, Connection) async throws -> Void) async throws {
    try await withFixture(script: { _ in script }, operation: { service, connection, _ in try await operation(service, connection) })
}

private func withFixture(script: (URL) -> String, operation: (MountService, Connection, URL) async throws -> Void) async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let paths = AppPaths(
        config: root.appendingPathComponent("config.json"),
        support: root,
        mounts: root.appendingPathComponent("drives"),
        logs: root.appendingPathComponent("logs")
    )
    try paths.prepare()
    let connection = fixture()
    FileManager.default.createFile(atPath: paths.socket(connection).path, contents: Data())
    let binary = root.appendingPathComponent("rclone-fixture")
    try script(root).write(to: binary, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: binary.path)
    try await operation(MountService(executable: binary, helperDirectory: root, paths: paths), connection, root)
}
