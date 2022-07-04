import TokamakShim
import JavaScriptKit

private func cartestianProduct<R>(
    a: [[Character]],
    b: [[Character]],
    c: [[Character]],
    predicate: ([Character], [Character], [Character]) -> R?
) -> R? {
    for a in a {
        for b in b {
            for c in c {
                if let result = predicate(a, b, c) {
                    return result
                }
            }
        }
    }
    return nil
}

private func makeGrid() -> ([Character], [Character], [Character]) {
    let rowLength = 3
    let colLength = 3
    
    let rowWords = wordlist.shuffled()
    let colWords = wordlist
    
    var possible = [[[Character]]]()
    let rowWord = rowWords[0]
    for col in 0..<rowLength {
        possible.append(colWords.reduce(into: [], { (partialResult: inout [[Character]], word: String) in
            if word.starts(with: String(rowWord[rowWord.index(rowWord.startIndex, offsetBy: col)])) {
                partialResult.append(Array(word))
            }
        }))
    }
    
    return cartestianProduct(
        a: possible[0], b: possible[1], c: possible[2]
    ) { (a, b, c) in
        for col in 0..<rowLength {
            let col = [a[col], b[col], c[col]]
            if !wordlist.contains(String(col)) {
                return nil
            }
            if a == col || b == col || c == col {
                return nil
            }
        }
        return (a, b, c)
    } ?? makeGrid()
}

struct GriddleApp: App {
    #if os(WASI)
    static let _configuration = _AppConfiguration(reconciler: .fiber(useDynamicLayout: true))
    #endif
    
    let grid: [[Character]]
    
    init() {
//        let grid = makeGrid()
        let grid: ([Character], [Character], [Character]) = (["A", "B", "C"], ["D", "E", "F"], ["G", "H", "I"])
        self.grid = [
            grid.0,
            grid.1,
            grid.2,
        ]
    }
    
    @State private var count = 0
    
    var body: some Scene {
        WindowGroup("Griddle") {
            GameView(grid: grid)
        }
    }
}

var style = JSObject.global.document.createElement("style")
style.innerHTML = .string("button { border: none; background: none; padding: none; margin: none; }")
_ = JSObject.global.document.head.appendChild(style)

GriddleApp.main()
