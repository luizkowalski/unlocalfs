import SwiftUI
import UnlocalFSDomain
import UnlocalFSPresentation

struct GoogleDriveConnectionFields: View {
    @Bindable var viewModel: ConnectionEditorViewModel
    let errors: [ConnectionField: String]
    let focus: FocusState<ConnectionField?>.Binding

    var body: some View {
        Form {
            Section {
                ConnectionIdentityFields(viewModel: viewModel, errors: errors, focus: focus)
                ConnectionEditorField(field: .folder, error: errors[.folder], focus: focus) {
                    TextField("Folder", text: $viewModel.connection.folder, prompt: Text("Optional, for example UnlocalFS"))
                }
            } header: {
                Text("Storage")
            } footer: {
                Text("The drive shows only files and folders that UnlocalFS made. Files that you already have in Google Drive do not show.")
            }
            Section {
                GoogleAccountField(viewModel: viewModel, errors: errors, focus: focus)
            } header: {
                Text("Credentials")
            } footer: {
                Text("The sign-in is stored in your Mac’s Keychain. Deleted files go to the Google Drive trash.")
            }
        }
    }
}
