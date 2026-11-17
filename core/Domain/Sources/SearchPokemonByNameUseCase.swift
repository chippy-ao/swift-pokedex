import Dependencies
import DependenciesMacros
import Foundation
import Model
import Repository

/// 名前で検索する。
@DependencyClient
package struct SearchPokemonByNameUseCase: Sendable {
    package var execute: @Sendable (_ query: String) async throws -> [PokemonSummary]
}

extension SearchPokemonByNameUseCase: TestDependencyKey {
    package static let testValue = SearchPokemonByNameUseCase()
}

extension SearchPokemonByNameUseCase: DependencyKey {
    package static let liveValue = SearchPokemonByNameUseCase(
        execute: { _ in
            []
        }
    )
}

extension DependencyValues {
    package var searchPokemonByName: SearchPokemonByNameUseCase {
        get { self[SearchPokemonByNameUseCase.self] }
        set { self[SearchPokemonByNameUseCase.self] = newValue }
    }
}
