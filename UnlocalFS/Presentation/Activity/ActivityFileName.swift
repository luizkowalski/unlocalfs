import AppKit
import SwiftUI
import UniformTypeIdentifiers
import UnlocalFSDomain
import UnlocalFSPresentation

struct ActivityFileName: View {
    let activity: FileActivity

    var body: some View {
        HStack(spacing: 7) {
            Image(nsImage: NSWorkspace.shared.icon(for: UTType(filenameExtension: (activity.name as NSString).pathExtension) ?? .data))
                .resizable()
                .frame(width: 16, height: 16)
                .accessibilityHidden(true)
            Text(activity.name).truncationMode(.middle).textSelection(.enabled)
        }
        .help(activity.path)
    }
}
