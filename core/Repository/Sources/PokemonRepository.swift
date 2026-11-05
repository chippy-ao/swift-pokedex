import Dependencies
import DependenciesMacros
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
    // 枠のみ。DTO から Model への変換とエラー変換は後続のコミットで実装する
    public static let liveValue = PokemonRepository(
        fetchList: { _, _ in
            throw NotImplemented()
        }
    )
}

private struct NotImplemented: Error {}

extension DependencyValues {
    public var pokemonRepository: PokemonRepository {
        get { self[PokemonRepository.self] }
        set { self[PokemonRepository.self] = newValue }
    }
}
