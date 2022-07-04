import TokamakShim
import JavaScriptKit
import Foundation

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
