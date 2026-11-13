import NetworkClientURLSession
import Observation
import PokedexFeature
import SwiftUI

/// 図鑑タブの NavigationStack の path を持つ。画面と Route の対応は PokedexFeature が持ち、
/// ここは path を保持するだけ（PokedexFeature は Router を知らない）。
@MainActor
@Observable
final class Router {
    var path: [PokedexRoute] = []
}

// アプリの入口。実装モジュールのリンクと注入はここで行う（docs/package-dependencies.md）。
// NetworkClientURLSession は import するだけで、通信の liveValue が使われる。
@main
struct PokedexApp: App {
    @State private var router = Router()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                PokemonListView()
                    .pokedexDestinations()
            }
        }
    }
}
