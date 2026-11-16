#if DEBUG
    import Dependencies
    import Domain
    import Foundation
    import Model
    import SwiftUI

    /// 一覧画面の「Preview とスナップショットのための場面」。製品のコードからは使わない。
    ///
    /// Preview（#Preview）と、スナップショットのテスト（app/PokedexSnapshotTests）が同じ場面と
    /// 同じデータを使うために、ここに 1 か所で定義する。場面を足したら、スナップショットも自動で増える
    /// （`CaseIterable`）。
    ///
    /// `public` なのは、スナップショットのテストが Package.swift の外（app/App.xcodeproj）にあり、
    /// `package` や `@testable` では見えないため（ADR-0020）。Release には入らないよう `#if DEBUG` で囲む。
    ///
    /// feature は Domain の UseCase しか知らないので、差し替えるのは fetchPokemonPage だけ。
    /// UseCase ごと差し替えるので名前の言語は選ばれない。Preview の既定の言語（英語）の文言とそろえて英語にする。
    public enum PokemonListScenario: String, CaseIterable, Sendable {
        case loaded
        case loading
        case errorOffline

        /// 画面に出す前の状態の画面。表示されたとき（`.task`）に、画面自身が読み込みを始める。Preview 用。
        @MainActor
        public func makeView() -> some View {
            NavigationStack { PokemonListView(store: makeStore()) }
        }

        /// 読み込みが終わった状態の画面。読み込みが終わるのを待ってから返す。スナップショット用。
        /// `loading` は終わらない場面なので、待たない。
        @MainActor
        public func makeSettledView() async -> some View {
            let store = makeStore()
            if self != .loading {
                await store.send(.onAppear)?.value
            }
            return NavigationStack { PokemonListView(store: store) }
        }

        @MainActor
        private func makeStore() -> PokemonListStore {
            withDependencies {
                switch self {
                case .loaded:
                    $0.fetchPokemonPage.execute = { _ in Self.page }
                case .loading:
                    $0.fetchPokemonPage.execute = { _ in
                        try await Task.sleep(for: .seconds(3600))
                        return Self.page
                    }
                case .errorOffline:
                    $0.fetchPokemonPage.execute = { _ in throw LoadError.offline }
                }
            } operation: {
                PokemonListStore()
            }
        }

        // スプライトの URL は、通信させないため file URL にする（読み込みは失敗して代わりの表示になる）。
        // 本物の URL だと、Preview もスナップショットも通信し、画像の出方が通信しだいで変わる。
        private static func summary(id: Int, name: String) -> PokemonSummary {
            PokemonSummary(id: id, name: name, spriteURL: URL(filePath: "/"))
        }

        private static let page = PokemonPage(
            items: [
                summary(id: 1, name: "Bulbasaur"),
                summary(id: 4, name: "Charmander"),
                summary(id: 7, name: "Squirtle"),
                summary(id: 25, name: "Pikachu"),
            ],
            hasNext: false)
    }
#endif
