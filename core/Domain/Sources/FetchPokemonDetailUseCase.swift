import Dependencies
import DependenciesMacros
import Foundation
import Model
import Repository

/// 図鑑の詳細を 1 件取得する。名前と分類をアプリの言語で 1 つ選ぶ。
@DependencyClient
package struct FetchPokemonDetailUseCase: Sendable {
    package var execute: @Sendable (_ id: Int) async throws -> PokemonDetail
}

extension FetchPokemonDetailUseCase: TestDependencyKey {
    package static let testValue = FetchPokemonDetailUseCase()
}

extension FetchPokemonDetailUseCase: DependencyKey {
    package static let liveValue = FetchPokemonDetailUseCase(
        execute: { id in
            @Dependency(\.pokemonRepository) var repository
            @Dependency(\.preferredLocalization) var preferredLocalization
            let entry = try await repository.fetchDetail(id)
            return PokemonDetail(
                id: entry.id,
                name: displayName(
                    from: entry.names, identifier: entry.identifier,
                    localization: preferredLocalization),
                genus: localizedText(in: entry.genera, localization: preferredLocalization),
                types: entry.types, stats: entry.stats,
                heightInMeters: entry.heightInMeters, weightInKilograms: entry.weightInKilograms,
                artworkURL: entry.artworkURL)
        }
    )
}

extension DependencyValues {
    package var fetchPokemonDetail: FetchPokemonDetailUseCase {
        get { self[FetchPokemonDetailUseCase.self] }
        set { self[FetchPokemonDetailUseCase.self] = newValue }
    }
}
