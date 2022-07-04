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
    
    static let today: Self = {
        Self(
            timestamp: Int(midnight.valueOf() / 1000)
        )
    }()
    
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
