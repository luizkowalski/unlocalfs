import AppKit
import SwiftUI
import UniformTypeIdentifiers
import UnlocalFSDomain

struct ActivityFileName: View {
    let activity: FileActivity

    var body: some View {
        HStack(spacing: 7) {
            Image(nsImage: NSWorkspace.shared.icon(for: UTType(filenameExtension: (name as NSString).pathExtension) ?? .data))
                .resizable()
                .frame(width: 16, height: 16)
                .accessibilityHidden(true)
            Text(name).truncationMode(.middle).textSelection(.enabled)
        }
        .help(activity.path)
    }

    private var name: String { (activity.path as NSString).lastPathComponent }
}
