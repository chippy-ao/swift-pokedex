import Foundation

/// 一覧の 1 件ぶん。画面に出す名前はまだ選ばず、全部の言語の名前を持つ。
/// どの言語で出すかは Domain の UseCase が決める（`PokemonSummary` になる）。
package struct PokemonListEntry: Equatable, Sendable, Identifiable {
    package var id: Int
    /// PokeAPI の識別子（`mr-mime` など）。どの言語の名前も無いときの最後の手段。
    package var identifier: String
    package var names: [LocalizedName]
    package var spriteURL: URL

    package init(id: Int, identifier: String, names: [LocalizedName], spriteURL: URL) {
        self.id = id
        self.identifier = identifier
        self.names = names
        self.spriteURL = spriteURL
    }
}

/// `PokemonListEntry` の 1 ページぶん。
package struct PokemonListPage: Equatable, Sendable {
    package var items: [PokemonListEntry]
    package var hasNext: Bool

    package init(items: [PokemonListEntry], hasNext: Bool) {
        self.items = items
        self.hasNext = hasNext
    }
}
