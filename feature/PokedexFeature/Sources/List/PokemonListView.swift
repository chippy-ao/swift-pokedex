import DesignSystem
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
