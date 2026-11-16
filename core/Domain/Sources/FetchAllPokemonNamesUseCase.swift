import Dependencies
import DependenciesMacros
import Foundation
import Model
import Repository

/// 検索のために、全件の名前を設定言語で返す（API は叩かない。名前の表だけから作る）。
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
            @Dependency(\.pokemonRepository) var repository
            @Dependency(\.preferredLocalization) var preferredLocalization
            let entries = try await repository.fetchAllNames()
            // 一覧と同じ規則で、フォーム違いは入れない。使える名前が無い番号は、空の行になるので入れない。
            return entries.compactMap { entry in
                guard entry.id <= FetchPokemonPageUseCase.lastListedID,
                    let name = localizedText(in: entry.names, localization: preferredLocalization)
                else { return nil }
                return PokemonSummary(id: entry.id, name: name, spriteURL: entry.spriteURL)
            }
        }
    )
}

extension DependencyValues {
    package var fetchAllPokemonNames: FetchAllPokemonNamesUseCase {
        get { self[FetchAllPokemonNamesUseCase.self] }
        set { self[FetchAllPokemonNamesUseCase.self] = newValue }
    }
}
