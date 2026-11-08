import Foundation
import UnlocalFSDomain

enum DriveCondition: Equatable, Sendable {
    case checking
    case working
    case needsReconnect
    case needsAttention
    case offline
    case uploadFailed
    case uploading(count: Int, isMounted: Bool)
    case connected
    case ejected
    case disconnected

    init(_ status: MountStatus?, busy: Bool, hasError: Bool, offline: Bool) {
        if busy {
            self = .working
            return
        }
        if status?.needsReconnect == true {
            self = .needsReconnect
            return
        }
        if hasError {
            self = .needsAttention
            return
        }
        guard let status else {
            self = .checking
            return
        }
        if offline {
            self = .offline
            return
        }
        if status.failedUploads > 0 {
            self = .uploadFailed
            return
        }
        if status.pendingUploads > 0 {
            self = .uploading(count: status.pendingUploads, isMounted: status.isMounted)
            return
        }
        if status.isMounted {
            self = .connected
            return
        }
        if status.isRunning {
            self = .ejected
            return
        }
        self = .disconnected
    }

    var statusText: String {
        switch self {
        case .working: String(localized: .working)
        case .needsReconnect: String(localized: .needsReconnect)
        case .needsAttention: String(localized: .needsAttention)
        case .checking: String(localized: .checking)
        case .offline: String(localized: .networkUnavailable)
        case .uploadFailed: String(localized: .uploadNeedsAttention)
        case let .uploading(count, _): String(localized: .uploadsPending(count))
        case .connected: String(localized: .connected)
        case .ejected: String(localized: .ejected)
        case .disconnected: String(localized: .disconnected)
        }
    }

    var indicator: AppViewModel.Indicator {
        switch self {
        case .working: .working
        case .needsReconnect, .needsAttention, .offline, .uploadFailed: .attention
        case .connected: .connected
        case let .uploading(_, isMounted): isMounted ? .connected : .idle
        case .checking, .ejected, .disconnected: .idle
        }
    }
}
