import SwiftUI
import UnlocalFSDomain
import UnlocalFSPresentation

struct ConnectionBucketFields: View {
    @Bindable var viewModel: ConnectionEditorViewModel
    let errors: [ConnectionField: String]
    let focus: FocusState<ConnectionField?>.Binding

    var body: some View {
        ConnectionEditorField(field: .bucket, error: errors[.bucket], focus: focus) { TextField("Bucket", text: $viewModel.connection.bucket, prompt: Text("my-bucket")) }
        ConnectionEditorField(field: .folder, error: errors[.folder], focus: focus) {
            TextField("Folder", text: $viewModel.connection.folder, prompt: Text("Optional, for example clients/acme"))
        }
    }
}
