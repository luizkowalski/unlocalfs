import SwiftUI
import UnlocalFSCore

struct ConnectionEditor: View {
    @Environment(AppModel.self) private var model
    @State private var connection: Connection
    private let credentialsSource: UUID
    private let isDuplicate: Bool
    @State private var credentials = Credentials()
    @State private var confirmation = ""
    @State private var credentialsLoaded = false
    @State private var testing = false
    @State private var saving = false
    @State private var tested = false
    @State private var error: String?
    @State private var showErrors = false
    @State private var pane = Pane.connection
    @FocusState private var focus: Field?
    @Environment(\.dismiss) private var dismiss

    private enum Pane: String, CaseIterable {
        case connection = "Connection", settings = "Settings"
    }

    private enum Field: String, CaseIterable {
        case name = "Name", endpoint = "Endpoint", bucket = "Bucket", folder = "Folder", accessKey = "Access key", secretKey = "Secret key"
        case encryptionPassword = "Encryption password", confirmation = "Confirm password"

        var pane: Pane {
            switch self {
            case .encryptionPassword, .confirmation: .settings
            default: .connection
            }
        }
    }

    init(draft: AppModel.Draft) {
        _connection = State(initialValue: draft.connection)
        credentialsSource = draft.credentialsSource
        isDuplicate = draft.isDuplicate
    }

    private static let cacheLimits: [Int64] = [128_000_000, 512_000_000, 1_000_000_000, 5_000_000_000, 10_000_000_000, 50_000_000_000]
    private static let freeSpaces: [Int64] = [1_000_000_000, 5_000_000_000, 10_000_000_000, 20_000_000_000]
    private static let bandwidthLimits: [Int64] = [1_000_000, 5_000_000, 10_000_000, 25_000_000, 50_000_000, 100_000_000]
    private static let transferCounts = [1, 2, 4, 8, 16, 32]

    private var isNew: Bool { !model.connections.contains { $0.id == connection.id } }
    private var title: String {
        if isDuplicate { return "Duplicate connection" }
        return isNew ? "Add connection" : "Edit connection"
    }
    private var isLocked: Bool { testing || saving || !credentialsLoaded }
    private var testInputs: [String] { [connection.provider.rawValue, connection.endpoint, connection.region, connection.bucket, connection.folder, String(connection.encrypted)] }
    private var fieldErrors: [Field: String] {
        guard showErrors else { return [:] }
        var errors: [Field: String] = [:]
        for error in connection.validate(against: model.connections) + credentials.validate(for: connection) {
            if let field = Field(rawValue: error.field), errors[field] == nil { errors[field] = error.localizedDescription }
        }
        if isNew, connection.encrypted, confirmation != credentials.encryptionPassword { errors[.confirmation] = "The passwords do not match." }
        return errors
    }

