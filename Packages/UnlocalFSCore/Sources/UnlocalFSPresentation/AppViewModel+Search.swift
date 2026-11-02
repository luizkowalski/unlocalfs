import Foundation
import UnlocalFSDomain

public extension AppViewModel {
    var visibleConnections: [Connection] {
        searchQuery.isEmpty ? connections : connections.filter { $0.name.localizedStandardContains(searchQuery) }
    }

    func openSearch() {
        isSearching = true
        searchFocusRequest += 1
    }

    func closeSearch() {
        searchQuery = ""
        isSearching = false
    }

    func closeSearchIfEmpty() {
        if searchQuery.isEmpty { isSearching = false }
    }

    func submitSearch() {
        guard let first = visibleConnections.first else { return }
        if case let .drive(id) = selection, visibleConnections.contains(where: { $0.id == id }) { return }
        selection = .drive(first.id)
    }
}
