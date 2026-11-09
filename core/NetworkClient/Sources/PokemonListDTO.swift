import Foundation

/// ポケモン一覧の 1 ページぶん。通信方式（REST など）の仕組みを知らなくても使える値だけを持つ。
public struct PokemonListDTO: Equatable, Sendable {
    public struct Entry: Equatable, Sendable {
        public var id: Int
        public var name: String
        public var spriteURL: URL

        public init(id: Int, name: String, spriteURL: URL) {
            self.id = id
            self.name = name
            self.spriteURL = spriteURL
        }
    }

    public var items: [Entry]
    public var hasNext: Bool

    public init(items: [Entry], hasNext: Bool) {
        self.items = items
        self.hasNext = hasNext
    }
}
