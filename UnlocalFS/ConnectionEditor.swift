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

    private static let cacheLimits: [Int64] = [128_000_000, 512_000_000, 1_000_000_000, 5_000_000_000, 10_000_000_000, 50_000_000_000]
    private static let freeSpaces: [Int64] = [1_000_000_000, 5_000_000_000, 10_000_000_000, 20_000_000_000]

    private var isNew: Bool { !model.connections.contains { $0.id == connection.id } }
    private var isLocked: Bool { testing || !credentialsLoaded }
    private var testInputs: [String] { [connection.provider.rawValue, connection.endpoint, connection.region, connection.bucket] }

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
                        ForEach(Provider.allCases) { provider in
                            Label { Text(provider.title) } icon: { provider.logo }.tag(provider)
                        }
                    }
                    TextField("Bucket", text: $connection.bucket, prompt: Text("my-bucket"))
                    TextField("Endpoint", text: $connection.endpoint, prompt: Text(verbatim: "https://s3.example.com"))
                    TextField("Region", text: $connection.region, prompt: Text("us-east-1 or auto"))
                    Text("Use the service endpoint without the bucket name. For Cloudflare R2, use region auto.")
                        .font(.caption).foregroundStyle(.secondary)
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
        .frame(width: 560)
        .presentationSizing(.fitted)
        .onAppear(perform: loadCredentials)
        .onChange(of: testInputs) { tested = false }
        .onChange(of: credentials) { tested = false }
    }

    private func loadCredentials() {
        do {
            credentials = try model.credentials(for: connection)
            credentialsLoaded = true
        } catch { self.error = error.localizedDescription }
    }

    func test() async {
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
