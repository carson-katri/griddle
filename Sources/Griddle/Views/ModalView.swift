import TokamakShim
import Foundation

/// A custom modal UI. This could perhaps use the `dialog` tag when available in Tokamak.
struct ModalView<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        Color.black.opacity(0.25)
            .overlay {
                content
                    .padding()
                    .background(Color(white: 1), in: RoundedRectangle(cornerRadius: 5))
            }
    }
}
