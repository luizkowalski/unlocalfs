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
    @State private var tested = false
    @State private var error: String?
    @State private var showErrors = false
    @FocusState private var focus: Field?
    @Environment(\.dismiss) private var dismiss

    private enum Field: String, CaseIterable {
        case name = "Name", bucket = "Bucket", folder = "Folder", endpoint = "Endpoint", accessKey = "Access key", secretKey = "Secret key"
        case encryptionPassword = "Encryption password", confirmation = "Confirm password"
    }

    init(draft: AppModel.Draft) {
        _connection = State(initialValue: draft.connection)
        credentialsSource = draft.credentialsSource
        isDuplicate = draft.isDuplicate
    }

    private static let cacheLimits: [Int64] = [128_000_000, 512_000_000, 1_000_000_000, 5_000_000_000, 10_000_000_000, 50_000_000_000]
    private static let freeSpaces: [Int64] = [1_000_000_000, 5_000_000_000, 10_000_000_000, 20_000_000_000]

    private var isNew: Bool { !model.connections.contains { $0.id == connection.id } }
    private var title: String {
        if isDuplicate { return "Duplicate connection" }
        return isNew ? "Add connection" : "Edit connection"
    }
    private var isLocked: Bool { testing || !credentialsLoaded }
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
            Text(title)
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            Form {
                Section("Drive") {
                    validated(.name, error: errors[.name]) { TextField("Name", text: $connection.name, prompt: Text("My storage")) }
                    Picker("Provider", selection: $connection.provider) {
                        ForEach(Provider.allCases) { provider in
                            Label { Text(provider.title) } icon: { provider.logo }.tag(provider)
                        }
                    }
                    validated(.bucket, error: errors[.bucket]) { TextField("Bucket", text: $connection.bucket, prompt: Text("my-bucket")) }
                    validated(.folder, error: errors[.folder]) { TextField("Folder", text: $connection.folder, prompt: Text("Optional, for example clients/acme")) }
                    validated(.endpoint, error: errors[.endpoint]) { TextField("Endpoint", text: $connection.endpoint, prompt: Text(verbatim: "https://s3.example.com")) }
                    TextField("Region", text: $connection.region, prompt: Text("us-east-1 or auto"))
                    Text("Use the service endpoint without the bucket name. For Cloudflare R2, use region auto. Enter a folder to show only that folder as the drive.")
                        .font(.caption).foregroundStyle(.secondary)
                    Toggle("Read-only", isOn: $connection.readOnly)
                }
                Section("Credentials") {
                    validated(.accessKey, error: errors[.accessKey]) { TextField("Access key", text: $credentials.accessKey) }
                    validated(.secretKey, error: errors[.secretKey]) { SecureField("Secret key", text: $credentials.secretKey) }
                    SecureField("Session token (optional)", text: $credentials.sessionToken)
                    Text("Credentials are stored in your Mac’s Keychain.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Encryption") {
                    Toggle("Encrypt files", isOn: $connection.encrypted).disabled(!isNew)
                    if isNew && connection.encrypted {
                        validated(.encryptionPassword, error: errors[.encryptionPassword]) { SecureField("Encryption password", text: $credentials.encryptionPassword) }
                        validated(.confirmation, error: errors[.confirmation]) { SecureField("Confirm password", text: $confirmation) }
                    }
                    Text(isNew
                         ? "Files and file names are encrypted on this Mac before they upload. Keep the password in a safe place. " +
                           "Without it, nobody can read these files, including you."
                         : "You cannot change encryption after you add a drive.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Options") {
                    Toggle("Connect on start up", isOn: $connection.connectsAutomatically)
                }
                Section("Cache") {
                    Picker("Cache limit", selection: $connection.cacheLimit) {
                        ForEach(Self.cacheLimits, id: \.self) { Text($0, format: .byteCount(style: .file)).tag($0) }
                    }
                    Picker("Keep free on disk", selection: $connection.minimumFreeSpace) {
                        Text("Off").tag(Int64(0))
                        ForEach(Self.freeSpaces, id: \.self) { Text($0, format: .byteCount(style: .file)).tag($0) }
                    }
                    Text("Files you have not opened for the longest time are removed first. Open files and pending uploads stay, so the cache can go over the limit.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
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
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction).disabled(testing)
                Button("Save", action: save).keyboardShortcut(.defaultAction).disabled(isLocked)
            }
            .padding(20)
        }
        .frame(width: 560)
        .presentationSizing(.fitted)
        .onAppear(perform: loadCredentials)
        .onChange(of: testInputs) { tested = false }
        .onChange(of: credentials) { tested = false }
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

    private func save() {
        if focusFirstInvalidField() { return }
        do {
            try model.save(connection, credentials: credentials)
            dismiss()
        } catch { self.error = error.localizedDescription }
    }
}
