import AppKit
import SwiftUI
import UnlocalFSDomain
import UnlocalFSPresentation

struct SFTPConnectionFields: View {
    @Bindable var viewModel: ConnectionEditorViewModel
    let errors: [ConnectionField: String]
    let focus: FocusState<ConnectionField?>.Binding

    var body: some View {
        Form {
            serverSection
            authenticationSection
        }
    }

    private var serverSection: some View {
        Section {
            ConnectionIdentityFields(viewModel: viewModel, errors: errors, focus: focus)
            ConnectionEditorField(field: .host, error: errors[.host], focus: focus) {
                TextField("Host", text: $viewModel.connection.sftp.host, prompt: Text(verbatim: "files.example.com"))
            }
            ConnectionEditorField(field: .port, error: errors[.port], focus: focus) {
                TextField("Port", value: $viewModel.connection.sftp.port, format: .number.grouping(.never))
            }
            ConnectionEditorField(field: .username, error: errors[.username], focus: focus) { TextField("Username", text: $viewModel.connection.sftp.username) }
            ConnectionEditorField(field: .remotePath, error: errors[.remotePath], focus: focus) {
                TextField("Remote folder", text: $viewModel.connection.sftp.remotePath, prompt: Text("Optional, for example /srv/files"))
            }
            .disabled(viewModel.locksRemoteFolder)
        } header: {
            Text("Server")
        } footer: {
            Text(viewModel.locksRemoteFolder
                 ? "To use a different folder, duplicate this drive."
                 : "Leave the folder empty for your home folder. Start it with / for a path from the server’s root.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var authenticationSection: some View {
        Section {
            Picker("Sign in with", selection: $viewModel.connection.sftp.authentication) {
                ForEach(SFTPAuthentication.allCases) { Text($0.title).tag($0) }
            }
            switch viewModel.connection.sftp.authentication {
            case .password:
                ConnectionEditorField(field: .password, error: errors[.password], focus: focus) { SecureField("Password", text: $viewModel.credentials.password) }
            case .privateKey:
                ConnectionEditorField(field: .keyFile, error: errors[.keyFile], focus: focus) {
                    fileChooser(String(localized: "Private key"), path: $viewModel.connection.sftp.keyFile, prompt: "~/.ssh/id_ed25519")
                }
                SecureField("Passphrase", text: $viewModel.credentials.keyPassphrase, prompt: Text("If the key has one"))
            case .agent:
                TextField("Agent socket", text: $viewModel.connection.sftp.agentSocket, prompt: Text("Optional, uses your Mac’s agent"))
            }
        } header: {
            Text("Authentication")
        } footer: {
            Text(authenticationHelp).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var authenticationHelp: LocalizedStringKey {
        switch viewModel.connection.sftp.authentication {
        case .password: "Your password is stored in your Mac’s Keychain."
        case .privateKey: "The key file stays where it is. A passphrase is stored in your Mac’s Keychain."
        case .agent: "Uses a key loaded in your ssh-agent. Nothing is stored for this option."
        }
    }

    private func fileChooser(_ title: String, path: Binding<String>, prompt: String) -> some View {
        HStack {
            TextField(title, text: path, prompt: Text(verbatim: prompt))
            Button("Choose…") {
                if let chosen = Self.chooseFile(title: title, current: path.wrappedValue) { path.wrappedValue = chosen }
            }
        }
    }

    private static func chooseFile(title: String, current: String) -> String? {
        let panel = NSOpenPanel()
        panel.title = title
        panel.showsHiddenFiles = true
        panel.canChooseDirectories = false
        panel.directoryURL = URL(filePath: NSString(string: current).expandingTildeInPath).deletingLastPathComponent()
        return panel.runModal() == .OK ? panel.url?.path : nil
    }
}
