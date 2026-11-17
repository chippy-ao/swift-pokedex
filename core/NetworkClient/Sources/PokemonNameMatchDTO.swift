/// 名前の検索で当たった 1 件。名前は全部の言語で運び、どれを出すかは Domain が 1 回だけ選ぶ（ADR-0007）。
package struct PokemonNameMatchDTO: Equatable, Sendable {
    package var id: Int
    package var names: [LocalizedNameDTO]

    package init(id: Int, names: [LocalizedNameDTO]) {
        self.id = id
        self.names = names
    }
}
