/// species の、詳細画面に使う部分。言語コードは PokeAPI の文字列のまま。
package struct PokemonSpeciesDTO: Equatable, Sendable {
    package var names: [LocalizedNameDTO]
    /// 分類（genus。「たねポケモン」など）。`LocalizedNameDTO.name` に genus を入れる。
    package var genera: [LocalizedNameDTO]

    package init(names: [LocalizedNameDTO], genera: [LocalizedNameDTO]) {
        self.names = names
        self.genera = genera
    }
}
