import TokamakShim
import Foundation

/// Modal content with explainer text for the game.
struct HowToPlay: View {
    let onClose: () -> ()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("How to Play")
                .font(.title)
                .bold()
            Group {
                Text("""
                Each row/column forms a word.
                Find all six words to win.
                
                You can make up to 5 guesses per tile.
                
                """)
                Text("Tap on a selector to enter a row/column.")
                Text("Guesses are made on a single row/column at a time.")
                AxisButton(axis: .vertical, isActive: false, action: {})
                    .frame(width: 70)
                Text("Once it's active, you can start typing.")
                Text("Tap enter to confirm the row/column you selected.")
                Text("The colors of the tiles will indicate how close you are.")
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
    
    /// An example of a single row of tiles.
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
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
        }
    }
}
