import Foundation
import Testing
import UnlocalFSCore

@Suite struct MountSafetyTests {
    @Test func unavailableControlServiceKeepsRecoveryBlocked() async throws {
        try await withFixture(script: "#!/bin/sh\necho 'Control unavailable' >&2\nexit 1\n") { service, connection in
            let before = await service.status(connection)
            #expect(before.needsReconnect)
            #expect(!before.isRunning)
            await #expect {
                try await service.reconnect(connection, credentials: Credentials(accessKey: "key", secretKey: "secret"))
            } throws: { error in
                error is AppError && error.localizedDescription.contains("Could not stop the old drive service")
            }
            let after = await service.status(connection)
            #expect(after.isActive)
        }
    }

    @Test(arguments: [
        ("\"uploadsQueued\":1,\"uploadsInProgress\":0,\"erroredFiles\":0", true),
        ("\"uploadsQueued\":0,\"uploadsInProgress\":1,\"erroredFiles\":0", true),
        ("\"uploadsQueued\":0,\"uploadsInProgress\":0,\"erroredFiles\":1", false),
        ("\"uploadsQueued\":1,\"uploadsInProgress\":0,\"erroredFiles\":1", false)
    ])
    func unmountRefusesQueuedOrFailedUploads(cache: String, pending: Bool) async throws {
        try await withFixture(script: """
        #!/bin/sh
        if [ "$4" = 'vfs/queue' ]; then printf '{"queue":[]}'; exit 0; fi
        printf '%s' '{"diskCache":{\(cache),"bytesUsed":42}}'
        """) { service, connection in
            let status = await service.status(connection)
            #expect(status.isRunning)
            await #expect { try await service.unmount(connection) } throws: { error in
                pending ? error is UploadsPendingError : error is AppError
            }
        }
    }

    @Test func uploadsQueuedDuringEjectKeepTheServiceAlive() async throws {
        try await withFixture { root in
            """
            #!/bin/sh
            if [ "$4" = 'vfs/queue' ]; then printf '{"queue":[]}'; exit 0; fi
            pending=0
            if [ -f '\(root.path)/checked' ]; then pending=1; fi
            touch '\(root.path)/checked'
            printf '{"diskCache":{"uploadsQueued":%s,"uploadsInProgress":0,"erroredFiles":0,"bytesUsed":42}}' "$pending"
            """
        } operation: { service, connection in
            await #expect { try await service.unmount(connection) } throws: { error in
                error is UploadsPendingError
            }
        }
    }

    @Test func disconnectKeepsTheServiceAliveWhenUploadStatusBecomesUnavailable() async throws {
        try await withFixture { root in
            """
            #!/bin/sh
            if [ "$4" = 'core/quit' ]; then rm "$3"; exit 0; fi
            if [ -f '\(root.path)/checked' ]; then echo 'Control unavailable' >&2; exit 1; fi
            touch '\(root.path)/checked'
            printf '%s' '{"diskCache":{"uploadsQueued":0,"uploadsInProgress":0,"erroredFiles":0,"bytesUsed":42}}'
            """
        } operation: { service, connection in
            await #expect(throws: AppError.self) { try await service.unmount(connection) }
            let status = await service.status(connection)
            #expect(status.isActive)
        }
    }

    @Test(arguments: ["before", "during", "after"])
    func disconnectSucceedsWhenRcloneExitsDuringShutdown(phase: String) async throws {
        try await withFixture { shutdownScript(phase: phase, root: $0) } operation: { service, connection in
            try await service.unmount(connection)
            let status = await service.status(connection)
            #expect(!status.isMounted && !status.isRunning)
        }
    }

    @Test func disconnectReportsQuitFailuresWhileRcloneRemainsRunning() async throws {
        try await withFixture { shutdownScript(phase: "running", root: $0) } operation: { service, connection in
            await #expect { try await service.unmount(connection) } throws: { error in
                error is AppError && error.localizedDescription.contains("Quit failed")
            }
            let status = await service.status(connection)
            #expect(status.isRunning)
        }
    }

    @Test func connectionErrorsDoNotExposeCredentials() async throws {
        let script = """
        #!/bin/sh
        case "$1" in
            obscure) printf 'obscured-token' ;;
            lsf)
                printf '%s' "Denied $RCLONE_S3_ACCESS_KEY_ID $RCLONE_S3_SECRET_ACCESS_KEY $RCLONE_S3_SESSION_TOKEN $RCLONE_CRYPT_PASSWORD private-password" >&2
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
    try await withFixture(script: { _ in script }, operation: operation)
}

private func withFixture(script: (URL) -> String, operation: (MountService, Connection) async throws -> Void) async throws {
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
    try await operation(MountService(executable: binary, helperDirectory: root, paths: paths), connection)
}
