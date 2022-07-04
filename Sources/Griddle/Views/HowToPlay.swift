import TokamakShim
import Foundation

struct HowToPlay: View {
    let onClose: () -> ()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("How to Play")
                .font(.title)
                .bold()
            Group {
                Text("""
                Each word across and down forms a word.
                Find all six words to win.
                
                You can make up to 5 guesses per tile.
                
                """)
                Text("Tap on a selector to enter a row/column.")
                    .font(.caption)
                AxisButton(axis: .vertical, isActive: false, action: {})
                    .frame(width: 70)
                Text("Then you can start typing.\nLetters will change color to indicate various states.")
                    .padding(.bottom)
            }
            .font(.caption)
            

            Text("Examples")
                .font(.headline)
                .padding(.bottom, 4)
            VStack(alignment: .leading, spacing: 16) {
                ExampleRow(
                    word: [("H", .green), ("E", .clear), ("Y", .clear)],
                    caption: """
                    Green means 'H' is correct.
                    You cannot change a green letter.
                    """
                )
                ExampleRow(
                    word: [("B", .clear), ("A", .yellow), ("T", .clear)],
                    caption: "Yellow means 'A' goes somewhere else in the grid."
                )
                ExampleRow(
                    word: [("F", .clear), ("U", .clear), ("N", Color.secondary)],
                    caption: "Gray means 'N' is not in the word."
                )
            }
            .padding(.bottom)
            
            Text("""
                Each guess does not need to make a fully valid grid.
                If you make more than 5 guesses in a tile, you lose.
                """)
            .font(.caption)
            
            Keyboard.Key(
                label: Text("start playing")
                    .foregroundColor(.white),
                padding: 8,
                action: onClose,
                fill: .green
            )
        }
        .frame(maxWidth: 300, alignment: .leading)
    }
    
    struct ExampleRow: View {
        let word: [(letter: Character, color: Color)]
        let caption: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    ForEach(word, id: \.letter) { letter in
                        Tile(letter.letter, fill: letter.color)
                            .frame(width: 35, height: 35)
                    }
                }
                .font(.title3.bold())
                Text(caption)
                    .font(.caption2)
                    .padding(.top, 2)
            }
        }
    }
}
