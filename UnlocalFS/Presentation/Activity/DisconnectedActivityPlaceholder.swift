import SwiftUI
import UnlocalFSDomain

struct DisconnectedActivityPlaceholder: View {
    let connection: Connection

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            activity
            SpeedChart(speeds: [], showsPlaceholderLine: true)
        }
    }

    private var activity: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity").font(.headline)
            ActivityTable(files: []) {
                ActivityIdle(readOnly: connection.readOnly)
            }
        }
    }
}
