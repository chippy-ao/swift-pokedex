import NetworkClientURLSession
import PokedexFeature
import SwiftUI

// アプリの入口。実装モジュールのリンクと注入はここで行う（docs/package-dependencies.md）。
// NetworkClientURLSession は import するだけで、通信の liveValue が使われる。
@main
struct PokedexApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                PokemonListView()
            }
        }
    }
}
