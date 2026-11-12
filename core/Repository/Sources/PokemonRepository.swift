import Dependencies
import DependenciesMacros
import Foundation
import Model
import NetworkClient

@DependencyClient
public struct PokemonRepository: Sendable {
    public var fetchList: @Sendable (_ limit: Int, _ offset: Int) async throws -> PokemonListPage
}

extension PokemonRepository: TestDependencyKey {
    public static let testValue = PokemonRepository()

    public static let previewValue = PokemonRepository(
        fetchList: { _, _ in
            PokemonListPage(
                items: [
                    PokemonListEntry(
                        id: 1, identifier: "bulbasaur",
                        names: [
                            LocalizedName(languageCode: .en, name: "Bulbasaur"),
                            LocalizedName(languageCode: .jaHrkt, name: "フシギダネ"),
                        ],
                        spriteURL: URL(
                            string:
                                "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png"
                        )!)
                ],
                hasNext: false)
        }
    )
}

extension PokemonRepository: DependencyKey {
    public static let liveValue = PokemonRepository(
        fetchList: { limit, offset in
            @Dependency(\.pokeAPIClient) var client
            do {
                let dto = try await client.fetchPokemonList(limit, offset)
                let items = dto.items.map {
                    PokemonListEntry(
                        id: $0.id, identifier: $0.name, names: [], spriteURL: $0.spriteURL)
                }
                return PokemonListPage(items: items, hasNext: dto.hasNext)
            } catch {
                throw loadError(from: error)
            }
        }
    )
}

/// NetworkClient のエラーを画面に見せる `LoadError` に変える。
/// キャンセルは失敗ではないので変換せずそのまま投げ直す。
private func loadError(from error: any Error) -> any Error {
    switch error {
    case is CancellationError, is LoadError:
        return error
    case PokeAPIError.offline:
        return LoadError.offline
    default:
        return LoadError.unavailable
    }
}

extension DependencyValues {
    public var pokemonRepository: PokemonRepository {
        get { self[PokemonRepository.self] }
        set { self[PokemonRepository.self] = newValue }
    }
}
