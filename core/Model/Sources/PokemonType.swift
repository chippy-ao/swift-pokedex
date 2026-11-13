/// ポケモンのタイプ 18 種類。rawValue は PokeAPI の識別子（`grass` など）。
///
/// PokeAPI の `stellar` と `unknown` は入れない（図鑑の通常のポケモンが持たない）。
/// 知らない識別子は Repository がそのタイプだけ落とす（取得の失敗にはしない）。
package enum PokemonType: String, CaseIterable, Hashable, Sendable {
    case normal
    case fire
    case water
    case electric
    case grass
    case ice
    case fighting
    case poison
    case ground
    case flying
    case psychic
    case bug
    case rock
    case ghost
    case dragon
    case dark
    case steel
    case fairy
}
