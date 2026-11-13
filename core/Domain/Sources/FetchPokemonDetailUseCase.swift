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
    // 仮の中身（テスト先行の段階。実装で置き換える）
    package static let liveValue = FetchPokemonDetailUseCase(
        execute: { id in
            PokemonDetail(
                id: id, name: "", genus: nil, types: [], stats: [], heightInMeters: 0,
                weightInKilograms: 0, artworkURL: nil)
        }
    )
}

extension DependencyValues {
    package var fetchPokemonDetail: FetchPokemonDetailUseCase {
        get { self[FetchPokemonDetailUseCase.self] }
        set { self[FetchPokemonDetailUseCase.self] = newValue }
    }
}
