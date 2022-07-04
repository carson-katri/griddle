import TokamakShim
import Foundation
import JavaScriptKit

final class GameManager: ObservableObject {
    static let maxGuessesPerLetter = 5
    
    let grid: [[Character]]
    let occurrences: [Character:Int]
    
    @Published var phase = Phase.playing
    @Published var activeInput = [Character]()
    @Published var guesses = [[[Character]]]()
    @Published var selection: Selection? = nil
    
    @Published var messages = [String]()
    
    enum Phase: Hashable {
        case playing
        case win(Stats)
        case loss(Stats)
    }
    
    struct Stats: Hashable {
        let guesses: [[[Character]]]
        
        func share() {
            let grid = guesses.map { row in
                row.map { column in
                    if column.count == 0 {
                        return "⬛️"
                    } else if column.count <= 2 {
                        return "🟩"
                    } else if column.count <= 3 {
                        return "🟨"
                    } else if column.count >= GameManager.maxGuessesPerLetter {
                        return "🟥"
                    } else {
                        return "⬛️"
                    }
                }.joined(separator: "")
            }.joined(separator: "\n")
            let message = """
            Griddle 1
            
            \(grid)
            """
            print(message)
            
            if JSObject.global.navigator.isUndefined || JSObject.global.navigator.share.isUndefined {
                _ = JSObject.global.navigator.clipboard.writeText(message)
            } else {
                _ = JSObject.global.navigator.share([
                    "text": message
                ].jsValue)
            }
        }
    }
    
    struct Selection: Hashable {
        let direction: Axis
        var row: Int
        var column: Int
    }
    
    init(grid: [[Character]]) {
        self.grid = grid
        var occurrences = [Character:Int]()
        var guesses = [[[Character]]]()
        for row in grid {
            guesses.append(Array(repeating: [], count: row.count))
            for column in row {
                occurrences[column, default: 0] += 1
            }
        }
        self.guesses = guesses
        self.occurrences = occurrences
        activeInput = grid.map { _ in " " }
        
        print(grid)
        
        let alphabet = "abcdefghijklmnopqrstuvwxyz"
        _ = JSObject.global.document.addEventListener("keydown", JSClosure { [weak self] event in
            guard let event = event.first?.object,
                  let key = event.key.string
            else { return .undefined }
            if key == "Enter" {
                self?.guess()
            } else if key == "Backspace" {
                self?.delete()
            } else if let character = key.first,
                      alphabet.contains(character) {
                self?.enter(character)
            }
            return .undefined
        })
    }
    
    func select(column: Int) {
        var selection = Selection(
            direction: .vertical,
            row: 0,
            column: column
        )
        activeInput = guesses.enumerated().map { (row, guessRow) in
            guessRow[column].last == grid[row][column] ? grid[row][column] : " "
        }
        while guesses.indices.contains(selection.row) && guesses[selection.row][column].last == grid[selection.row][column] {
            selection.row += 1
        }
        
        if self.selection == selection {
            self.selection = nil
        } else {
            self.selection = selection
        }
    }
    
    func select(row: Int) {
        var selection = Selection(
            direction: .horizontal,
            row: row,
            column: 0
        )
        
        activeInput = guesses[row].enumerated().map { (column, guesses) in
            guesses.last == grid[row][column] ? grid[row][column] : " "
        }
        while guesses.indices.contains(row) && guesses[row].indices.contains(selection.column) && guesses[row][selection.column].last == grid[row][selection.column] {
            selection.column += 1
        }
        
        if self.selection == selection {
            self.selection = nil
        } else {
            self.selection = selection
        }
    }
    
    func enter(_ character: Character) {
        let character = Character(String(character).uppercased())
        
        guard var selection = selection,
              guesses.indices.contains(selection.row),
              guesses[selection.row].indices.contains(selection.column)
        else { return }
        switch selection.direction {
        case .horizontal:
            activeInput[selection.column] = character
            selection.column += 1
            while guesses.indices.contains(selection.row) && guesses[selection.row].indices.contains(selection.column) && guesses[selection.row][selection.column].last == grid[selection.row][selection.column] {
                selection.column += 1
            }
        case .vertical:
            activeInput[selection.row] = character
            selection.row += 1
            while guesses.indices.contains(selection.row) && guesses[selection.row].indices.contains(selection.column) && guesses[selection.row][selection.column].last == grid[selection.row][selection.column] {
                selection.row += 1
            }
        }
        
        if self.selection == selection {
            self.selection = nil
        } else {
            self.selection = selection
        }
    }
    
    func delete() {
        guard var selection = selection
        else { return }
        let targetRow = selection.direction == .vertical ? selection.row - 1 : selection.row
        let targetColumn = selection.direction == .horizontal ? selection.column - 1 : selection.column
        guard guesses.indices.contains(targetRow),
              guesses[targetRow].indices.contains(targetColumn)
        else { return }
        switch selection.direction {
        case .horizontal:
            if guesses[targetRow][targetColumn].last != grid[targetRow][targetColumn] {
                activeInput[targetColumn] = " "
            }
            selection.column -= 1
            while guesses.indices.contains(targetRow) && guesses[targetRow].indices.contains(selection.column) && guesses[targetRow][selection.column].last == grid[targetRow][selection.column] {
                selection.column -= 1
            }
            activeInput[selection.column] = " "
        case .vertical:
            if guesses[targetRow][targetColumn].last != grid[targetRow][targetColumn] {
                activeInput[targetRow] = " "
            }
            selection.row -= 1
            while guesses.indices.contains(selection.row) && guesses[selection.row].indices.contains(targetColumn) && guesses[selection.row][targetColumn].last == grid[selection.row][targetColumn] {
                selection.row -= 1
            }
            activeInput[selection.row] = " "
        }
        self.selection = selection
    }
    
