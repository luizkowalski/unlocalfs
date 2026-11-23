import Foundation
import Observation
import UnlocalFSDomain

@MainActor @Observable public final class VersionsViewModel {
    public let connection: Connection
    public let path: String
    public let isFolder: Bool
    public private(set) var versions: [FileVersion] = []
    public private(set) var versioning: BucketVersioning?
    public private(set) var loading = false
    public private(set) var working: FileVersion.ID?
    public private(set) var message: String?
    public var preview: URL?

    private let fileVersions: FileVersionsUseCase
    private let drives: any DriveGateway
    private let onVersioning: (BucketVersioning) -> Void
    @ObservationIgnored private var work: Task<Void, Never>?
    @ObservationIgnored private var previews: [URL] = []

    init(
        connection: Connection, path: String, isFolder: Bool, fileVersions: FileVersionsUseCase, drives: any DriveGateway,
        onVersioning: @escaping (BucketVersioning) -> Void,
    ) {
        self.connection = connection
        self.path = path
        self.isFolder = isFolder
        self.fileVersions = fileVersions
        self.drives = drives
        self.onVersioning = onVersioning
    }

    public var id: String { "\(connection.id.uuidString)/\(path)" }

    public var title: String {
        let name = path.isEmpty ? connection.name : (path as NSString).lastPathComponent
        return isFolder ? String(localized: .recentlyDeletedIn(name)) : String(localized: .versionsOf(name))
    }

    public var notice: String? {
        switch versioning {
        case .off: String(localized: .versioningOff)
        case .suspended: String(localized: .versioningSuspended)
        case .enabled, .unknown, nil: nil
        }
    }

    public var emptyText: String {
        isFolder ? String(localized: .noDeletedFiles) : String(localized: .noEarlierVersions)
    }

    public func canRestore(_ version: FileVersion) -> Bool {
        connection.serverCopyRefusal == nil && !version.isCurrent && working == nil
    }

    public func load() async {
        loading = true
        defer { loading = false }
        do {
            let loaded = try await fileVersions.load(path, isFolder: isFolder, in: connection)
            versioning = loaded.versioning
            versions = loaded.versions
            message = nil
            onVersioning(loaded.versioning)
        } catch is CancellationError {
        } catch {
            message = error.localizedDescription
        }
    }

    public func open(_ version: FileVersion) {
        run(version) { [self] in
            let file = try await drives.preview(version, in: connection)
            previews.append(file)
            preview = file
        }
    }

    public func restore(_ version: FileVersion, asCopy: Bool) {
        run(version) { [self] in
            _ = try await fileVersions.restore(version, asCopy: asCopy, in: connection)
            await load()
        }
    }

    public func close() {
        work?.cancel()
        previews.forEach(drives.discardPreview)
        previews = []
    }

    private func run(_ version: FileVersion, _ body: @escaping () async throws -> Void) {
        working = version.id
        message = nil
        work = Task {
            do {
                try await body()
            } catch is CancellationError {
            } catch {
                message = error.localizedDescription
            }
            working = nil
        }
    }
}
