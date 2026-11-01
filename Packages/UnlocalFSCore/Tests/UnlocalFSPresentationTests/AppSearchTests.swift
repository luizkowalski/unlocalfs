import Foundation
import Testing
import UnlocalFSDomain
import UnlocalFSPresentation
import UnlocalFSTestSupport

@MainActor @Suite final class AppSearchTests {
    let fixture: ViewModelFixture

    init() throws { fixture = try ViewModelFixture() }

    deinit { fixture.remove() }

    private func appWithUnlocals() throws -> AppViewModel {
        for name in ["Backups", "Homelab", "Homelab Media", "Café"] {
            try fixture.repository.save(Connection.s3(name: name), credentials: Credentials())
        }
        return fixture.app()
    }

    @Test func queryFiltersUnlocalsByNameIgnoringCaseAndAccents() throws {
        let app = try appWithUnlocals()
        app.openSearch()

        let expectations = [
            ("homelab", ["Homelab", "Homelab Media"]),
            ("CAFE", ["Café"]),
            ("", ["Backups", "Café", "Homelab", "Homelab Media"]),
            ("zzz", []),
        ]
        for (query, names) in expectations {
            app.searchQuery = query
            #expect(app.visibleConnections.map(\.name) == names, "query “\(query)”")
        }
    }

    @Test func fieldClosesOnEscOrWhenEmptyAndUnfocused() throws {
        let app = try appWithUnlocals()

        app.openSearch()
        app.searchQuery = "ho"
        app.closeSearchIfEmpty()
        #expect(app.isSearching)

        app.searchQuery = ""
        #expect(app.isSearching)
        app.closeSearchIfEmpty()
        #expect(!app.isSearching)

        app.openSearch()
        app.searchQuery = "ho"
        app.closeSearch()
        #expect(!app.isSearching)
        #expect(app.searchQuery.isEmpty)
    }

    @Test func submittingSelectsTheFirstMatchUnlessAMatchIsAlreadySelected() throws {
        let app = try appWithUnlocals()
        let backups = try #require(app.connections.first { $0.name == "Backups" })
        let media = try #require(app.connections.first { $0.name == "Homelab Media" })
        app.openSearch()
        app.searchQuery = "homelab"

        app.selection = .drive(backups.id)
        app.submitSearch()
        #expect(app.selected?.name == "Homelab")

        app.selection = .drive(media.id)
        app.submitSearch()
        #expect(app.selected == media)

        app.selection = .traffic
        app.submitSearch()
        #expect(app.selected?.name == "Homelab")

        app.searchQuery = "zzz"
        app.selection = .drive(backups.id)
        app.submitSearch()
        #expect(app.selected == backups)
    }

    @Test func connectingClosesTheSearchOnlyOnceTheDriveCanConnect() async throws {
        let first = Connection.s3(name: "First")
        let second = Connection.s3(name: "Second")
        for connection in [first, second] { try fixture.repository.save(connection, credentials: Credentials.s3()) }
        try "Connection failed".write(to: fixture.root.appending(path: "test-error"), atomically: true, encoding: .utf8)
        let app = fixture.app()

        app.openSearch()
        app.searchQuery = "fir"
        await app.toggle(first)

        #expect(app.isSearching)
        #expect(app.searchQuery == "fir")

        await app.refresh()
        await app.activate(first)

        #expect(!app.isSearching)
        #expect(app.searchQuery.isEmpty)
        #expect(app.selected == first)

        app.openSearch()
        app.searchQuery = "sec"
        await app.toggle(second)

        #expect(!app.isSearching)
        #expect(app.searchQuery.isEmpty)
    }
}
