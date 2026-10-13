import SwiftUI
import UnlocalFSDomain
import UnlocalFSPresentation

struct ConnectionEditor: View {
    @State private var viewModel: ConnectionEditorViewModel
    @State private var pane = Pane.connection
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
                case .connection:
                    switch viewModel.connection.backend {
                    case .s3Compatible: S3ConnectionFields(viewModel: viewModel, errors: errors, focus: $focus)
                    case .sftp: SFTPConnectionFields(viewModel: viewModel, errors: errors, focus: $focus)
                    case .gcs: GCSConnectionFields(viewModel: viewModel, errors: errors, focus: $focus)
                    }
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

    private func settingsForm(errors: [ConnectionField: String]) -> some View {
        @Bindable var viewModel = viewModel
        return Form {
            Section("General") {
                Toggle("Read-only", isOn: $viewModel.connection.readOnly)
                if viewModel.connection.backend == .s3Compatible {
                    Toggle(isOn: Binding { viewModel.connection.usesUploadTimes } set: { viewModel.connection.prefersUploadTimes = $0 }) {
                        Text("Use upload time as file date")
                        Text("Folders open faster, but files show when they were uploaded, not when they were last changed. Always on for read-only drives.")
                    }
                    .disabled(viewModel.connection.readOnly)
                }
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
                    ConnectionEditorField(field: .encryptionPassword, error: errors[.encryptionPassword], focus: $focus) {
                        SecureField("Encryption password", text: $viewModel.credentials.encryptionPassword)
                    }
                    ConnectionEditorField(field: .confirmation, error: errors[.confirmation], focus: $focus) { SecureField("Confirm password", text: $viewModel.confirmation) }
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
                ConnectionEditorField(field: .kmsKey, error: errors[.kmsKey], focus: $focus) {
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
}
