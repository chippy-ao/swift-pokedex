import Dependencies
import DependenciesMacros
import Foundation
import Model

@DependencyClient
package struct PokeAPIClient: Sendable {
    package var fetchPokemonList:
        @Sendable (_ limit: Int, _ offset: Int) async throws -> PokemonListDTO
    /// 全 species の名前（species の ID をキーに、言語ごとの名前）。
    /// 呼ぶ側からは API の 1 エンドポイントと見分けがつかない（実装が何から答えるかは知らない）。
    package var fetchAllPokemonSpeciesNames: @Sendable () async throws -> [Int: [LocalizedNameDTO]]
    /// 名前で検索する。`language` の名前が `query` に部分一致する species を、番号の小さい順に返す。
    /// 空の `query` は全件。当たった species の名前は全部の言語で返す。
    ///
    /// 今は同梱の名前の表を、実装（NetworkClientURLSession）が端末内で絞っている。PokeAPI に名前検索の
    /// API が無く、`GET /pokemon` が日本語名を返さないための回避策（docs/adr/0018-bundled-pokemon-names-table.md）。
    /// API で検索できるようになったら、この interface は変えず、実装だけを差し替える。
    /// 通信するようになったら、呼ぶ側の画面で debounce と前の検索のキャンセルが要る
    /// （今は端末内で一瞬で終わるので入れていない）。
    package var searchPokemonNames:
        @Sendable (_ query: String, _ language: LanguageCode) async throws -> [PokemonNameMatchDTO]
    package var fetchPokemonDetail: @Sendable (_ id: Int) async throws -> PokemonDetailDTO
    package var fetchPokemonSpecies: @Sendable (_ speciesID: Int) async throws -> PokemonSpeciesDTO
}

extension PokeAPIClient: TestDependencyKey {
    // 呼ばれたらテストが失敗する（@DependencyClient が未実装のクロージャを作る）
    package static let testValue = PokeAPIClient()

    package static let previewValue = PokeAPIClient(
        fetchPokemonList: { _, _ in
            PokemonListDTO(
                items: [
                    .init(
                        id: 1, name: "bulbasaur",
                        spriteURL: URL(
                            string:
                                "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png"
                        )!)
                ],
                hasNext: false
            )
        },
        fetchAllPokemonSpeciesNames: {
            [
                1: [
                    LocalizedNameDTO(languageCode: "en", name: "Bulbasaur"),
                    LocalizedNameDTO(languageCode: "ja-hrkt", name: "フシギダネ"),
                ]
            ]
        },
        searchPokemonNames: { _, _ in
            [
                PokemonNameMatchDTO(
                    id: 1,
                    names: [
                        LocalizedNameDTO(languageCode: "en", name: "Bulbasaur"),
                        LocalizedNameDTO(languageCode: "ja-hrkt", name: "フシギダネ"),
                    ])
            ]
        },
        fetchPokemonDetail: { _ in
            PokemonDetailDTO(
                id: 1, name: "bulbasaur", speciesID: 1, types: ["grass", "poison"],
                stats: [
                    .init(name: "hp", baseValue: 45), .init(name: "attack", baseValue: 49),
                    .init(name: "defense", baseValue: 49),
                    .init(name: "special-attack", baseValue: 65),
                    .init(name: "special-defense", baseValue: 65),
                    .init(name: "speed", baseValue: 45),
                ],
                height: 7, weight: 69,
                artworkURL: URL(
                    string:
                        "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/"
                        + "official-artwork/1.png"
                ))
        },
        fetchPokemonSpecies: { _ in
            PokemonSpeciesDTO(
                names: [
                    LocalizedNameDTO(languageCode: "en", name: "Bulbasaur"),
                    LocalizedNameDTO(languageCode: "ja-hrkt", name: "フシギダネ"),
                ],
                genera: [
                    LocalizedNameDTO(languageCode: "en", name: "Seed Pokémon"),
                    LocalizedNameDTO(languageCode: "ja-hrkt", name: "たねポケモン"),
                ])
        }
    )
}

extension DependencyValues {
    package var pokeAPIClient: PokeAPIClient {
        get { self[PokeAPIClient.self] }
        set { self[PokeAPIClient.self] = newValue }
    }
}
