import SwiftUI

struct GoogleSignInLabel: View {
    let title: Text

    var body: some View {
        Label {
            title
        } icon: {
            Image(.google).resizable().renderingMode(.original).frame(width: 16, height: 16)
        }
        .labelStyle(.titleAndIcon)
    }
}
