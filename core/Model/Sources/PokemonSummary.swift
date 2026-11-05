/// 一覧の 1 行ぶん。
public struct PokemonSummary: Equatable, Hashable, Sendable, Identifiable {
    public var id: Int
    public var name: String

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

/// 一覧の 1 ページぶん。
public struct PokemonPage: Equatable, Sendable {
    public var items: [PokemonSummary]
    public var hasNext: Bool

    public init(items: [PokemonSummary], hasNext: Bool) {
        self.items = items
        self.hasNext = hasNext
    }
}
