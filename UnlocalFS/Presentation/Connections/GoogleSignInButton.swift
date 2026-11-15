import AppKit
import SwiftUI

struct GoogleSignInButton: View {
    let title: Text
    let signIn: () async -> Void

    var body: some View {
        Button {
            Task {
                await signIn()
                NSApp.activate()
            }
        } label: {
            Label {
                title
            } icon: {
                Image(.google).resizable().renderingMode(.original).frame(width: 16, height: 16)
            }
            .labelStyle(.titleAndIcon)
        }
    }
}
