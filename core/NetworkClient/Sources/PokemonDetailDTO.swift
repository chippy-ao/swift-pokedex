import Foundation

/// ポケモン 1 匹の詳細。通信方式（REST など）の仕組みを知らなくても使える値だけを持つ。
/// タイプと種族値の識別子は PokeAPI の文字列のまま（Model の型への変換は Repository で行う）。
package struct PokemonDetailDTO: Equatable, Sendable {
    package struct Stat: Equatable, Sendable {
        /// PokeAPI の識別子（`special-attack` など）。
        package var name: String
        package var baseValue: Int

        package init(name: String, baseValue: Int) {
            self.name = name
            self.baseValue = baseValue
        }
    }

    package var id: Int
    package var name: String
    /// species の番号。フォーム違い（ID > 10000）では pokemon の番号と違う。
    package var speciesID: Int
    /// PokeAPI の識別子（`grass` など）。スロットの順。
    package var types: [String]
    package var stats: [Stat]
    /// 0.1 m 単位の整数（PokeAPI の値のまま）。
    package var height: Int
    /// 0.1 kg 単位の整数（PokeAPI の値のまま）。
    package var weight: Int
    package var artworkURL: URL?

    package init(
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
