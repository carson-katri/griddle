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

var title = JSObject.global.document.createElement("title")
title.innerHTML = .string("Griddle")
_ = JSObject.global.document.head.appendChild(title)

var favicon = JSObject.global.document.createElement("link")
favicon.rel = .string("icon")
favicon.type = .string("image/x-icon")
favicon.href = .string("favicon.ico")
_ = JSObject.global.document.head.appendChild(favicon)

GriddleApp.main()
