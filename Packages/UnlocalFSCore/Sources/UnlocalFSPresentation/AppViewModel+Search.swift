import Foundation
import UnlocalFSDomain

extension AppViewModel {
    public var visibleConnections: [Connection] {
        searchQuery.isEmpty ? connections : connections.filter { $0.name.localizedStandardContains(searchQuery) }
    }

    public func openSearch() {
        isSearching = true
        searchFocusRequest += 1
    }

    public func closeSearch() {
        searchQuery = ""
        isSearching = false
    }

    public func closeSearchIfEmpty() {
        if searchQuery.isEmpty { isSearching = false }
    }

    public func submitSearch() {
        guard let first = visibleConnections.first else { return }
        if case .drive(let id) = selection, visibleConnections.contains(where: { $0.id == id }) { return }
        selection = .drive(first.id)
    }
}
