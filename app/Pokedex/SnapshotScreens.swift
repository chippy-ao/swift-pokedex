#if DEBUG
    import PokedexFeature
    import SwiftUI

    /// スナップショットのテスト（app/PokedexSnapshotTests）が撮る画面の一覧。製品のコードからは使わない。
    ///
    /// テストが PokedexFeature を直接リンクすると、App と同じパッケージのモジュールを 2 つの target が
    /// リンクすることになり、Xcode が動的ライブラリにして型が複製され、App の liveValue が見つからなくなる。
    /// そのため、テストは `@testable import Pokedex` で App のこの入口だけを使う（ADR-0020）。
    /// 場面の定義は PokedexFeature の PokemonDetailScenario にあり、Preview と共有している。
    @MainActor
    enum SnapshotScreens {
        struct Screen {
            let name: String
            let view: AnyView
        }

        /// 詳細画面の場面。読み込みが終わった状態にして返す。
        /// `loading` は撮らない。ProgressView は回り続けるので、撮るたびに羽根の濃淡の位置が変わり、
        /// 毎回違う画像になって比べられない。Preview には残してある。
        static func pokemonDetail() async -> [Screen] {
            var screens: [Screen] = []
            for scenario in PokemonDetailScenario.allCases where scenario != .loading {
                screens.append(
                    Screen(name: scenario.rawValue, view: AnyView(await scenario.makeSettledView()))
                )
            }
            return screens
        }
    }
#endif
