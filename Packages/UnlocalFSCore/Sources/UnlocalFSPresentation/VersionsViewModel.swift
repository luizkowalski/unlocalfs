import Foundation
import Observation
import UnlocalFSDomain

@MainActor @Observable public final class VersionsViewModel {
    public let target: VersionsTarget
    public private(set) var versions: [FileVersion] = []
    private var versioning: BucketVersioning?
    public private(set) var loading = false
    public private(set) var working: FileVersion.ID?
    public private(set) var message: String?
    public var preview: URL?

    private let fileVersions: FileVersionsUseCase
    @ObservationIgnored private var download: Task<Void, Never>?
    @ObservationIgnored private var previews: [URL] = []

    public init(target: VersionsTarget, fileVersions: FileVersionsUseCase) {
        self.target = target
        self.fileVersions = fileVersions
    }

    public var title: String {
        target.isFolder ? String(localized: .recentlyDeletedIn(target.name)) : String(localized: .versionsOf(target.name))
    }

    public var notice: String? {
        switch versioning {
        case .off: String(localized: .versioningOff)
        case .suspended: String(localized: .versioningSuspended)
        case .enabled, .unknown, nil: nil
        }
    }

    public var emptyText: String {
        target.isFolder ? String(localized: .noDeletedFiles) : String(localized: .noEarlierVersions)
    }

    public func canRestore(_ version: FileVersion) -> Bool {
        target.connection.versionRestoreRefusal == nil && !version.isCurrent && working == nil
    }

    public func load() async {
        loading = true
        defer { loading = false }
        do {
            let loaded = try await fileVersions.load(target)
            try Task.checkCancellation()
            versioning = loaded.versioning
            versions = loaded.versions
            message = nil
        } catch {
            if !Task.isCancelled { message = error.localizedDescription }
        }
    }

    public func open(_ version: FileVersion) {
        download = run(version) { [self] in
            let file = try await fileVersions.preview(version, in: target.connection)
            previews.append(file)
            preview = file
        }
    }

    public func restore(_ version: FileVersion, asCopy: Bool) {
        run(version) { [self] in
            _ = try await fileVersions.restore(version, asCopy: asCopy, in: target.connection)
            await load()
        }
    }

    public func close() {
        download?.cancel()
        previews.forEach(fileVersions.discardPreview)
        previews = []
    }

    @discardableResult
    private func run(_ version: FileVersion, _ body: @escaping () async throws -> Void) -> Task<Void, Never> {
        working = version.id
        message = nil
        return Task {
            do {
                try await body()
            } catch {
                if !Task.isCancelled { message = error.localizedDescription }
            }
            working = nil
        }
    }
}
