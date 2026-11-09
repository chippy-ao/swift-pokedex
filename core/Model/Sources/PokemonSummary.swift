import Foundation

/// 一覧の 1 行ぶん。
public struct PokemonSummary: Equatable, Hashable, Sendable, Identifiable {
    public var id: Int
    public var name: String
    public var spriteURL: URL

    public init(id: Int, name: String, spriteURL: URL) {
        self.id = id
        self.name = name
        self.spriteURL = spriteURL
    }
}
