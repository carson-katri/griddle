import Foundation
import TokamakShim
import JavaScriptKit

struct GameView: View {
    let grid: [[Character]]
    
    @StateObject private var manager: GameManager
    
    init(grid: [[Character]]) {
        self.grid = grid
        self._manager = .init(wrappedValue: GameManager(grid: grid))
    }
    
    var body: some View {
        VStack {
            Text("Griddle")
                .font(.largeTitle.weight(.heavy))
                .padding(.vertical)
            
            VStack {
                Spacer()
                    .frame(maxHeight: .infinity)
                
                Grid(horizontalSpacing: 4, verticalSpacing: 4).callAsFunction {
                    GridRow {
                        Color.clear
                            .gridCellUnsizedAxes([.horizontal, .vertical])
                        ForEach(0..<grid.count) { column in
                            AxisButton(axis: .vertical) {
                                manager.select(column: column)
                            }
                        }
                    }
                    ForEach(Array(grid.enumerated()), id: \.element) { word in
                        GridRow {
                            AxisButton(axis: .horizontal) {
                                manager.select(row: word.offset)
                            }
                            ForEach(Array(word.element.enumerated()), id: \.element) { character in
                                Button(action: {  }) {
                                    let lastGuess = manager.lastGuess(row: word.offset, column: character.offset)
                                    let guessCount = manager.guesses[word.offset][character.offset].count
                                    let color = manager.color(row: word.offset, column: character.offset)
                                    let isActive = manager.selection?.row == word.offset
                                        && manager.selection?.column == character.offset
                                    Text(
                                        String(lastGuess)
                                    )
                                        .font(.title.bold())
                                        .foregroundColor(color == .clear ? nil : Color.white)
                                        .frame(width: 65, height: 65)
                                        .background(color)
                                        .overlay {
                                            Rectangle()
                                                .stroke(
                                                    isActive ? .secondary : .tertiary,
                                                    lineWidth: color != .clear ? 0 :
                                                        (
                                                            manager.selection?.direction == .horizontal
                                                                && manager.selection?.row == word.offset
                                                        )
                                                    || (
                                                        manager.selection?.direction == .vertical
                                                            && manager.selection?.column == character.offset
                                                        ) ? 4 : 2
                                                )
                                        }
                                        .overlay(alignment: .bottomTrailing) {
                                            Text("\(GameManager.maxGuessesPerLetter - guessCount)")
                                                .font(.caption)
                                                .foregroundColor(color == .clear ? Color.secondary : Color.white.opacity(0.8))
                                                .padding(4)
                                                .background((color == .clear ? Color.primary.opacity(0.1) : Color.white.opacity(0.25)), in: RoundedRectangle(cornerRadius: 4))
                                                .padding(4)
                                        }
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                    .frame(maxHeight: .infinity)
                
                Keyboard(manager: manager) { letter in
                    manager.enter(letter)
                } onEnter: {
                    manager.guess()
                } onDelete: {
                    manager.delete()
                }
            }
            .overlay(alignment: .top) {
                ForEach(manager.messages, id: \.self) { message in
                    Text(message)
                        .padding()
                        .background(Color(white: 0.9), in: RoundedRectangle(cornerRadius: 5))
                        .padding(.top)
                }
            }
        }
        .padding()
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity)
        .overlay {
            switch manager.phase {
            case let .loss(stats),
                 let .win(stats):
                ModalView {
                    VStack(alignment: .leading) {
                        if case .win = manager.phase {
                            Text("Nice work!")
                                .font(.largeTitle)
                                .bold()
                        } else {
                            Text("Oh no!")
                                .font(.largeTitle)
                                .bold()
                        }
                        Text("Today's Grid")
                            .foregroundStyle(.secondary)
                        Grid(horizontalSpacing: 2, verticalSpacing: 2).callAsFunction {
                            ForEach(Array(manager.grid.enumerated()), id: \.offset) { row in
                                GridRow {
                                    ForEach(Array(row.element.enumerated()), id: \.offset) { letter in
                                        let guesses = stats.guesses[row.offset][letter.offset].count
                                        Text(String(letter.element))
                                            .font(.title3)
                                            .bold()
                                            .foregroundColor(.white)
                                            .frame(width: 40, height: 40)
                                            .background(manager.resultsColor(row: row.offset, column: letter.offset))
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                        Button(action: { stats.share() }) {
                            Text("share")
                                .foregroundColor(.white)
                                .bold()
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(.green, in: RoundedRectangle(cornerRadius: 5))
                        }
                    }
                    .frame(maxWidth: 300)
                }
            case .playing:
                EmptyView()
            }
        }
    }
}

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
                                .padding(8)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
                        }
                            .gridCellColumns(3)
                            .gridCellUnsizedAxes(.horizontal)
                    }
                    ForEach(Array(row), id: \.self) { letter in
                        Button(action: { onTapLetter(letter) }) {
                            let color = manager.color(for: letter)
                            Text(String(letter))
                                .font(.body.bold())
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(color ?? Color.primary.opacity(0.2), in: RoundedRectangle(cornerRadius: 5))
                        }
                            .gridCellColumns(2)
                    }
                    if row.starts(with: "z") {
                        Button(action: onDelete) {
                            Text("del")
                                .font(.body.bold())
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
                        }
                            .gridCellColumns(3)
                            .gridCellUnsizedAxes(.horizontal)
                    }
                }
            }
        }
    }
}

struct AxisButton: View {
    let axis: Axis
    let action: () -> ()
    
    var body: some View {
        Button(action: action) {
            Group {
                ellipsis
            }
            .frame(maxWidth: axis == .vertical ? .infinity : nil, maxHeight: axis == .horizontal ? .infinity : nil)
            .background {
                Rectangle()
                    .stroke(.quaternary, lineWidth: 2)
            }
        }
        .gridCellUnsizedAxes([.horizontal, .vertical])
    }
    
    @ViewBuilder
    var ellipsis: some View {
        let ellipsisLayout = axis == .vertical ? AnyLayout(HStack()) : AnyLayout(VStack())
        ellipsisLayout.callAsFunction {
            ForEach(0..<3) { _ in
                Circle()
                    .fill(.secondary)
                    .frame(width: 5, height: 5)
            }
        }
        .padding(axis == .vertical ? .vertical : .horizontal)
    }
}
