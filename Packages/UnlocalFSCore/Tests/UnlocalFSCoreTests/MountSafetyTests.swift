import Foundation
import Testing
import UnlocalFSDomain
@testable import UnlocalFSInfrastructure
import UnlocalFSTestSupport

@Suite struct MountSafetyTests {
    @Test func ejectCommandTimeoutFitsRetryWindow() {
        #expect(MountService.ejectCommandTimeout == .seconds(1))
    }

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
        (#""uploadsQueued":1,"uploadsInProgress":0"#, "", true),
        (#""uploadsQueued":0,"uploadsInProgress":1"#, "", true),
        (#""uploadsQueued":0,"uploadsInProgress":0"#, failedItem, false),
        (#""uploadsQueued":1,"uploadsInProgress":0"#, failedItem, false),
    ])
    func unmountRefusesQueuedOrFailedUploads(cache: String, queue: String, pending: Bool) async throws {
        let batch = statusBatch(cache: cache + #","bytesUsed":42"#, queue: #"{"queue":[\#(queue)]}"#)
        try await withControl { _, _ in { _ in batch } } operation: { service, connection in
            let status = await service.status(connection)
            #expect(status.isRunning)
            await #expect { try await service.unmount(connection) } throws: { error in
                pending ? error is UploadsPendingError : error is AppError
            }
        }
    }

    @Test func cacheItemsRcloneCouldNotClearAreNotFailedUploads() async throws {
        let batch = statusBatch(cache: #""uploadsQueued":0,"uploadsInProgress":0,"erroredFiles":1,"bytesUsed":42"#)
        try await withControl { _, _ in { _ in batch } } operation: { service, connection in
            let status = await service.status(connection)
            #expect(status.failedUploads == 0)
            #expect(throws: Never.self) { try status.requireSafeDisconnect() }
        }
    }

    @Test(arguments: [(2, false, true), (3, true, true), (1, false, true), (1, true, false), (0, false, false)])
    func uploadErrorShowsOnlyWhileAnUploadHasFailed(tries: Int, uploading: Bool, failed: Bool) async throws {
        let item = #"{"name":"a.txt","id":1,"size":1,"expiry":1,"tries":\#(tries),"delay":5,"uploading":\#(uploading)}"#
        let batch = statusBatch(
            cache: #""uploadsQueued":0,"uploadsInProgress":0,"bytesUsed":42"#,
            queue: #"{"queue":[\#(item)]}"#, stats: #"{"lastError":"AccessDenied: Access Denied"}"#
        )
        try await withControl { _, _ in { _ in batch } } operation: { service, connection in
            let status = await service.status(connection)
            #expect(status.failedUploads == (failed ? 1 : 0))
            #expect(status.uploadError == (failed ? "AccessDenied: Access Denied" : nil))
        }
    }

    @Test func anErrorInsideTheStatusBatchMarksTheDriveForReconnect() async throws {
        let batch = statusBatch(cache: #""uploadsQueued":0,"uploadsInProgress":0,"bytesUsed":42"#, stats: #"{"error":"core/stats failed","status":500}"#)
        try await withControl { _, _ in { _ in batch } } operation: { service, connection in
            let status = await service.status(connection)
            #expect(status.needsReconnect)
            #expect(status.controlError?.contains("core/stats failed") == true)
        }
    }

    @Test func uploadsQueuedDuringEjectKeepTheServiceAlive() async throws {
        try await withControl { root, _ in
            { request in
                if request.method == "job/list" { return #"{"runningIds":[]}"# }
                let pending = mark(root.appending(path: "checked")) ? 1 : 0
                return statusBatch(cache: #""uploadsQueued":\#(pending),"uploadsInProgress":0,"bytesUsed":42"#)
            }
        } operation: { service, connection in
            await #expect { try await service.unmount(connection) } throws: { error in
                error is UploadsPendingError
            }
        }
    }

    @Test func disconnectKeepsTheServiceAliveWhenUploadStatusBecomesUnavailable() async throws {
        try await withControl { root, socket in
            { request in
                if request.method == "core/quit" {
                    try FileManager.default.removeItem(at: socket)
                    return "{}"
                }
                if mark(root.appending(path: "checked")) { throw ControlFailure("Control unavailable") }
                return statusBatch(cache: #""uploadsQueued":0,"uploadsInProgress":0,"bytesUsed":42"#)
            }
        } operation: { service, connection in
            await #expect(throws: AppError.self) { try await service.unmount(connection) }
            let status = await service.status(connection)
            #expect(status.isActive)
        }
    }

    @Test func disconnectRefusesWhileRcloneRunsADuplicateBeforeOrAfterEject() async throws {
        var fixtureRoot: URL?
        try await withControl { root, _ in
            fixtureRoot = root
            return { request in
                switch request.method {
                case "job/list":
                    return mark(root.appending(path: "listed")) ? #"{"runningIds":[3,7]}"# : #"{"runningIds":[3]}"#
                case "job/status":
                    let group = request.parameter("jobid") == "7" ? "duplicate" : ""
                    return #"{"finished":false,"success":false,"error":"","group":"\#(group)"}"#
                case "core/quit":
                    _ = mark(root.appending(path: "quit"))
                    return "{}"
                default:
                    return statusBatch(cache: #""uploadsQueued":0,"uploadsInProgress":0,"bytesUsed":0"#)
                }
            }
        } operation: { service, connection in
            await #expect { try await service.unmount(connection) } throws: { error in
                error.localizedDescription == String(localized: .copyInProgress)
            }
            #expect(await service.status(connection).isRunning)
            let root = try #require(fixtureRoot)
            #expect(!FileManager.default.fileExists(atPath: root.appending(path: "quit").path))
        }
    }

    @Test func controlCallsStopAtTheirDeadline() async throws {
        let socket = URL(filePath: "/tmp/uf-deadline-\(UUID().uuidString.prefix(8)).sock")
        let server = try ControlServer(at: socket) { _ in
            try await Task.sleep(for: .seconds(2))
            return "{}"
        }
        defer {
            server.stop()
            try? FileManager.default.removeItem(at: socket)
        }
        let started = ContinuousClock.now

        await #expect { _ = try await ControlSocket.post(socket, "core/stats", body: Data("{}".utf8), timeout: .milliseconds(300)) } throws: { error in
            error.localizedDescription == String(localized: .commandTimedOut)
        }
        #expect(ContinuousClock.now - started < .seconds(1))
    }

    @Test(arguments: ["before", "during", "after"])
    func disconnectSucceedsWhenRcloneExitsDuringShutdown(phase: String) async throws {
        try await withControl { shutdown(phase: phase, root: $0, socket: $1) } operation: { service, connection in
            try await service.unmount(connection)
            let status = await service.status(connection)
            #expect(!status.isMounted && !status.isRunning)
        }
    }

    @Test func disconnectReportsQuitFailuresWhileRcloneRemainsRunning() async throws {
        try await withControl { shutdown(phase: "running", root: $0, socket: $1) } operation: { service, connection in
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

private func shutdown(phase: String, root: URL, socket: URL) -> ControlServer.Respond {
    { request in
        switch request.method {
        case "job/list":
            let listed = mark(root.appending(path: "listed"))
            if phase == "before" || (phase == "during" && listed) { try FileManager.default.removeItem(at: socket) }
            return #"{"runningIds":[]}"#
        case "core/quit":
            if phase == "after" { try FileManager.default.removeItem(at: socket) }
            throw ControlFailure("Quit failed")
        default:
            return statusBatch(cache: #""uploadsQueued":0,"uploadsInProgress":0,"bytesUsed":42"#)
        }
    }
}

private let failedItem = #"{"name":"a.txt","id":1,"size":1,"expiry":1,"tries":2,"delay":5,"uploading":false}"#

private func mark(_ file: URL) -> Bool {
    defer { FileManager.default.createFile(atPath: file.path, contents: Data()) }
    return FileManager.default.fileExists(atPath: file.path)
}

private func withFixture(script: String, operation: (MountService, Connection) async throws -> Void) async throws {
    try await withFixture(script: { _ in script }, operation: operation)
}

private func withControl(
    _ control: @escaping (_ root: URL, _ socket: URL) -> ControlServer.Respond, operation: (MountService, Connection) async throws -> Void
) async throws {
    try await withFixture(script: { _ in "" }, control: control, operation: operation)
}

private func withFixture(
    script: (URL) -> String, control: ((_ root: URL, _ socket: URL) -> ControlServer.Respond)? = nil,
    operation: (MountService, Connection) async throws -> Void
) async throws {
    let root = URL(filePath: "/tmp/uf-safety-\(UUID().uuidString.prefix(8))")
    defer { try? FileManager.default.removeItem(at: root) }
    let paths = AppPaths(
        config: root.appendingPathComponent("config.json"),
        support: root,
        mounts: root.appendingPathComponent("drives"),
        logs: root.appendingPathComponent("logs")
    )
    try paths.prepare()
    let connection = fixture()
    let socket = paths.socket(connection)
    let server = try control.map { try ControlServer(at: socket, respond: $0(root, socket)) }
    defer { server?.stop() }
    if server == nil { FileManager.default.createFile(atPath: socket.path, contents: Data()) }
    let binary = root.appendingPathComponent("rclone-fixture")
    try writeRcloneStub(script(root), to: binary)
    try await operation(MountService(executable: binary, helperDirectory: root, paths: paths), connection)
}
