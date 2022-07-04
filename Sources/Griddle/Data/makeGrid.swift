import Foundation

func makeGrid(seed: Int) -> ([Character], [Character], [Character]) {
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
