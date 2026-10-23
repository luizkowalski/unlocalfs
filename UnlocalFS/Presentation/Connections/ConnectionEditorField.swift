import SwiftUI
import UnlocalFSDomain

struct ConnectionEditorField<Input: View>: View {
    let field: ConnectionField
    let error: String?
    let focus: FocusState<ConnectionField?>.Binding
    @ViewBuilder let input: Input

    var body: some View {
        LabeledContent {
            VStack(alignment: .trailing, spacing: 4) {
                input
                    .labelsHidden()
                    .focused(focus, equals: field)
                if let error {
                    Label(error, systemImage: "exclamationmark.circle.fill")
                        .font(.caption).foregroundStyle(.red).multilineTextAlignment(.trailing)
                }
            }
        } label: {
            Text(field.displayName).foregroundStyle(error == nil ? Color.primary : Color.red)
        }
    }
}
