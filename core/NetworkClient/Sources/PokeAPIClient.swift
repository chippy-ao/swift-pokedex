import Dependencies
import DependenciesMacros

@DependencyClient
public struct PokeAPIClient: Sendable {
    public var fetchPokemonList:
        @Sendable (_ limit: Int, _ offset: Int) async throws -> PokemonListDTO
}

extension PokeAPIClient: TestDependencyKey {
    // 呼ばれたらテストが失敗する（@DependencyClient が未実装のクロージャを作る）
    public static let testValue = PokeAPIClient()

    public static let previewValue = PokeAPIClient(
        fetchPokemonList: { _, _ in
            PokemonListDTO(
                count: 1,
                results: [.init(name: "bulbasaur", url: "https://pokeapi.co/api/v2/pokemon/1/")]
            )
        }
    )
}

extension DependencyValues {
    public var pokeAPIClient: PokeAPIClient {
        get { self[PokeAPIClient.self] }
        set { self[PokeAPIClient.self] = newValue }
    }
}
