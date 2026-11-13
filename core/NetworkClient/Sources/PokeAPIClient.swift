import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
package struct PokeAPIClient: Sendable {
    package var fetchPokemonList:
        @Sendable (_ limit: Int, _ offset: Int) async throws -> PokemonListDTO
    /// 全 species の名前（species の ID をキーに、言語ごとの名前）。
    /// 呼ぶ側からは API の 1 エンドポイントと見分けがつかない（実装が何から答えるかは知らない）。
    package var fetchAllPokemonSpeciesNames: @Sendable () async throws -> [Int: [LocalizedNameDTO]]
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
