import TokamakShim
import Foundation

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
