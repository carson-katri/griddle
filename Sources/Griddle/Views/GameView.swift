import Foundation
import TokamakShim
import JavaScriptKit

struct GameView: View {
    let grid: [[Character]]
    
    @StateObject private var manager: GameManager
    
    @State private var showTutorial = false
    
    init(grid: [[Character]]) {
        self.grid = grid
        self._manager = .init(wrappedValue: GameManager(grid: grid))
    }
    
    var body: some View {
        VStack {
            Text("Griddle")
                .font(.largeTitle.weight(.heavy))
                .padding(.vertical)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .trailing) {
                    Keyboard.Key(label: Text("?"), padding: 5, action: { showTutorial = true }, fill: .quaternary)
                        .frame(width: 28)
                        .padding(.trailing)
                }
            
            VStack {
                Spacer()
                    .frame(maxHeight: .infinity)
                
                Grid(horizontalSpacing: 4, verticalSpacing: 4).callAsFunction {
                    GridRow {
                        Color.clear
                            .gridCellUnsizedAxes([.horizontal, .vertical])
                        ForEach(0..<grid.count) { column in
                            AxisButton(
                                axis: .vertical,
                                isActive: manager.selection?.direction == .vertical
                                    && manager.selection?.column == column
                            ) {
                                manager.select(column: column)
                            }
                        }
                    }
                    ForEach(Array(grid.enumerated()), id: \.element) { word in
                        GridRow {
                            AxisButton(
                                axis: .horizontal,
                                isActive: manager.selection?.direction == .horizontal
                                    && manager.selection?.row == word.offset
                            ) {
                                manager.select(row: word.offset)
                            }
                            ForEach(Array(word.element.enumerated()), id: \.element) { character in
                                let lastGuess = manager.lastGuess(row: word.offset, column: character.offset)
                                let guessCount = manager.guesses[word.offset][character.offset].count
                                let color = manager.color(row: word.offset, column: character.offset)
                                let isActive = manager.selection?.row == word.offset
                                && manager.selection?.column == character.offset
                                Tile(lastGuess, fill: color, isActive: isActive)
                                .font(.title.bold())
                                .frame(width: 65, height: 65)
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
                VStack {
                    ForEach(manager.messages, id: \.self) { message in
                        Text(message)
                            .padding()
                            .background(Color(white: 0.9), in: RoundedRectangle(cornerRadius: 5))
                            .padding(.top)
                    }
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
                    GameSummaryView(manager: manager, stats: stats)
                }
            case .playing:
                EmptyView()
            }
        }
        .overlay {
            if showTutorial {
                ModalView {
                    HowToPlay {
                        showTutorial = false
                    }
                }
            } else {
                // FIXME: Bug in Tokamak where enabling then disabling the if causes an index out of bounds error.
                EmptyView()
            }
        }
    }
}

struct AxisButton: View {
    let axis: Axis
    let isActive: Bool
    let action: () -> ()
    
    var body: some View {
        Button(action: action) {
            ellipsis
            .frame(maxWidth: axis == .vertical ? .infinity : nil, maxHeight: axis == .horizontal ? .infinity : nil)
            .background {
                Group {
                    Rectangle()
                        .fill(isActive ? Color.primary.opacity(0.2) : .clear)
                    Rectangle()
                        .stroke(.quaternary, lineWidth: 2)
                }
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
