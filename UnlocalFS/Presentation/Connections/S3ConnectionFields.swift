import SwiftUI
import UnlocalFSDomain
import UnlocalFSPresentation

struct S3ConnectionFields: View {
    @Bindable var viewModel: ConnectionEditorViewModel
    let errors: [ConnectionField: String]
    let focus: FocusState<ConnectionField?>.Binding

    var body: some View {
        Form {
            Section {
                ConnectionIdentityFields(viewModel: viewModel, errors: errors, focus: focus)
                ConnectionEditorField(field: .endpoint, error: errors[.endpoint], focus: focus) {
                    TextField("Endpoint", text: $viewModel.connection.endpoint, prompt: Text(verbatim: "https://s3.example.com"))
                }
                TextField("Region", text: $viewModel.connection.region, prompt: Text("us-east-1 or auto"))
                ConnectionBucketFields(viewModel: viewModel, errors: errors, focus: focus)
            } header: {
                Text("Storage")
            } footer: {
                Text("Use the endpoint without the bucket name. For Cloudflare R2, use region auto.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section {
                ConnectionEditorField(field: .accessKey, error: errors[.accessKey], focus: focus) { TextField("Access key", text: $viewModel.credentials.accessKey) }
                ConnectionEditorField(field: .secretKey, error: errors[.secretKey], focus: focus) { SecureField("Secret key", text: $viewModel.credentials.secretKey) }
                SecureField("Session token", text: $viewModel.credentials.sessionToken, prompt: Text("Optional"))
            } header: {
                Text("Credentials")
            } footer: {
                Text("Credentials are stored in your Mac’s Keychain.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
