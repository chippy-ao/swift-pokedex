/// 一覧の 1 ページぶん。
package struct PokemonPage: Equatable, Sendable {
    package var items: [PokemonSummary]
    package var hasNext: Bool

    package init(items: [PokemonSummary], hasNext: Bool) {
        self.items = items
        self.hasNext = hasNext
    }
}
