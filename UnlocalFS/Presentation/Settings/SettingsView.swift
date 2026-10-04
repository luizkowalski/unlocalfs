import SwiftUI
import UnlocalFSPresentation

struct SettingsView: View {
    @Environment(AppViewModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Form {
            Toggle("Open at Login", isOn: Binding(
                get: { model.opensAtLogin },
                set: { model.setOpensAtLogin($0) }
            ))
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .alert("UnlocalFS", isPresented: $model.isShowingAlert, presenting: model.alert) { _ in
            Button("OK", role: .cancel) {}
        } message: {
            Text($0)
        }
    }
}
