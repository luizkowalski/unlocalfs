import SwiftUI
import UnlocalFSDomain
import UnlocalFSPresentation

struct ConnectionIdentityFields: View {
    @Bindable var viewModel: ConnectionEditorViewModel
    let errors: [ConnectionField: String]
    let focus: FocusState<ConnectionField?>.Binding

    var body: some View {
        ConnectionEditorField(field: .name, error: errors[.name], focus: focus) {
            TextField("Name", text: $viewModel.connection.name, prompt: Text("My storage"))
        }
        providerPicker
    }

    private var providerPicker: some View {
        let providers = viewModel.availableProviders
        return Picker("Provider", selection: $viewModel.connection.provider) {
            Section { providerOptions(providers.filter { !$0.isGeneric }) }
            Section { providerOptions(providers.filter(\.isGeneric)) }
        }
    }

    private func providerOptions(_ providers: [Provider]) -> some View {
        ForEach(providers) { provider in
            Label { Text(provider.title) } icon: { provider.logo.renderingMode(.template) }.tag(provider)
        }
    }
}
