import Foundation

/// 一覧の 1 行ぶん。
package struct PokemonSummary: Equatable, Hashable, Sendable, Identifiable {
    package var id: Int
    package var name: String
    package var spriteURL: URL

    package init(id: Int, name: String, spriteURL: URL) {
        self.id = id
        self.name = name
        self.spriteURL = spriteURL
    }
}
