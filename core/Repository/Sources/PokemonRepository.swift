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
            PokemonPage(items: [PokemonSummary(id: 1, name: "bulbasaur")], hasNext: false)
        }
    )
}

extension PokemonRepository: DependencyKey {
    public static let liveValue = PokemonRepository(
        fetchList: { limit, offset in
            @Dependency(\.pokeAPIClient) var client
            do {
                let dto = try await client.fetchPokemonList(limit, offset)
                let items = try dto.results.map { entry in
                    guard let id = pokemonID(fromURL: entry.url) else {
                        // 1 件でも ID を取り出せなければ、ページ全体を失敗にする
                        throw LoadError.unavailable
                    }
                    return PokemonSummary(id: id, name: entry.name)
                }
                return PokemonPage(items: items, hasNext: dto.next != nil)
            } catch {
                throw loadError(from: error)
            }
        }
    )
}

/// `https://pokeapi.co/api/v2/pokemon/25/` の末尾の `25` を取り出す。
private func pokemonID(fromURL url: String) -> Int? {
    url.split(separator: "/").last.flatMap { Int($0) }
}

/// NetworkClient のエラーを画面に見せる `LoadError` に変える。
/// キャンセルは失敗ではないので変換せずそのまま投げ直す。
private func loadError(from error: any Error) -> any Error {
    if error is CancellationError || error is LoadError {
        return error
    }
    if let urlError = error as? URLError {
        switch urlError.code {
        case .cancelled:
            return error
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            return LoadError.offline
        default:
            return LoadError.unavailable
        }
    }
    return LoadError.unavailable
}

extension DependencyValues {
    public var pokemonRepository: PokemonRepository {
        get { self[PokemonRepository.self] }
        set { self[PokemonRepository.self] = newValue }
    }
}
