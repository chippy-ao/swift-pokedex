import Dependencies
import DependenciesMacros
import Foundation
import Model
import Repository

/// 検索のために、全件の名前を設定言語で返す。
@DependencyClient
package struct FetchAllPokemonNamesUseCase: Sendable {
    package var execute: @Sendable () async throws -> [PokemonSummary]
}

extension FetchAllPokemonNamesUseCase: TestDependencyKey {
    package static let testValue = FetchAllPokemonNamesUseCase()
}

extension FetchAllPokemonNamesUseCase: DependencyKey {
    package static let liveValue = FetchAllPokemonNamesUseCase(
        execute: {
            []
        }
    )
}

extension DependencyValues {
    package var fetchAllPokemonNames: FetchAllPokemonNamesUseCase {
        get { self[FetchAllPokemonNamesUseCase.self] }
        set { self[FetchAllPokemonNamesUseCase.self] = newValue }
    }
}
