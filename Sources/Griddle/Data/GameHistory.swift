import Foundation
import TokamakShim

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
}
