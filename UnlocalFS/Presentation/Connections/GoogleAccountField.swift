import SwiftUI
import UnlocalFSDomain
import UnlocalFSPresentation

struct GoogleAccountField: View {
    let viewModel: ConnectionEditorViewModel
    let errors: [ConnectionField: String]
    let focus: FocusState<ConnectionField?>.Binding

    var body: some View {
        ConnectionEditorField(field: .googleAccount, error: errors[.googleAccount], focus: focus) {
            HStack {
                if viewModel.credentials.isSignedInToGoogle {
                    Text("Google account connected")
                    GoogleSignInButton(title: Text("Sign In Again…"), signIn: viewModel.signInWithGoogle)
                } else {
                    GoogleSignInButton(title: Text("Sign in with Google"), signIn: viewModel.signInWithGoogle)
                }
            }
        }
    }
}
