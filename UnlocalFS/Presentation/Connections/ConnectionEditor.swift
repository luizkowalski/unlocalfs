import AppKit
import SwiftUI
import UnlocalFSDomain
import UniformTypeIdentifiers
import UnlocalFSPresentation

struct ConnectionEditor: View {
    @State private var viewModel: ConnectionEditorViewModel
    @State private var pane = Pane.connection
    @State private var importingKey = false
    @FocusState private var focus: ConnectionField?
    @Environment(\.dismiss) private var dismiss

    private enum Pane: String, CaseIterable {
        case connection = "Connection", settings = "Settings"

        var displayName: String {
            switch self {
            case .connection: String(localized: "Connection")
            case .settings: String(localized: "Settings")
            }
        }
    }

    init(viewModel: ConnectionEditorViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private static let cacheLimits: [Int64] = [128_000_000, 512_000_000, 1_000_000_000, 5_000_000_000, 10_000_000_000, 50_000_000_000]
    private static let freeSpaces: [Int64] = [1_000_000_000, 5_000_000_000, 10_000_000_000, 20_000_000_000]
    private static let bandwidthLimits: [Int64] = [1_000_000, 5_000_000, 10_000_000, 25_000_000, 50_000_000, 100_000_000]
    private static let transferCounts = [1, 2, 4, 8, 16, 32]

    var body: some View {
        let errors = viewModel.fieldErrors
        VStack(spacing: 0) {
            HStack {
                Text(viewModel.title).font(.title2.bold())
                Spacer()
                Picker("Section", selection: $pane) {
                    ForEach(Pane.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 4)
            Group {
                switch pane {
                case .connection: connectionForm(errors: errors)
                case .settings: settingsForm(errors: errors)
                }
            }
            .formStyle(.grouped)
            .frame(height: 560)
            .disabled(viewModel.isLocked)
            Divider()
            HStack {
                Button {
                    Task {
                        await viewModel.test()
                        focusFirstInvalidField()
                    }
                } label: {
                    if viewModel.testing { ProgressView().controlSize(.small) } else { Text("Test Connection") }
                }
                .disabled(viewModel.isLocked)
                if let error = viewModel.error {
                    Label(error, systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.red).font(.callout).lineLimit(1).help(error).textSelection(.enabled)
                } else if viewModel.tested {
                    Label("Connection successful", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green).font(.callout)
                }
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction).disabled(viewModel.testing || viewModel.saving)
                Button("Save") {
                    Task {
                        if await viewModel.save() { dismiss() } else { focusFirstInvalidField() }
                    }
                }.keyboardShortcut(.defaultAction).disabled(viewModel.isLocked)
            }
            .padding(20)
        }
        .frame(width: 560)
        .presentationSizing(.fitted)
        .sheet(item: Binding(get: { viewModel.serverTrust }, set: { _ in })) { challenge in
            ServerTrustSheet(challenge: challenge,
                             onTrust: { Task { await viewModel.trustServer() } },
                             onCancel: { Task { await viewModel.cancelServerTrust() } })
        }
        .onAppear {
            viewModel.loadCredentials()
            if viewModel.credentialsLoaded && viewModel.isDuplicate { focus = .folder }
        }
    }

    private func connectionForm(errors: [ConnectionField: String]) -> some View {
        @Bindable var viewModel = viewModel
        return Form {
            switch viewModel.connection.backend {
            case .s3Compatible: s3Sections(errors: errors)
            case .sftp: sftpSections(errors: errors)
            case .gcs: gcsSections(errors: errors)
            }
        }
        .fileImporter(isPresented: $importingKey, allowedContentTypes: [.json]) { result in
            Task {
                viewModel.importServiceAccountKey(await MacOSDesktopServices.readServiceAccountKey(result))
            }
        }
    }

    @ViewBuilder private func s3Sections(errors: [ConnectionField: String]) -> some View {
        @Bindable var viewModel = viewModel
        Section {
            nameField(errors: errors)
            providerPicker
            validated(.endpoint, error: errors[.endpoint]) { TextField("Endpoint", text: $viewModel.connection.endpoint, prompt: Text(verbatim: "https://s3.example.com")) }
            TextField("Region", text: $viewModel.connection.region, prompt: Text("us-east-1 or auto"))
            bucketFields(errors: errors)
        } header: {
            Text("Storage")
        } footer: {
            Text("Use the endpoint without the bucket name. For Cloudflare R2, use region auto.")
                .font(.caption).foregroundStyle(.secondary)
        }
        Section {
            validated(.accessKey, error: errors[.accessKey]) { TextField("Access key", text: $viewModel.credentials.accessKey) }
            validated(.secretKey, error: errors[.secretKey]) { SecureField("Secret key", text: $viewModel.credentials.secretKey) }
            SecureField("Session token", text: $viewModel.credentials.sessionToken, prompt: Text("Optional"))
        } header: {
            Text("Credentials")
        } footer: {
            Text("Credentials are stored in your Mac’s Keychain.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private func sftpSections(errors: [ConnectionField: String]) -> some View {
        serverSection(errors: errors)
        authenticationSection(errors: errors)
    }

    private func serverSection(errors: [ConnectionField: String]) -> some View {
        @Bindable var viewModel = viewModel
        return Section {
            nameField(errors: errors)
            providerPicker
            validated(.host, error: errors[.host]) { TextField("Host", text: $viewModel.connection.sftp.host, prompt: Text(verbatim: "files.example.com")) }
            validated(.port, error: errors[.port]) {
                TextField("Port", value: $viewModel.connection.sftp.port, format: .number.grouping(.never))
            }
            validated(.username, error: errors[.username]) { TextField("Username", text: $viewModel.connection.sftp.username) }
            validated(.remotePath, error: errors[.remotePath]) {
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

    private func authenticationSection(errors: [ConnectionField: String]) -> some View {
        @Bindable var viewModel = viewModel
        return Section {
            Picker("Sign in with", selection: $viewModel.connection.sftp.authentication) {
                ForEach(SFTPAuthentication.allCases) { Text($0.title).tag($0) }
            }
            switch viewModel.connection.sftp.authentication {
            case .password:
                validated(.password, error: errors[.password]) { SecureField("Password", text: $viewModel.credentials.password) }
            case .privateKey:
                validated(.keyFile, error: errors[.keyFile]) {
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

    private func nameField(errors: [ConnectionField: String]) -> some View {
        @Bindable var viewModel = viewModel
        return validated(.name, error: errors[.name]) { TextField("Name", text: $viewModel.connection.name, prompt: Text("My storage")) }
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

    private func settingsForm(errors: [ConnectionField: String]) -> some View {
        @Bindable var viewModel = viewModel
        return Form {
            Section("General") {
                Toggle("Read-only", isOn: $viewModel.connection.readOnly)
                Toggle("Connect on start up", isOn: $viewModel.connection.connectsAutomatically)
            }
            Section("Encryption") {
                Toggle(isOn: $viewModel.connection.encrypted) {
                    Text("Encrypt files")
                    Text(viewModel.isNew
                         ? "Files and names are encrypted before they upload. Without the password, nobody can read them, including you."
                         : "You cannot change this after you add a drive.")
                }
                .disabled(!viewModel.isNew)
                if viewModel.isNew && viewModel.connection.encrypted {
                    validated(.encryptionPassword, error: errors[.encryptionPassword]) { SecureField("Encryption password", text: $viewModel.credentials.encryptionPassword) }
                    validated(.confirmation, error: errors[.confirmation]) { SecureField("Confirm password", text: $viewModel.confirmation) }
                }
            }
            if viewModel.connection.provider == .aws { awsSection(errors: errors) }
            Section {
                Picker("Cache limit", selection: $viewModel.connection.cacheLimit) {
                    ForEach(Self.cacheLimits, id: \.self) { Text($0, format: .byteCount(style: .file)).tag($0) }
                }
                Picker("Keep free on disk", selection: $viewModel.connection.minimumFreeSpace) {
                    Text("Off").tag(Int64(0))
                    ForEach(Self.freeSpaces, id: \.self) { Text($0, format: .byteCount(style: .file)).tag($0) }
                }
            } header: {
                Text("Cache")
            } footer: {
                Text("Files you have not opened for the longest time are removed first. Open files and pending uploads stay, so the cache can go over the limit.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            advancedSection
        }
    }

    private var advancedSection: some View {
        @Bindable var viewModel = viewModel
        return Section {
            Picker("Bandwidth limit", selection: $viewModel.connection.bandwidthLimit) {
                Text("Off").tag(Int64(0))
                ForEach(Self.bandwidthLimits, id: \.self) { limit in
                    Text("\(limit, format: .byteCount(style: .file))/s").tag(limit)
                }
            }
            Picker("Parallel transfers", selection: $viewModel.connection.transfers) {
                ForEach(Self.transferCounts, id: \.self) { count in
                    Text("\(count)").tag(count)
                }
            }
        } header: {
            Text("Advanced")
        } footer: {
            Text("Bandwidth limits uploads and downloads. Parallel transfers controls how many files can move at once.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func validated(_ field: ConnectionField, error: String?, @ViewBuilder input: () -> some View) -> some View {
        LabeledContent {
            VStack(alignment: .trailing, spacing: 4) {
                input()
                    .labelsHidden()
                    .focused($focus, equals: field)
                if let error {
                    Label(error, systemImage: "exclamationmark.circle.fill")
                        .font(.caption).foregroundStyle(.red).multilineTextAlignment(.trailing)
                }
            }
        } label: {
            Text(field.displayName).foregroundStyle(error == nil ? Color.primary : Color.red)
        }
    }

    private func focusFirstInvalidField() {
        guard let field = viewModel.firstInvalidField else { return }
        pane = [.encryptionPassword, .confirmation, .kmsKey].contains(field) ? .settings : .connection
        focus = field
    }
}

private extension ConnectionEditor {
    func awsSection(errors: [ConnectionField: String]) -> some View {
        @Bindable var viewModel = viewModel
        return Section {
            Picker("Storage class", selection: $viewModel.connection.aws.storageClass) {
                ForEach(S3StorageClass.allCases) { Text($0.title).tag($0) }
            }
            Picker("Server-side encryption", selection: $viewModel.connection.aws.serverSideEncryption) {
                Text("Bucket default").tag(ServerSideEncryption?.none)
                ForEach(ServerSideEncryption.allCases) { Text($0.title).tag(Optional($0)) }
            }
            if viewModel.connection.aws.serverSideEncryption == .kms {
                validated(.kmsKey, error: errors[.kmsKey]) {
                    TextField("KMS key", text: $viewModel.connection.aws.kmsKeyID, prompt: Text("Optional: key ID, alias, or ARN"))
                }
            }
        } header: {
            Text("Amazon S3")
        } footer: {
            Text("Applies to new uploads. Infrequent-access classes bill a minimum size and storage time. AWS can read files it encrypts; Encrypt files keeps them private.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder func bucketFields(errors: [ConnectionField: String]) -> some View {
        @Bindable var viewModel = viewModel
        validated(.bucket, error: errors[.bucket]) { TextField("Bucket", text: $viewModel.connection.bucket, prompt: Text("my-bucket")) }
        validated(.folder, error: errors[.folder]) { TextField("Folder", text: $viewModel.connection.folder, prompt: Text("Optional, for example clients/acme")) }
    }

    @ViewBuilder func gcsSections(errors: [ConnectionField: String]) -> some View {
        @Bindable var viewModel = viewModel
        Section {
            nameField(errors: errors)
            providerPicker
            bucketFields(errors: errors)
        } header: {
            Text("Storage")
        }
        Section {
            validated(.serviceAccountKey, error: errors[.serviceAccountKey]) {
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

    var providerPicker: some View {
        @Bindable var viewModel = viewModel
        let providers = viewModel.availableProviders
        return Picker("Provider", selection: $viewModel.connection.provider) {
            Section { providerOptions(providers.filter { !$0.isGeneric }) }
            Section { providerOptions(providers.filter(\.isGeneric)) }
        }
    }

    func providerOptions(_ providers: [Provider]) -> some View {
        ForEach(providers) { provider in
            Label { Text(provider.title) } icon: { provider.logo.renderingMode(.template) }.tag(provider)
        }
    }
}
