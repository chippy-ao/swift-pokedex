import Dependencies
import DependenciesMacros
import Model
import Repository

/// 図鑑の一覧を 1 ページぶん取得する。
/// 1 ページの件数と、一覧に入れる ID の範囲（図鑑のきまり）はここで決める。
@DependencyClient
package struct FetchPokemonPageUseCase: Sendable {
    package var execute: @Sendable (_ offset: Int) async throws -> PokemonPage
}

extension FetchPokemonPageUseCase: TestDependencyKey {
    package static let testValue = FetchPokemonPageUseCase()
}

extension FetchPokemonPageUseCase: DependencyKey {
    /// 1 ページの件数。PokeAPI の初期値で、1 画面を少し超える量。
    private static let pageSize = 20

    /// 一覧に入れる ID の上限。PokeAPI の `/pokemon` は 1..1025 のあとに、
    /// フォーム違い（10001〜）が続く。フォーム違いは詳細で扱う。
    /// 世代で絞り込むときは、この「止める位置」を世代の終わりに差し替える。
    private static let lastListedID = 10000

    package static let liveValue = FetchPokemonPageUseCase(
        execute: { offset in
            @Dependency(\.pokemonRepository) var repository
            let page = try await repository.fetchList(pageSize, offset)
            let items = page.items.filter { $0.id <= lastListedID }
            let reachedEnd = items.count < page.items.count
            return PokemonPage(items: items, hasNext: reachedEnd ? false : page.hasNext)
        }
    )
}

extension DependencyValues {
    package var fetchPokemonPage: FetchPokemonPageUseCase {
        get { self[FetchPokemonPageUseCase.self] }
        set { self[FetchPokemonPageUseCase.self] = newValue }
    }
}
