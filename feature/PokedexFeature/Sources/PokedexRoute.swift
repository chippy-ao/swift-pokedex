import SwiftUI

/// PokedexFeature の中の遷移先。NavigationStack の path に積む。
/// path を持つ Router は App ターゲットにあり、feature は Router を知らない。
public enum PokedexRoute: Hashable, Sendable {
    case detail(id: Int)
}

extension View {
    /// `PokedexRoute` から画面への対応表。NavigationStack の中身に 1 回だけ付ける。
    public func pokedexDestinations() -> some View {
        navigationDestination(for: PokedexRoute.self) { route in
            switch route {
            case .detail(let id):
                PokemonDetailView(id: id)
            }
        }
    }
}
