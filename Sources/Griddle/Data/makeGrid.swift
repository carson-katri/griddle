import Foundation

var generator = SeededRandomNumberGenerator(seed: seed)

/// Generate a 3x3 grid of valid words.
///
/// A few conditions must be met for a grid to be valid:
///
/// * Each row/column must form a valid word. For example,
/// ```
/// S A C
/// A G O
/// T E N
/// ```
/// is a valid grid containing `SAC`, `AGO`, `TEN` as rows, and `SAT`, `AGE`, and `CON` as columns.
///
/// * No words can repeat. For example,
/// ```
/// S A G
/// A G E
/// T E N
/// ```
/// is not a valid grid (even though each word itself is valid) because `AGE` is the second row and column.
func makeGrid(seed: Int) -> ([Character], [Character], [Character]) {
    let rowLength = 3
    
    let shuffledWords = wordlist.shuffled(using: &generator)
    
    var possible = [[[Character]]]()
    
    // First pick the topmost row.
    // Example:
    // C A T
    // _ _ _
    // _ _ _
    let rowWord = shuffledWords[0]
    
    // Filter the word list to words that start with any letter in the `rowWord`.
    // Example:
    // C A T
    // A R A
    // R T G
    // At this point, we don't try to build a valid grid, we just want a list of every word
    // that starts with (in this case) C, A, or T.
    for col in 0..<rowLength {
        possible.append(shuffledWords.reduce(into: [], { partialResult, word in
            if word.starts(with: String(rowWord[rowWord.index(rowWord.startIndex, offsetBy: col)])) {
                partialResult.append(Array(word))
            }
        }))
    }
    
    // Now check every possible combination of columns.
    return cartestianProduct(
        a: possible[0], b: possible[1], c: possible[2]
    ) { (a, b, c) in
        // Validate this combination.
        // These words would be placed vertically. We know they are valid words.
        
        // Don't allow the same word twice in a column.
        if a == b || b == c || a == c {
            return nil
        }
        
        var columns = [[Character]]()
        // Check if they form a valid word in each row.
        // Example:
        // a is STY, b is AWE, c is TOT.
        // S T Y
        // A W E
        // T O T
        for col in 0..<rowLength {
            // Check if the letters form a column.
            // Example:
            // STY[0] -> S, AWE[0] -> A, TOT[0] -> T.
            // SAT is a word, so it passes.
            let column = [a[col], b[col], c[col]]
            if !wordlist.contains(String(column)) {
                return nil
            }
            // Check if we used a word more than once.
            // If so, this is invalid.
            if column == a || column == b || column == c || columns.contains(column) {
                return nil
            }
            columns.append(column)
        }
        // If all checks passed, use this as the grid.
        return (a, b, c)
    } ?? makeGrid(seed: seed) // If this `rowWord` has no valid grid, try again with a new row word.
}

/// Naively loops through all combinations of `a`, `b`, and `c`.
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

/// A random number generator that accepts a seed.
///
/// This allows us to generate the same grid for every player each day
/// by using the date as the seed. It also prevents the need to precompute a certain number of grids.
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
