import Foundation
import Testing
import UnlocalFSDomain
@testable import UnlocalFSInfrastructure

@Suite struct MountSafetyTests {
    @Test func unavailableControlServiceKeepsRecoveryBlocked() async throws {
        try await withFixture(script: "echo 'Control unavailable' >&2\nexit 1\n") { service, connection in
            let before = await service.status(connection)
            #expect(before.needsReconnect)
            #expect(!before.isRunning)
            await #expect {
                try await service.reconnect(connection, credentials: Credentials(accessKey: "key", secretKey: "secret"))
            } throws: { error in
                error is AppError && error.localizedDescription == String(localized: .couldNotStopOldService)
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
            if [ "$4" = 'core/quit' ]; then rm "$3"; exit 0; fi
            if [ "$4" = 'core/stats' ]; then printf '{}'; exit 0; fi
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

    @Test(arguments: [
        ("lsf", 1), ("lsf", 8192)
    ])
    func connectionErrorsDoNotExposeCredentials(command: String, passwordRepetitions: Int) async throws {
        let password = String(repeating: "private-password", count: passwordRepetitions)
        let script = """
        case "$1" in
            rc)
                if [ "$4" = 'vfs/queue' ]; then printf '{"queue":[]}'; else printf '{}'; fi ;;
            obscure) printf 'obscured-token' ;;
            \(command))
                printf '%s' "Denied $RCLONE_S3_ACCESS_KEY_ID $RCLONE_S3_SECRET_ACCESS_KEY $RCLONE_S3_SESSION_TOKEN $RCLONE_CRYPT_PASSWORD \(password)" >&2
                exit 1 ;;
        esac
        """
        try await withFixture(script: script) { service, connection in
            var connection = connection
            connection.encrypted = command == "lsf"
            let credentials = Credentials(
                accessKey: "private-access", secretKey: "private-secret", sessionToken: "private-token", encryptionPassword: password
            )
            await #expect {
                try await service.test(connection, credentials: credentials)
            } throws: { error in
                !error.localizedDescription.contains("private-") && !error.localizedDescription.contains("obscured-") && error.localizedDescription.contains("Denied")
            }
        }
    }

    @Test func sftpErrorsAndCommandsDoNotExposeCredentials() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "uf-sftp-files-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let key = directory.appending(path: "id")
        try Data().write(to: key)
        let script = """
        case "$1" in
            obscure) printf 'obscured-token' ;;
            lsf)
                printf '%s' "$*" > '\(directory.path)/arguments'
                printf '%s' "Denied $RCLONE_SFTP_PASS $RCLONE_SFTP_KEY_FILE_PASS $RCLONE_CRYPT_PASSWORD private-ssh private-phrase private-password" >&2
                exit 1 ;;
        esac
        """
        try await withFixture(script: script) { service, _ in
            var connection = sftpFixture()
            connection.encrypted = true
            connection.sftp.authentication = .privateKey
            connection.sftp.keyFile = key.path
            let credentials = Credentials(encryptionPassword: "private-password", password: "private-ssh", keyPassphrase: "private-phrase")
            await #expect {
                try await service.test(connection, credentials: credentials)
            } throws: { error in
                let message = error.localizedDescription
                return message.contains("Denied") && !message.contains("private-") && !message.contains("obscured-")
            }
            let arguments = try String(contentsOf: directory.appending(path: "arguments"), encoding: .utf8)
            #expect(!arguments.contains("private-") && !arguments.contains("obscured-"))
        }
    }

    @Test func sftpTestRefusesAnUnreadableKeyFileWithoutRunningRclone() async throws {
        var fixtureRoot: URL?
        try await withFixture { root in
            fixtureRoot = root
            return "if [ \"$1\" = 'lsf' ]; then touch '\(root.path)/ran'; fi\n"
        } operation: { service, _ in
            var connection = sftpFixture()
            let root = try #require(fixtureRoot)
            connection.sftp.authentication = .privateKey
            connection.sftp.keyFile = "/nonexistent/id"
            await #expect { try await service.test(connection, credentials: Credentials()) } throws: {
                $0.localizedDescription.contains("/nonexistent/id")
            }
            #expect(!FileManager.default.fileExists(atPath: root.appending(path: "ran").path))
        }
    }

    @Test func shareLinksRefuseDisconnectedDrivesWithoutRunningRclone() async throws {
        var fixtureRoot: URL?
        try await withFixture { root in
            fixtureRoot = root
            return """
            touch '\(root.path)/ran'
            if [ "$1" = 'link' ]; then printf 'https://s3.example.com/my-bucket/a.txt?X-Amz-Signature=abc'; fi
            """
        } operation: { service, connection in
            await #expect {
                _ = try await service.shareLink(for: connection, path: "a.txt", expiry: .day, credentials: Credentials(accessKey: "key", secretKey: "secret"))
            } throws: { error in
                error is AppError && error.localizedDescription == String(localized: .reconnectForLinks)
            }
            let root = try #require(fixtureRoot)
            #expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent("ran").path))
        }
    }

    @Test func configExportRefusesFoldersEndingInWhitespace() async throws {
        var fixtureRoot: URL?
        try await withFixture { root in
            fixtureRoot = root
            return "touch '\(root.path)/ran'\n"
        } operation: { service, connection in
            let root = try #require(fixtureRoot)
            let config = root.appendingPathComponent("rclone.conf")
            var connection = connection
            connection.encrypted = true
            connection.folder = "clients/acme "
            await #expect {
                try await service.exportRcloneConfig(connection, credentials: nil, to: config)
            } throws: { error in
                error.localizedDescription == String(localized: .folderEndsWithSpace)
            }
            connection = sftpFixture()
            connection.encrypted = true
            connection.sftp.remotePath = "/srv/files "
            await #expect {
                try await service.exportRcloneConfig(connection, credentials: nil, to: config)
            } throws: { error in
                error.localizedDescription == String(localized: .folderEndsWithSpace)
            }
            #expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent("ran").path))
            #expect(!FileManager.default.fileExists(atPath: config.path))
        }
    }
}

private func shutdownScript(phase: String, root: URL) -> String {
    """
    if [ "$4" = 'core/quit' ]; then
        if [ '\(phase)' = 'after' ]; then rm "$3"; fi
        echo 'Quit failed'
        exit 1
    fi
    if [ '\(phase)' = 'before' ] || { [ '\(phase)' = 'during' ] && [ -f '\(root.path)/checked' ]; }; then
        rm -f "$3"
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
    try writeRcloneStub(script(root), to: binary)
    try await operation(MountService(executable: binary, helperDirectory: root, paths: paths), connection)
}
