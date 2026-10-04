import SwiftUI
import UnlocalFSPresentation

struct SettingsView: View {
    @Environment(AppViewModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Form {
            Section {
                Toggle("Open at Login", isOn: Binding(
                    get: { model.opensAtLogin },
                    set: { model.setOpensAtLogin($0) }
                ))
            }
            Section {
                Picker("Language", selection: Binding(
                    get: { model.appLanguage },
                    set: { model.setAppLanguage($0) }
                )) {
                    Text("System").tag(AppLanguage.system)
                    Text("English").tag(AppLanguage.english)
                    Text("Português (Brasil)").tag(AppLanguage.portuguese)
                }
            } footer: {
                Text("Language changes take effect the next time you open UnlocalFS.")
            }
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
