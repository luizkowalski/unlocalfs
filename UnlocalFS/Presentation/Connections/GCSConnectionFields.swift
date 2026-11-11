import AppKit
import SwiftUI
import UniformTypeIdentifiers
import UnlocalFSDomain
import UnlocalFSPresentation

struct GCSConnectionFields: View {
    @Bindable var viewModel: ConnectionEditorViewModel
    let errors: [ConnectionField: String]
    let focus: FocusState<ConnectionField?>.Binding
    @State private var importingKey = false

    var body: some View {
        Form {
            Section {
                ConnectionIdentityFields(viewModel: viewModel, errors: errors, focus: focus)
                ConnectionBucketFields(viewModel: viewModel, errors: errors, focus: focus)
            } header: {
                Text("Storage")
            }
            Section {
                Picker("Sign in with", selection: $viewModel.connection.gcs.authentication) {
                    ForEach(GCSAuthentication.allCases) { Text($0.title).tag($0) }
                }
                switch viewModel.connection.gcs.authentication {
                case .googleAccount: googleAccountField
                case .serviceAccount: serviceAccountField
                }
            } header: {
                Text("Credentials")
            } footer: {
                Group {
                    switch viewModel.connection.gcs.authentication {
                    case .googleAccount:
                        Text("The sign-in is stored in your Mac’s Keychain. Your Google account needs the Storage Object User role on the bucket.")
                    case .serviceAccount:
                        Text("The key is stored in your Mac’s Keychain. Give its service account the Storage Object User role on the bucket.")
                    }
                }
                .font(.caption).foregroundStyle(.secondary)
            }
        }
        .fileImporter(isPresented: $importingKey, allowedContentTypes: [.json]) { result in
            Task {
                await viewModel.importServiceAccountKey(result)
            }
        }
    }

    private var googleAccountField: some View {
        ConnectionEditorField(field: .googleAccount, error: errors[.googleAccount], focus: focus) {
            HStack {
                if viewModel.credentials.isSignedInToGoogle {
                    Text("Google account connected")
                    Button("Sign In Again…", action: signIn)
                } else {
                    Button("Sign in with Google", action: signIn)
                }
            }
        }
    }

    private var serviceAccountField: some View {
        ConnectionEditorField(field: .serviceAccountKey, error: errors[.serviceAccountKey], focus: focus) {
            let email = viewModel.credentials.serviceAccountEmail
            HStack {
                if let email {
                    Text(verbatim: email).lineLimit(1).truncationMode(.middle).textSelection(.enabled)
                }
                Button(email == nil ? "Import key…" : "Replace…") { importingKey = true }
            }
        }
    }

    private func signIn() {
        Task {
            await viewModel.signInWithGoogle()
            NSApp.activate()
        }
    }
}
