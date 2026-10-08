import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSInfrastructure
@testable import UnlocalFSPresentation

extension IntegrationTests {
    @Suite
    struct DriveFeatureTests {
        @MainActor @Test func activatingADriveConnectsReconnectsAndOpensFinderWithoutDisconnectingAHealthyOne() async throws {
            try await withAppDrive { drive, app, desktop in
                let id = drive.connection.id
                let socket = drive.paths.socket(drive.connection)
                let hiddenSocket = socket.appendingPathExtension("hidden")

                async let first: Void = app.activate(drive.connection)
                async let second: Void = app.activate(drive.connection)
                _ = await (first, second)
                #expect(app.problem(drive.connection) == nil)
                #expect(desktop.openedDrives == [id], "repeated activation while connecting opens Finder once")
                #expect(app.canOpen(drive.connection))
                #expect(await drive.service.status(drive.connection).isMounted)

                await app.refresh()
                await app.activate(drive.connection)
                #expect(desktop.openedDrives == [id, id], "a connected drive only opens Finder")
                #expect(await drive.service.status(drive.connection).isMounted)

                try await drive.service.unmount(drive.connection)
                try #require(app.canOpen(drive.connection))
                await app.activate(drive.connection)
                #expect(desktop.openedDrives == [id, id, id], "a drive disconnected since the last refresh connects")
                #expect(await drive.service.status(drive.connection).isMounted)

                try FileManager.default.moveItem(at: socket, to: hiddenSocket)
                await app.refresh()
                #expect(app.needsReconnect(drive.connection))
                await app.activate(drive.connection)
                #expect(desktop.openedDrives == [id, id, id, id], "an unhealthy drive reconnects")
                #expect(app.canOpen(drive.connection))
                #expect(await drive.service.status(drive.connection).isMounted)
                try FileManager.default.removeItem(at: hiddenSocket)

                try FileManager.default.moveItem(at: socket, to: hiddenSocket)
                await app.refresh()
                #expect(app.needsReconnect(drive.connection))
                try FileManager.default.moveItem(at: hiddenSocket, to: socket)
                await app.activate(drive.connection)
                #expect(desktop.openedDrives == [id, id, id, id, id], "a recovered drive only opens Finder")
                #expect(await drive.service.status(drive.connection).isMounted)

                await app.disconnectAll()
                #expect(app.problem(drive.connection) == nil)
                #expect(!app.isActive(drive.connection))
                #expect(await !drive.service.status(drive.connection).isActive)
            }
        }

        @MainActor @Test func openingADriveKeepsItsUploadCompletionNotification() async throws {
            try await withAppDrive { drive, app, desktop in
                try await drive.service.mount(drive.connection, credentials: s3Credentials)
                try Data("upload".utf8).write(to: drive.mounted.appendingPathComponent("upload.txt"))
                try #require(await drive.service.status(drive.connection).pendingUploads > 0)
                await app.refresh()
                await app.toggle(drive.connection)
                try #require(app.canOpen(drive.connection))

                await app.activate(drive.connection)
                try await drive.waitForUploads(on: drive.service)
                await app.refresh()

                #expect(desktop.notificationTitles == [String(localized: .finishedUploading(drive.connection.name))])
                try await drive.service.unmount(drive.connection)
            }
        }
    }
}

func withAppDrive(
    folder: String = "", encrypted: Bool = false,
    credentials: Credentials = s3Credentials,
    credentialStorage: MemoryCredentialStorage = MemoryCredentialStorage(),
    _ body: @MainActor @Sendable (Drive, AppViewModel, DriveDesktopServices) async throws -> Void
) async throws {
    try await withDrive(folder: folder, encrypted: encrypted) { drive in
        let repository = SavedConnectionRepository(store: ConnectionStore(url: drive.paths.config), credentials: credentialStorage)
        try repository.save(drive.connection, credentials: credentials)
        let desktop = await DriveDesktopServices(paths: drive.paths)
        let app = await AppViewModel(
            initialConnections: .success([drive.connection]), drives: drive.service,
            deleteConnection: DeleteConnectionUseCase(repository: repository, drives: drive.service),
            toggleDrive: ToggleDriveUseCase(repository: repository, drives: drive.service),
            shareFiles: ShareFilesUseCase(repository: repository, drives: drive.service),
            exportConfig: ExportRcloneConfigUseCase(repository: repository, drives: drive.service),
            quit: QuitUseCase(drives: drive.service), desktop: desktop
        )
        await app.refresh()
        try await body(drive, app, desktop)
    }
}

@MainActor final class DriveDesktopServices: DesktopServices {
    let paths: AppPaths
    var opensAtLogin = false
    var openedDrives: [UUID] = []
    var notificationTitles: [String] = []
    var rcloneConfigDestination: RcloneConfigDestination?

    init(paths: AppPaths) { self.paths = paths }

    func setOpensAtLogin(_ enabled: Bool) { opensAtLogin = enabled }
    func mountLocation(_ connection: Connection) -> URL { paths.mount(connection) }
    func openDrive(_ connection: Connection) { openedDrives.append(connection.id) }
    func openLog(_ connection: Connection) {}
    func copyShareLinks(_ links: [URL]) {}
    func chooseRcloneConfigDestination(for connection: Connection) -> RcloneConfigDestination? { rcloneConfigDestination }
    func notify(title: String, body: String, fallbackToAlert: Bool) { notificationTitles.append(title) }
}
