import Foundation

/// 詳細の 1 件ぶん。画面に出す名前と分類はまだ選ばず、全部の言語のものを持つ。
/// どの言語で出すかは Domain の UseCase が決める（`PokemonDetail` になる）。
package struct PokemonDetailEntry: Equatable, Sendable, Identifiable {
    package var id: Int
    /// PokeAPI の識別子（`mr-mime` など）。どの言語の名前も無いときの最後の手段。
    package var identifier: String
    package var names: [LocalizedName]
    /// 分類（「たねポケモン」など）。名前と同じく言語ごと。
    package var genera: [LocalizedName]
    package var types: [PokemonType]
    package var stats: [PokemonStat]
    /// 単位は m。
    package var heightInMeters: Double
    /// 単位は kg。
    package var weightInKilograms: Double
    package var artworkURL: URL?

    package init(
        id: Int, identifier: String, names: [LocalizedName], genera: [LocalizedName],
        types: [PokemonType], stats: [PokemonStat], heightInMeters: Double,
        weightInKilograms: Double, artworkURL: URL?
    ) {
        self.id = id
        self.identifier = identifier
        self.names = names
        self.genera = genera
        self.types = types
        self.stats = stats
        self.heightInMeters = heightInMeters
        self.weightInKilograms = weightInKilograms
        self.artworkURL = artworkURL
    }
}

/// 詳細画面に出す 1 件ぶん。
package struct PokemonDetail: Equatable, Sendable, Identifiable {
    package var id: Int
    package var name: String
    /// 分類。どの言語も無いときは nil（画面には出さない）。
    package var genus: String?
    package var types: [PokemonType]
    package var stats: [PokemonStat]
    /// 単位は m。
    package var heightInMeters: Double
    /// 単位は kg。
    package var weightInKilograms: Double
    package var artworkURL: URL?

    package init(
        id: Int, name: String, genus: String?, types: [PokemonType], stats: [PokemonStat],
        heightInMeters: Double, weightInKilograms: Double, artworkURL: URL?
    ) {
        self.id = id
        self.name = name
        self.genus = genus
        self.types = types
        self.stats = stats
        self.heightInMeters = heightInMeters
        self.weightInKilograms = weightInKilograms
        self.artworkURL = artworkURL
    }

    /// 種族値の合計。
    package var statTotal: Int {
        stats.reduce(0) { $0 + $1.value }
    }
}
