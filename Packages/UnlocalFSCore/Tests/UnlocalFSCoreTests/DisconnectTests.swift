import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure
import UnlocalFSPresentation

@Suite(.timeLimit(.minutes(2))) struct DisconnectTests {
    @Test func busyDriveStaysConnectedAndCanDisconnectAfterTheFileCloses() async throws {
        try await withS3Drive { drive, bucket in
            try Data("open file".utf8).write(to: bucket.appending(path: "open.txt"))
            try await drive.service.mount(drive.connection, credentials: s3Credentials)
            let app = await makeApp(drive)
            await app.refresh()
            let file = try FileHandle(forReadingFrom: drive.mounted.appending(path: "open.txt"))
            defer { try? file.close() }

            await app.toggle(drive.connection)

            #expect(await app.disconnectFailure == drive.connection)
            #expect(await app.isActive(drive.connection))
            #expect(await app.canOpen(drive.connection))
            #expect(await app.problem(drive.connection) == nil)
            #expect(await MainActor.run { app.indicator(drive.connection) == .connected })

            try file.close()
            await app.disconnect(drive.connection)

            #expect(await app.disconnectFailure == nil)
            #expect(await !app.isActive(drive.connection))
        }
    }

    @Test func disconnectRetryDoesNotReconnectADriveEjectedOutsideTheApp() async throws {
        try await withS3Drive { drive, _ in
            try await drive.service.mount(drive.connection, credentials: s3Credentials)
            let app = await makeApp(drive)
            await app.refresh()
            try await drive.service.unmount(drive.connection)

            await app.disconnect(drive.connection)

            #expect(await !app.isActive(drive.connection))
            #expect(await app.disconnectFailure == nil)
        }
    }
}

@MainActor private func makeApp(_ drive: Drive) -> AppViewModel {
    let repository = SavedConnectionRepository(store: ConnectionStore(url: drive.paths.config), credentials: MemoryCredentialStorage())
    return AppViewModel(
        initialConnections: .success([drive.connection]), drives: drive.service,
        deleteConnection: DeleteConnectionUseCase(repository: repository, drives: drive.service),
        toggleDrive: ToggleDriveUseCase(repository: repository, drives: drive.service),
        shareFiles: ShareFilesUseCase(repository: repository, drives: drive.service),
        exportConfig: ExportRcloneConfigUseCase(repository: repository, drives: drive.service),
        quit: QuitUseCase(drives: drive.service), desktop: DisconnectDesktop(paths: drive.paths)
    )
}

@MainActor private final class DisconnectDesktop: DesktopServices {
    let paths: AppPaths
    var opensAtLogin = false

    init(paths: AppPaths) { self.paths = paths }

    func setOpensAtLogin(_ enabled: Bool) { opensAtLogin = enabled }
    func mountLocation(_ connection: Connection) -> URL { paths.mount(connection) }
    func openDrive(_ connection: Connection) {}
    func openLog(_ connection: Connection) {}
    func copyShareLinks(_ links: [URL]) {}
    func chooseRcloneConfigDestination(for connection: Connection) -> RcloneConfigDestination? { nil }
    func notify(title: String, body: String, fallbackToAlert: Bool) {}
}
