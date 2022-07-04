import TokamakShim

// FIXME: Use `Toggle` with a custom style. when available in Fiber renderers.
/// A custom toggle style for a checkbox with a ✅ or ❌ inside.
struct Checkbox<Label: View>: View {
    @Binding var isOn: Bool
    @ViewBuilder let label: Label
    
    var body: some View {
        Button(action: { isOn.toggle() }) {
            HStack(spacing: 8) {
                Image(isOn ? "checkmark.svg" : "xmark.svg")
                    .resizable()
                    .frame(width: 15, height: 15)
                    .frame(width: 20, height: 20)
                    .background(isOn ? .green : .secondary, in: RoundedRectangle(cornerRadius: 5))
                label
                    .foregroundStyle(.secondary)
            }
        }
    }
}
