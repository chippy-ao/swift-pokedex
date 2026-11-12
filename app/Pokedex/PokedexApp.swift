import Dependencies
import NetworkClient
import NetworkClientURLSession
import PokedexFeature
import SwiftUI

// アプリの入口。実装モジュールのリンクと注入はここで行う（docs/package-dependencies.md）。
// NetworkClientURLSession は import するだけで、通信の liveValue が使われる。
@main
struct PokedexApp: App {
    init() {
        Self.useUITestFixtureIfRequested()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                PokemonListView()
            }
        }
    }

    /// UI テスト（app/PokedexUITests）が起動時の環境変数 POKEDEX_UI_TEST_FIXTURE=1 を渡したときだけ、
    /// 一覧の通信（fetchPokemonList）を固定のデータに差し替える。CI で PokeAPI を叩かないため。
    /// 差し替えるのはここだけにする。名前の表（fetchAllPokemonSpeciesNames、同梱の JSON）と
    /// 言語の読み取り（PreferredLocalization の liveValue）は本物のまま通す。
    /// 単体テストが見逃した「組み上げたアプリでは言語が効いていない」を、UI テストで見つけるため。
    /// prepareDependencies は最初のアクセスの前に 1 回だけ呼べるので、init で呼ぶ。
    private static func useUITestFixtureIfRequested() {
        guard ProcessInfo.processInfo.environment["POKEDEX_UI_TEST_FIXTURE"] == "1" else { return }
        prepareDependencies {
            $0.pokeAPIClient.fetchPokemonList = { _, _ in
                // 通信させないため、画像は file URL にする（読み込みは失敗して代わりの表示になる）。
                let sprite = URL(filePath: "/")
                return PokemonListDTO(
                    items: [
                        .init(id: 1, name: "bulbasaur", spriteURL: sprite),
                        .init(id: 4, name: "charmander", spriteURL: sprite),
                        .init(id: 7, name: "squirtle", spriteURL: sprite),
                    ],
                    hasNext: false)
            }
        }
    }
}