    var body: some View {
        let errors = fieldErrors
        VStack(spacing: 0) {
            HStack {
                Text(title).font(.title2.bold())
                Spacer()
                Picker("Section", selection: $pane) {
                    ForEach(Pane.allCases, id: \.self) { Text($0.rawValue).tag($0) }
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
            .disabled(isLocked)
            Divider()
            HStack {
                Button { Task { await test() } } label: {
                    if testing { ProgressView().controlSize(.small) } else { Text("Test Connection") }
                }
                .disabled(isLocked)
                if let error {
                    Label(error, systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.red).font(.callout).lineLimit(1).help(error).textSelection(.enabled)
                } else if tested {
                    Label("Connection successful", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green).font(.callout)
                }
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction).disabled(testing || saving)
                Button("Save") { Task { await save() } }.keyboardShortcut(.defaultAction).disabled(isLocked)
            }
            .padding(20)
        }
        .frame(width: 560)
        .presentationSizing(.fitted)
        .onAppear(perform: loadCredentials)
        .onChange(of: testInputs) { tested = false }
        .onChange(of: credentials) { tested = false }
    }

    private func connectionForm(errors: [Field: String]) -> some View {
        Form {
            Section {
                validated(.name, error: errors[.name]) { TextField("Name", text: $connection.name, prompt: Text("My storage")) }
                Picker("Provider", selection: $connection.provider) {
                    ForEach(Provider.allCases) { provider in
                        Label { Text(provider.title) } icon: { provider.logo }.tag(provider)
                    }
                }
                validated(.endpoint, error: errors[.endpoint]) { TextField("Endpoint", text: $connection.endpoint, prompt: Text(verbatim: "https://s3.example.com")) }
                TextField("Region", text: $connection.region, prompt: Text("us-east-1 or auto"))
                validated(.bucket, error: errors[.bucket]) { TextField("Bucket", text: $connection.bucket, prompt: Text("my-bucket")) }
                validated(.folder, error: errors[.folder]) { TextField("Folder", text: $connection.folder, prompt: Text("Optional, for example clients/acme")) }
            } header: {
                Text("Storage")
            } footer: {
                Text("Use the endpoint without the bucket name. For Cloudflare R2, use region auto.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section {
                validated(.accessKey, error: errors[.accessKey]) { TextField("Access key", text: $credentials.accessKey) }
                validated(.secretKey, error: errors[.secretKey]) { SecureField("Secret key", text: $credentials.secretKey) }
                SecureField("Session token", text: $credentials.sessionToken, prompt: Text("Optional"))
            } header: {
                Text("Credentials")
            } footer: {
                Text("Credentials are stored in your Mac’s Keychain.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func settingsForm(errors: [Field: String]) -> some View {
        Form {
            Section("General") {
                Toggle("Read-only", isOn: $connection.readOnly)
                Toggle("Connect on start up", isOn: $connection.connectsAutomatically)
            }
            Section("Encryption") {
                Toggle(isOn: $connection.encrypted) {
                    Text("Encrypt files")
                    Text(isNew
                         ? "Files and names are encrypted before they upload. Without the password, nobody can read them, including you."
                         : "You cannot change this after you add a drive.")
                }
                .disabled(!isNew)
                if isNew && connection.encrypted {
                    validated(.encryptionPassword, error: errors[.encryptionPassword]) { SecureField("Encryption password", text: $credentials.encryptionPassword) }
                    validated(.confirmation, error: errors[.confirmation]) { SecureField("Confirm password", text: $confirmation) }
                }
            }
            Section {
                Picker("Cache limit", selection: $connection.cacheLimit) {
                    ForEach(Self.cacheLimits, id: \.self) { Text($0, format: .byteCount(style: .file)).tag($0) }
                }
                Picker("Keep free on disk", selection: $connection.minimumFreeSpace) {
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
        Section {
            Picker("Bandwidth limit", selection: $connection.bandwidthLimit) {
                Text("Off").tag(Int64(0))
                ForEach(Self.bandwidthLimits, id: \.self) { limit in
                    Text("\(limit, format: .byteCount(style: .file))/s").tag(limit)
                }
            }
            Picker("Parallel transfers", selection: $connection.transfers) {
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

    private func validated(_ field: Field, error: String?, @ViewBuilder input: () -> some View) -> some View {
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
            Text(field.rawValue).foregroundStyle(error == nil ? Color.primary : Color.red)
        }
    }

    private func focusFirstInvalidField() -> Bool {
        showErrors = true
        error = nil
        let errors = fieldErrors
        guard let field = Field.allCases.first(where: { errors[$0] != nil }) else { return false }
        pane = field.pane
        focus = field
        return true
    }

    private func loadCredentials() {
        do {
            credentials = try model.credentials(for: credentialsSource)
            confirmation = credentials.encryptionPassword
            credentialsLoaded = true
            if isDuplicate { focus = .folder }
        } catch { self.error = error.localizedDescription }
    }

    func test() async {
        if focusFirstInvalidField() { return }
        testing = true
        tested = false
        defer { testing = false }
        do {
            try await model.service.test(connection, credentials: credentials)
            tested = true
        } catch { self.error = error.localizedDescription }
    }

    private func save() async {
        if focusFirstInvalidField() { return }
        saving = true
        defer { saving = false }
        do {
            try await model.save(connection, credentials: credentials)
            dismiss()
        } catch { self.error = error.localizedDescription }
    }
}