    /// Commit a guess.
    func guess() {
        guard wordlist.contains(String(activeInput)) else {
            messages.append("Not in word list")
            return
        }
        guard let selection = selection else { return }
        switch selection.direction {
        case .horizontal:
            guard guesses.indices.contains(selection.row)
            else { return }
            for column in 0..<guesses[selection.row].count {
                guard activeInput.indices.contains(column) else { continue }
                if guesses[selection.row][column].last != grid[selection.row][column] {
                    guesses[selection.row][column].append(activeInput[column])
                }
            }
        case .vertical:
            guard guesses[0].indices.contains(selection.column)
            else { return }
            for row in 0..<guesses.count {
                guard activeInput.indices.contains(row) else { continue }
                if guesses[row][selection.column].last != grid[row][selection.column] {
                    guesses[row][selection.column].append(activeInput[row])
                }
            }
        }
        self.selection = nil
        activeInput = self.guesses.map { _ in " " }
        
        var didWin = true
        for row in 0..<guesses.count {
            for column in 0..<guesses[row].count {
                if guesses[row][column].last != grid[row][column] {
                    if guesses[row][column].count >= Self.maxGuessesPerLetter {
                        self.phase = .loss(Stats(guesses: guesses))
                        return
                    }
                    didWin = false
                }
            }
        }
        if didWin {
            self.phase = .win(Stats(guesses: guesses))
        }
    }
    
    func lastGuess(row: Int, column: Int, useInput: Bool = true) -> Character {
        guard let selection = selection else { return guesses[row][column].last ?? " " }

        let lastGuess = guesses[row][column].last ?? " "
        
        switch selection.direction {
        case .horizontal:
            if useInput && selection.row == row && lastGuess != grid[row][column] {
                return activeInput[column]
            } else {
                return lastGuess
            }
        case .vertical:
            if useInput && selection.column == column && lastGuess != grid[row][column] {
                return activeInput[row]
            } else {
                return lastGuess
            }
        }
    }
    
    /// The color for a grid tile at `row`/`column`.
    func color(row: Int, column: Int) -> Color {
        let guess = lastGuess(row: row, column: column, useInput: false)
        
        // No guess has been made, so fill with clear.
        if guess == " " {
            return .clear
        }
        
        let real = grid[row][column]
        
        // The guess was correct, so fill with green.
        if guess == real {
            return .green
        }
        
        switch selection?.direction {
        case .horizontal:
            guard selection?.row != row else { return .clear }
        case .vertical:
            guard selection?.column != column else { return .clear }
        default:
            break
        }
        
        var guessOccurrences = 0
        for rowIndex in 0..<grid.count {
            for columnIndex in 0..<grid[rowIndex].count {
                let lastGuess = guesses[rowIndex][columnIndex].last
                if lastGuess == guess && lastGuess == grid[rowIndex][columnIndex] {
                    guessOccurrences += 1
                    continue
                }
                if rowIndex > row || (rowIndex == row && columnIndex >= column) {
                    continue
                }
                if lastGuess == guess {
                    guessOccurrences += 1
                }
            }
        }
        return guessOccurrences < occurrences[guess, default: 0] ? .yellow : .secondary
    }
    
    /// The color for a share tile, indicating the number of guesses taken for each.
    func resultsColor(row: Int, column: Int) -> Color {
        let guesses = guesses[row][column]
        if guesses.last != grid[row][column] {
            return .red
        } else if guesses.count <= 2 {
            return .green
        } else if guesses.count <= 3 {
            return .yellow
        } else {
            return .secondary
        }
    }
    
    /// The color for a key given the current selection.
    func color(for letter: Character) -> Color? {
        let letter = Character(String(letter).uppercased())
        
        // If we have a selection,
        // disable the key when we previously guessed this letter here but it was wrong.
        if let selection = selection,
           grid.indices.contains(selection.row),
           grid[selection.row].indices.contains(selection.column),
           guesses[selection.row][selection.column].contains(letter) && grid[selection.row][selection.column] != letter {
            return .disabled
        }
        
        var isContained = false
        var wasGuessed = false
        // Check each coordinate
        for row in 0..<grid.count {
            for col in 0..<grid[row].count {
                // This letter is contained in the grid.
                if grid[row][col] == letter {
                    isContained = true
                }
                // Check each guess for our letter.
                for guess in guesses[row][col] {
                    guard guess == letter else { continue }
                    wasGuessed = true
                    // If we got it correct, return green.
                    if guess == grid[row][col] {
                        return .green
                    }
                }
            }
        }
        // If we haven't guessed this letter, don't reveal the color
        if wasGuessed {
            // If we have guessed this letter, return yellow if its contained in the grid,
            // or disable it if not.
            return isContained ? .yellow : .disabled
        }
        return nil
    }
}

extension Color {
    static var disabled: Color {
        .primary.opacity(0.05)
    }
}
