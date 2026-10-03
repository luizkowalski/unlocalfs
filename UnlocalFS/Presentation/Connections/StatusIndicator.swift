import SwiftUI
import UnlocalFSPresentation

struct StatusIndicator: View {
    @Environment(\.backgroundProminence) private var prominence
    let indicator: AppViewModel.Indicator
    var showsIdle = true

    var body: some View {
        switch indicator {
        case .working: ProgressView().controlSize(.mini)
        case .attention: dot(.orange)
        case .connected: dot(.green)
        case .idle: if showsIdle { dot(.secondary) }
        }
    }

    private func dot(_ color: Color) -> some View {
        Circle()
            .fill(prominence == .increased ? Color.white : color)
            .frame(width: 7, height: 7)
    }
}
