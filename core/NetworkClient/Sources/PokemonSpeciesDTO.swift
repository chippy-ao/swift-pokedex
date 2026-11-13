/// species の、詳細画面に使う部分。言語コードは PokeAPI の文字列のまま。
public struct PokemonSpeciesDTO: Equatable, Sendable {
    public var names: [LocalizedNameDTO]
    /// 分類（genus。「たねポケモン」など）。`LocalizedNameDTO.name` に genus を入れる。
    public var genera: [LocalizedNameDTO]

    public init(names: [LocalizedNameDTO], genera: [LocalizedNameDTO]) {
        self.names = names
        self.genera = genera
    }
}
