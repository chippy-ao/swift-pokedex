#if DEBUG
    import Dependencies
    import Domain
    import Foundation
    import Model
    import SwiftUI

    /// 詳細画面の「Preview とスナップショットのための場面」。製品のコードからは使わない。
    ///
    /// Preview（#Preview）と、スナップショットのテスト（app/PokedexSnapshotTests）が同じ場面と
    /// 同じデータを使うために、ここに 1 か所で定義する。場面を足したら、スナップショットも自動で増える
    /// （`CaseIterable`）。
    ///
    /// `public` なのは、スナップショットのテストが Package.swift の外（app/App.xcodeproj）にあり、
    /// `package` や `@testable` では見えないため（ADR-0020）。Release には入らないよう `#if DEBUG` で囲む。
    ///
    /// feature は Domain の UseCase しか知らないので、差し替えるのは fetchPokemonDetail だけ。
    /// UseCase ごと差し替えるので名前の言語は選ばれない。Preview の既定の言語（英語）の文言とそろえて英語にする。
    public enum PokemonDetailScenario: String, CaseIterable, Sendable {
        case loaded
        case loading
        case errorOffline

        /// 画面に出す前の状態の画面。表示されたとき（`.task`）に、画面自身が読み込みを始める。Preview 用。
        @MainActor
        public func makeView() -> some View {
            NavigationStack { PokemonDetailView(store: makeStore()) }
        }

        /// 読み込みが終わった状態の画面。読み込みが終わるのを待ってから返す。スナップショット用。
        /// `loading` は終わらない場面なので、待たない。
        @MainActor
        public func makeSettledView() async -> some View {
            let store = makeStore()
            if self != .loading {
                await store.send(.onAppear)?.value
            }
            return NavigationStack { PokemonDetailView(store: store) }
        }

        @MainActor
        private func makeStore() -> PokemonDetailStore {
            withDependencies {
                switch self {
                case .loaded:
                    $0.fetchPokemonDetail.execute = { _ in Self.detail }
                case .loading:
                    $0.fetchPokemonDetail.execute = { _ in
                        try await Task.sleep(for: .seconds(3600))
                        return Self.detail
                    }
                case .errorOffline:
                    $0.fetchPokemonDetail.execute = { _ in throw LoadError.offline }
                }
            } operation: {
                PokemonDetailStore(id: 1)
            }
        }

        // アートワークの URL は、通信させないため file URL にする（読み込みは失敗して代わりの表示になる）。
        // 本物の URL だと、Preview もスナップショットも通信し、画像の出方が通信しだいで変わる。
        private static let detail = PokemonDetail(
            id: 1, name: "Bulbasaur", genus: "Seed Pokémon", types: [.grass, .poison],
            stats: [
                PokemonStat(kind: .hp, value: 45), PokemonStat(kind: .attack, value: 49),
                PokemonStat(kind: .defense, value: 49),
                PokemonStat(kind: .specialAttack, value: 65),
                PokemonStat(kind: .specialDefense, value: 65), PokemonStat(kind: .speed, value: 45),
            ],
            heightInMeters: 0.7, weightInKilograms: 6.9,
            artworkURL: URL(filePath: "/"))
    }
#endif
