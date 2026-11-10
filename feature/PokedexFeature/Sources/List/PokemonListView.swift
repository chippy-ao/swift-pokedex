import Dependencies
import DesignSystem
import Domain
import Foundation
import Model
import SharedUI
import SwiftUI

public struct PokemonListView: View {
    @State private var store: PokemonListStore

    public init() {
        self.init(store: PokemonListStore())
    }

    init(store: PokemonListStore) {
        _store = State(initialValue: store)
    }

    public var body: some View {
        content
            .navigationTitle("ポケモン図鑑")
            .task { store.send(.onAppear) }
    }

    @ViewBuilder
    private var content: some View {
        let state = store.state
        if state.items.isEmpty {
            switch state.phase {
            case .failed(let error):
                VStack(spacing: 16) {
                    Text(Self.message(for: error))
                        .multilineTextAlignment(.center)
                    Button("再試行") { store.send(.retryTapped) }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            default:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            List {
                ForEach(state.items) { pokemon in
                    PokemonRow(pokemon: pokemon)
                        .onAppear {
                            if pokemon.id == state.items.last?.id {
                                store.send(.reachedBottom)
                            }
                        }
                }
                footer(state)
            }
            .listStyle(.plain)
        }
    }

    @ViewBuilder
    private func footer(_ state: PokemonListStore.State) -> some View {
        switch state.phase {
        case .loading:
            ProgressView().frame(maxWidth: .infinity)
        case .failed(let error):
            VStack(spacing: 8) {
                Text(Self.message(for: error))
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                Button("再試行") { store.send(.retryTapped) }
            }
            .frame(maxWidth: .infinity)
        case .idle, .loaded:
            EmptyView()
        }
    }

    private static func message(for error: LoadError) -> LocalizedStringKey {
        switch error {
        case .offline: "ネットワークに接続できません。接続を確認してください。"
        case .unavailable: "読み込めませんでした。時間をおいて再試行してください。"
        }
    }
}

// Preview は fetchPokemonPage だけを差し替える。feature は Domain の UseCase しか知らない。
private func previewSummary(id: Int, name: String) -> PokemonSummary {
    PokemonSummary(
        id: id, name: name,
        spriteURL: URL(
            string:
                "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png"
        )!)
}

#Preview("読み込み済み") {
    // ViewBuilder の中では `_ =` と書けないので `let _` を使う
    // swiftlint:disable:next redundant_discardable_let
    let _ = prepareDependencies {
        $0.fetchPokemonPage.execute = { _ in
            PokemonPage(
                items: [
                    previewSummary(id: 1, name: "bulbasaur"),
                    previewSummary(id: 4, name: "charmander"),
                    previewSummary(id: 7, name: "squirtle"),
                    previewSummary(id: 25, name: "pikachu"),
                ],
                hasNext: false)
        }
    }
    NavigationStack { PokemonListView() }
}

#Preview("初回の読み込み中") {
    // ViewBuilder の中では `_ =` と書けないので `let _` を使う
    // swiftlint:disable:next redundant_discardable_let
    let _ = prepareDependencies {
        $0.fetchPokemonPage.execute = { _ in
            try await Task.sleep(for: .seconds(3600))
            return PokemonPage(items: [], hasNext: false)
        }
    }
    NavigationStack { PokemonListView() }
}

#Preview("初回のエラー（オフライン）") {
    // ViewBuilder の中では `_ =` と書けないので `let _` を使う
    // swiftlint:disable:next redundant_discardable_let
    let _ = prepareDependencies {
        $0.fetchPokemonPage.execute = { _ in throw LoadError.offline }
    }
    NavigationStack { PokemonListView() }
}
