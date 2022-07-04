import TokamakShim
import JavaScriptKit
import Foundation

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

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    init(seed: Int) {
        srand48(seed)
    }
    
    func next() -> UInt64 {
        return withUnsafeBytes(of: drand48()) { bytes in
            bytes.load(as: UInt64.self)
        }
    }
}

private func makeGrid(seed: Int) -> ([Character], [Character], [Character]) {
    let rowLength = 3
    let colLength = 3
    
    var generator = SeededRandomNumberGenerator(seed: seed)
    let rowWords = wordlist.shuffled(using: &generator)
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
    } ?? makeGrid(seed: seed)
}

struct GriddleApp: App {
    #if os(WASI)
    static let _configuration = _AppConfiguration(reconciler: .fiber(useDynamicLayout: true))
    #endif
    
    @AppStorage("seenTutorial") var seenTutorial = false
    
    var body: some Scene {
        WindowGroup("Griddle") {
            GameView(seenTutorial: $seenTutorial)
        }
    }
}

struct GameHistory: Codable, Hashable {
    var history: [Day:[[[Character]]]]
    
    init(history: [Day:[[[Character]]]]) {
        self.history = history
    }
    
    static let sharedKey = "history"
    static var shared: Self {
        get {
            guard let data = LocalStorage.standard.read(key: sharedKey)?.data(using: .utf8),
                  let gameHistory = try? JSONDecoder().decode(GameHistory.self, from: data)
            else { return .init(history: [:]) }
            return gameHistory
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue),
                  let json = String(data: data, encoding: .utf8)
            else { return }
            LocalStorage.standard.store(key: sharedKey, value: json)
        }
    }
    
    struct Day: Codable, Hashable {
        let timestamp: Int
        
        static var today: Self {
            return Self(
                timestamp: Int(midnight.valueOf() / 1000)
            )
        }
        
        var grid: [[Character]] {
            let grid = makeGrid(seed: timestamp)
            return [
                grid.0,
                grid.1,
                grid.2,
            ]
        }
        
        static let midnight: JSDate = {
            var date = JSDate()
            date.hours = 0
            date.minutes = 0
            date.seconds = 0
            return date
        }()
        static let next: JSDate = {
            var date = midnight
            date.date += 1
            return date
        }()
    }
}

extension Character: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self = try Character(container.decode(String.self))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(String(self))
    }
}

var style = JSObject.global.document.createElement("style")
style.innerHTML = .string("button { border: none; background: none; padding: none; margin: none; touch-action: manipulation; }")
_ = JSObject.global.document.head.appendChild(style)

GriddleApp.main()
