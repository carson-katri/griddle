import TokamakShim
import JavaScriptKit
import Foundation

struct GameSummaryView: View {
    @ObservedObject var manager: GameManager
    @State private var includeURL = true
    
    @StateObject private var timer = Timer()
    final class Timer: ObservableObject {
        private var timer: JSTimer!
        @Published var now = JSDate()
        
        init() {
            self.timer = JSTimer(millisecondsDelay: 1000, isRepeating: true) { [weak self] in
                self?.now = JSDate()
            }
        }
    }
    
    var body: some View {
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
                            let guesses = manager.guesses[row.offset][letter.offset].count
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
            HStack {
                VStack(alignment: .leading) {
                    Text("Next Griddle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formattedCountdown)
                        .font(.title)
                        .bold()
                }
                .padding(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                // FIXME: Use `Divider` when fiber supports it
                Rectangle()
                    .fill(.quaternary)
                    .frame(width: 1, height: 50)
                VStack(alignment: .leading) {
                    Keyboard.Key(
                        label: Text("share your grid")
                            .foregroundColor(.white),
                        padding: 8,
                        action: { manager.share(includeURL: includeURL) },
                        fill: .green
                    )
                    .frame(width: 125)
                    Checkbox(isOn: $includeURL) {
                        Text(includeURL ? "with site link" : "without site link")
                            .font(.caption)
                    }
                }
            }
        }
        .frame(maxWidth: 300)
    }
    
    var formattedCountdown: String {
        let remaining = (Day.next.valueOf() - timer.now.valueOf()) / 1000
        let h = remaining / 3600
        let m = remaining.truncatingRemainder(dividingBy: 3600) / 60
        let s = remaining.truncatingRemainder(dividingBy: 3600).truncatingRemainder(dividingBy: 60)
        return (h < 10 ? "0\(Int(h))" : "\(Int(h))")
            + ":" + (m < 10 ? "0\(Int(m))" : "\(Int(m))")
            + ":" + (s < 10 ? "0\(Int(s))" : "\(Int(s))")
    }
}