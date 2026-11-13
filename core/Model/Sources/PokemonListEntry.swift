import Foundation

/// 一覧の 1 件ぶん。画面に出す名前はまだ選ばず、全部の言語の名前を持つ。
/// どの言語で出すかは Domain の UseCase が決める（`PokemonSummary` になる）。
public struct PokemonListEntry: Equatable, Sendable, Identifiable {
    public var id: Int
    /// PokeAPI の識別子（`mr-mime` など）。どの言語の名前も無いときの最後の手段。
    public var identifier: String
    public var names: [LocalizedName]
    public var spriteURL: URL

    public init(id: Int, identifier: String, names: [LocalizedName], spriteURL: URL) {
        self.id = id
        self.identifier = identifier
        self.names = names
        self.spriteURL = spriteURL
    }
}

/// `PokemonListEntry` の 1 ページぶん。
public struct PokemonListPage: Equatable, Sendable {
    public var items: [PokemonListEntry]
    public var hasNext: Bool

    public init(items: [PokemonListEntry], hasNext: Bool) {
        self.items = items
        self.hasNext = hasNext
    }
}
