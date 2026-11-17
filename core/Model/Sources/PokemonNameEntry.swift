import Foundation

/// 名前の表の 1 件ぶん（検索用）。表は番号と名前だけなので、`PokemonListEntry` と違って識別子を持たない。
/// どの言語で出すかは Domain の UseCase が決める。
package struct PokemonNameEntry: Equatable, Sendable, Identifiable {
    package var id: Int
    package var names: [LocalizedName]
    package var spriteURL: URL

    package init(id: Int, names: [LocalizedName], spriteURL: URL) {
        self.id = id
        self.names = names
        self.spriteURL = spriteURL
    }
}
