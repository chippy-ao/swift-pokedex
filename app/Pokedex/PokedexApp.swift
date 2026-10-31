import SwiftUI

// アプリの入口。実装モジュールのリンクと注入はここで行う（docs/package-dependencies.md）。
@main
struct PokedexApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Pokedex")
        }
    }
}
