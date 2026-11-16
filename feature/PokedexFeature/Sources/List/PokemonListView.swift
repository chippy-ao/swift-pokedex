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
            .navigationTitle(Text(.listNavigationTitle))
            .task { store.send(.onAppear) }
    }

    @ViewBuilder
    private var content: some View {
        let state = store.state
        if state.items.isEmpty {
            switch state.phase {
            case .failed(let error):
                VStack(spacing: Spacing.large) {
                    Text(Self.message(for: error))
                        .multilineTextAlignment(.center)
                    Button(.listRetryButton) { store.send(.retryTapped) }
                        .buttonStyle(.glassProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            default:
                skeleton
            }
        } else {
            List {
                ForEach(state.items) { pokemon in
                    // 行タップは Store を通さず、Route を path に積む（README の「画面遷移」）。
                    NavigationLink(value: PokedexRoute.detail(id: pokemon.id)) {
                        PokemonRow(pokemon: pokemon)
                    }
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

    /// 初回の読み込み中。行と同じ形の仮の行に shimmer を重ねる。
    private var skeleton: some View {
        List(Self.placeholderItems) { pokemon in
            // shimmer は背景が透明な行ごとにかける（List 全体だと光が行の全面を流れる）。
            PokemonRow(pokemon: pokemon)
                .redacted(reason: .placeholder)
                .shimmering()
        }
        .listStyle(.plain)
        .scrollDisabled(true)
        // 行ごとに読み上げさせず、1 つのラベルにまとめる。
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(.listLoadingAccessibilityLabel))
    }

    private static let placeholderItems: [PokemonSummary] = (1...10).map {
        // 通信させないため、file URL を渡す（強制アンラップも避けられる）。
        // 読み込みは画像として失敗し、RemoteImage の失敗時の表示になる（redacted で隠れる）。
        // 実機の見え方は未確認。
        PokemonSummary(id: $0, name: "placeholder", spriteURL: URL(filePath: "/"))
    }

    @ViewBuilder
    private func footer(_ state: PokemonListStore.State) -> some View {
        switch state.phase {
        case .loading:
            ProgressView().frame(maxWidth: .infinity)
        case .failed(let error):
            VStack(spacing: Spacing.small) {
                Text(Self.message(for: error))
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                Button(.listRetryButton) { store.send(.retryTapped) }
            }
            .frame(maxWidth: .infinity)
        case .idle, .loaded:
            EmptyView()
        }
    }

    private static func message(for error: LoadError) -> LocalizedStringResource {
        switch error {
        case .offline: .listErrorOffline
        case .unavailable: .listErrorUnavailable
        }
    }
}

// Preview の場面とデータは PokemonListScenario にある（スナップショットのテストと共有）。
#if DEBUG
    #Preview("読み込み済み") { PokemonListScenario.loaded.makeView() }
    #Preview("初回の読み込み中") { PokemonListScenario.loading.makeView() }
    #Preview("初回のエラー（オフライン）") { PokemonListScenario.errorOffline.makeView() }
#endif
