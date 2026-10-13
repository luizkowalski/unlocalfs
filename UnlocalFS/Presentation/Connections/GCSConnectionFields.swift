import UniformTypeIdentifiers
import SwiftUI
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
                ConnectionEditorField(field: .serviceAccountKey, error: errors[.serviceAccountKey], focus: focus) {
                    let email = viewModel.credentials.serviceAccountEmail
                    HStack {
                        if let email {
                            Text(verbatim: email).lineLimit(1).truncationMode(.middle).textSelection(.enabled)
                        }
                        Button(email == nil ? "Import key…" : "Replace…") { importingKey = true }
                    }
                }
            } header: {
                Text("Credentials")
            } footer: {
                Text("The key is stored in your Mac’s Keychain. Give its service account the Storage Object User role on the bucket.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .fileImporter(isPresented: $importingKey, allowedContentTypes: [.json]) { result in
            Task {
                viewModel.importServiceAccountKey(await MacOSDesktopServices.readServiceAccountKey(result))
            }
        }
    }
}
