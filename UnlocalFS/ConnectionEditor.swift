import SwiftUI
import UnlocalFSCore

struct ConnectionEditor: View {
    @Environment(AppModel.self) private var model
    @State private var connection: Connection
    @State private var credentials = Credentials()
    @State private var credentialsLoaded = false
    @State private var testing = false
    @State private var tested = false
    @State private var error: String?
    @Environment(\.dismiss) private var dismiss

    init(connection: Connection) {
        _connection = State(initialValue: connection)
    }

    private var isNew: Bool { !model.connections.contains { $0.id == connection.id } }
    private var isLocked: Bool { testing || !credentialsLoaded }

    var body: some View {
        VStack(spacing: 0) {
            Text(isNew ? "Add connection" : "Edit connection")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            Form {
                Section("Drive") {
                    TextField("Name", text: $connection.name, prompt: Text("My storage"))
                    Picker("Provider", selection: $connection.provider) {
                        ForEach(Provider.allCases) { Text($0.title).tag($0) }
                    }
                    TextField("Bucket", text: $connection.bucket, prompt: Text("my-bucket"))
                    TextField("Endpoint", text: $connection.endpoint, prompt: Text("https://s3.example.com"))
                    TextField("Region", text: $connection.region, prompt: Text("us-east-1 or auto"))
                    Text("Use the service endpoint without the bucket name. For Cloudflare R2, use region auto.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Credentials") {
                    TextField("Access key", text: $credentials.accessKey)
                    SecureField("Secret key", text: $credentials.secretKey)
                    SecureField("Session token (optional)", text: $credentials.sessionToken)
                    Text("Credentials are stored in your Mac’s Keychain.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .disabled(isLocked)
            if let error {
                Text(error).foregroundStyle(.red).font(.callout).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 24).padding(.bottom, 12)
            } else if tested {
                Label("Connection successful", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green).padding(.bottom, 12)
            }
            Divider()
            HStack {
                Button { Task { await test() } } label: {
                    if testing { ProgressView().controlSize(.small) } else { Text("Test Connection") }
                }
                .disabled(isLocked)
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction).disabled(testing)
                Button("Save", action: save).keyboardShortcut(.defaultAction).disabled(isLocked)
            }
            .padding(20)
        }
        .frame(width: 560, height: 630)
        .onAppear(perform: loadCredentials)
        .onChange(of: connection) { tested = false }
        .onChange(of: credentials) { tested = false }
    }

    private func loadCredentials() {
        do {
            credentials = try model.credentials(for: connection)
            credentialsLoaded = true
        } catch { self.error = error.localizedDescription }
    }

    private func test() async {
        testing = true
        tested = false
        error = nil
        defer { testing = false }
        do {
            try await model.service.test(connection, credentials: credentials)
            tested = true
        } catch { self.error = error.localizedDescription }
    }

    private func save() {
        do {
            try model.save(connection, credentials: credentials)
            dismiss()
        } catch { self.error = error.localizedDescription }
    }
}
