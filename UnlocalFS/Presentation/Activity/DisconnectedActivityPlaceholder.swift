import SwiftUI

struct DisconnectedActivityPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Activity").font(.headline)
                ActivityTable(files: []) { ActivityIdle(title: "All changes are uploaded") }
            }
            SpeedChart(speeds: [])
        }
    }
}
