/// 一覧の 1 ページぶん。
public struct PokemonPage: Equatable, Sendable {
    public var items: [PokemonSummary]
    public var hasNext: Bool

    public init(items: [PokemonSummary], hasNext: Bool) {
        self.items = items
        self.hasNext = hasNext
    }
}
