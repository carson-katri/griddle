import TokamakShim
import Foundation

/// An interactive keyboard, with an enter button on the left and delete button on the right.
///
/// The grid contains 20 columns so the second row can be offset by half a key (it is one key shorter than the first row).
/// Each key spans 2 columns, and the action buttons span 3.
struct Keyboard: View {
    static let rows = [
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
            ForEach(Self.rows, id: \.self) { row in
                GridRow {
                    if row.starts(with: "a") {
                        // The second row of letters is one key shorter than the first,
                        // so offset it one grid column with an unsized clear color.
                        Color.clear
                            .gridCellUnsizedAxes(.vertical)
                    } else if row.starts(with: "z") {
                        // The last row contains an enter button on the left.
                        Key(label: Text("enter"), action: onEnter, fill: .quaternary)
                            .gridCellColumns(3)
                            .gridCellUnsizedAxes(.horizontal)
                    }
                    ForEach(Array(row), id: \.self) { letter in
                        // Resolved color for this key, or the default quaternary hierarchical style.
                        // FIXME: When `AnyShapeStyle` is available in Tokamak, use `HierarchicalShapeStyle.quaternary` directly instead of recreating it from `Color.primary`.
                        let color = manager.color(for: letter) ?? Color.primary.opacity(0.2)
                        Key(
                            label: Text(String(letter))
                                .foregroundColor(
                                    // Use a white foreground color on a colorful fill.
                                    color == .disabled || color == Color.primary.opacity(0.2)
                                        ? nil
                                        : .white
                                ),
                            action: { onTapLetter(letter) },
                            fill: color
                        )
                            .gridCellColumns(2)
                    }
                    if row.starts(with: "z") {
                        // The last row contains a delete button on the right.
                        Key(label: Text("delete"), action: onDelete, fill: .quaternary)
                            .gridCellColumns(3)
                            .gridCellUnsizedAxes(.horizontal)
                    }
                }
            }
        }
    }
    
    struct Key<Fill: ShapeStyle>: View {
        let label: Text
        let action: () -> ()
        let fill: Fill
        
        var body: some View {
            Button(action: action) {
                label
                    .font(.system(size: 14))
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(fill, in: RoundedRectangle(cornerRadius: 5))
            }
        }
    }
}
