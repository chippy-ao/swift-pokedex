/// 一覧の 1 行ぶん。
public struct PokemonSummary: Equatable, Hashable, Sendable, Identifiable {
    public var id: Int
    public var name: String

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}
