import SwiftUI
import UnlocalFSDomain

struct ServerTrustSheet: View {
    let challenge: ServerTrustChallenge
    let onTrust: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                if challenge.keyChanged { Text("Server key changed") } else { Text("Trust this server?") }
            } icon: {
                Image(systemName: challenge.keyChanged ? "exclamationmark.shield" : "checkmark.shield")
            }
            .font(.title2.bold())
            Text(verbatim: challenge.server).font(.headline).textSelection(.enabled)
            if challenge.keyChanged {
                Text("This server has a different key. Check the fingerprint with its administrator before you replace the trusted key.")
            } else {
                Text("Check the fingerprint with the server’s administrator. Trust this key to connect now and recognize this server next time.")
            }
            Text(verbatim: challenge.fingerprints)
                .font(.system(.callout, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.quaternary, in: .rect(cornerRadius: 8))
            HStack {
                Spacer()
                Button("Cancel", action: onCancel).keyboardShortcut(.cancelAction)
                if challenge.keyChanged {
                    Button("Replace key and connect", role: .destructive, action: onTrust)
                } else {
                    Button("Trust and connect", action: onTrust).buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(24)
        .frame(width: 520)
        .fixedSize(horizontal: false, vertical: true)
        .interactiveDismissDisabled()
    }
}
