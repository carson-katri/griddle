import TokamakShim

/// A single letter in the grid with a given fill color or stoke.
///
/// Different fill colors have specific meanings:
/// * Green - the tile is correct.
/// * Yellow - the tile is somewhere in the grid.
/// * Gray - the tile is not in the grid.
///
/// When active, the stroke prominence is increased.
struct Tile: View {
    let letter: Character
    let fill: Color
    let isActive: Bool
    
    init(_ letter: Character, fill: Color = .clear, isActive: Bool = false) {
        self.letter = letter
        self.fill = fill
        self.isActive = isActive
    }
    
    var body: some View {
        Text(String(letter))
            .foregroundColor(fill == .clear ? nil : Color.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(fill)
            .overlay {
                Rectangle()
                    .stroke(
                        isActive ? .secondary : .tertiary,
                        lineWidth: fill != .clear ? 0 :
                            isActive ? 4 : 2
                    )
            }
    }
}
