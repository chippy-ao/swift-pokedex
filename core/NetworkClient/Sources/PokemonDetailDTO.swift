import Foundation

/// ポケモン 1 匹の詳細。通信方式（REST など）の仕組みを知らなくても使える値だけを持つ。
/// タイプと種族値の識別子は PokeAPI の文字列のまま（Model の型への変換は Repository で行う）。
public struct PokemonDetailDTO: Equatable, Sendable {
    public struct Stat: Equatable, Sendable {
        /// PokeAPI の識別子（`special-attack` など）。
        public var name: String
        public var baseValue: Int

        public init(name: String, baseValue: Int) {
            self.name = name
            self.baseValue = baseValue
        }
    }

    public var id: Int
    public var name: String
    /// species の番号。フォーム違い（ID > 10000）では pokemon の番号と違う。
    public var speciesID: Int
    /// PokeAPI の識別子（`grass` など）。スロットの順。
    public var types: [String]
    public var stats: [Stat]
    /// 0.1 m 単位の整数（PokeAPI の値のまま）。
    public var height: Int
    /// 0.1 kg 単位の整数（PokeAPI の値のまま）。
    public var weight: Int
    public var artworkURL: URL?

    public init(
        id: Int, name: String, speciesID: Int, types: [String], stats: [Stat], height: Int,
        weight: Int, artworkURL: URL?
    ) {
        self.id = id
        self.name = name
        self.speciesID = speciesID
        self.types = types
        self.stats = stats
        self.height = height
        self.weight = weight
        self.artworkURL = artworkURL
    }
}
