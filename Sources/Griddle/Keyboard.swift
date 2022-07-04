import TokamakShim
import Foundation

struct Keyboard: View {
    let rows = [
        "qwertyuiop",
        "asdfghjkl",
        "zxcvbnm"
    ]
    
    @ObservedObject var manager: GameManager
    
    let onTapLetter: (Character) -> ()
    let onEnter: () -> ()
    let onDelete: () -> ()
    
    var body: some View {
        Grid(horizontalSpacing: 2, verticalSpacing: 2).callAsFunction {
            GridRow {
                ForEach(0..<20) { _ in
                    Color.clear
                        .gridCellUnsizedAxes([.horizontal, .vertical])
                }
            }
            ForEach(rows, id: \.self) { row in
                GridRow {
                    if row.starts(with: "a") {
                        Color.clear
                            .gridCellUnsizedAxes(.vertical)
                    } else if row.starts(with: "z") {
                        Button(action: onEnter) {
                            Text("ent")
                                .font(.body.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 15)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
                        }
                            .gridCellColumns(3)
                            .gridCellUnsizedAxes(.horizontal)
                    }
                    ForEach(Array(row), id: \.self) { letter in
                        Key(
                            label: String(letter),
                            action: { onTapLetter(letter) },
                            fill: manager.color(for: letter) ?? Color.primary.opacity(0.2)
                        )
                            .gridCellColumns(2)
                    }
                    if row.starts(with: "z") {
                        Key(label: "del", action: onDelete, fill: .quaternary)
                            .gridCellColumns(3)
                            .gridCellUnsizedAxes(.horizontal)
                    }
                }
            }
        }
    }
    
    struct Key<Fill: ShapeStyle>: View {
        let label: String
        let action: () -> ()
        let fill: Fill
        
        var body: some View {
            Button(action: action) {
                Text(label)
                    .font(.body.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 15)
                    .background(fill, in: RoundedRectangle(cornerRadius: 5))
            }
        }
    }
}
