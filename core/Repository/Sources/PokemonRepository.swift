import Dependencies
import DependenciesMacros
import Foundation
import Model
import NetworkClient

@DependencyClient
public struct PokemonRepository: Sendable {
    public var fetchList: @Sendable (_ limit: Int, _ offset: Int) async throws -> PokemonPage
}

extension PokemonRepository: TestDependencyKey {
    public static let testValue = PokemonRepository()

    public static let previewValue = PokemonRepository(
        fetchList: { _, _ in
            PokemonPage(
                items: [
                    PokemonSummary(
                        id: 1, name: "bulbasaur",
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
                    PokemonSummary(id: $0.id, name: $0.name, spriteURL: $0.spriteURL)
                }
                return PokemonPage(items: items, hasNext: dto.hasNext)
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
