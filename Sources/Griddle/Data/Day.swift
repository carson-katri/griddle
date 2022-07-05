import Foundation
import JavaScriptKit

struct Day: Codable, Hashable {
    let timestamp: Int
    
    var grid: [[Character]] {
        let grid = makeGrid(seed: timestamp)
        return [
            grid.0,
            grid.1,
            grid.2,
        ]
    }
    
    /// The game was released 7/4/2022.
    ///
    /// Used to compute the # of this game when sharing.
    static let releaseDate: Self = {
        Self(timestamp: 1656892800)
    }()
    
    static let today: Self = {
        Self(
            timestamp: Int(midnight.valueOf() / 1000)
        )
    }()
    
    static let Date = JSObject.global.Date.function!
    static let midnight: JSDate = {
        var date = JSDate()
        return JSDate(millisecondsSinceEpoch: Date.UTC!(date.fullYear, date.month, date.date).number!)
    }()
    static let next: JSDate = {
        var date = JSDate()
        date.hours = 0
        date.minutes = 0
        date.seconds = 0
        date.date += 1
        return date
    }()
}
