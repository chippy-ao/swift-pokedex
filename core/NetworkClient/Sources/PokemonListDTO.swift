import Foundation

/// ポケモン一覧の 1 ページぶん。通信方式（REST など）の仕組みを知らなくても使える値だけを持つ。
package struct PokemonListDTO: Equatable, Sendable {
    package struct Entry: Equatable, Sendable {
        package var id: Int
        package var name: String
        package var spriteURL: URL

        package init(id: Int, name: String, spriteURL: URL) {
            self.id = id
            self.name = name
            self.spriteURL = spriteURL
        }
    }

    package var items: [Entry]
    package var hasNext: Bool

    package init(items: [Entry], hasNext: Bool) {
        self.items = items
        self.hasNext = hasNext
    }
}
