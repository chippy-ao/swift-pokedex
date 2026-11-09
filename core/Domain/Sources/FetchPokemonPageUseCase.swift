import Dependencies
import DependenciesMacros
import Model
import Repository

/// 図鑑の一覧を 1 ページぶん取得する。
/// 1 ページの件数と、一覧に入れる ID の範囲（図鑑のきまり）はここで決める。
@DependencyClient
public struct FetchPokemonPageUseCase: Sendable {
    public var execute: @Sendable (_ offset: Int) async throws -> PokemonPage
}

extension FetchPokemonPageUseCase: TestDependencyKey {
    public static let testValue = FetchPokemonPageUseCase()
}

extension FetchPokemonPageUseCase: DependencyKey {
    // 実装前のスタブ。誤った値を返す。
    public static let liveValue = FetchPokemonPageUseCase(
        execute: { _ in PokemonPage(items: [], hasNext: true) }
    )
}

extension DependencyValues {
    public var fetchPokemonPage: FetchPokemonPageUseCase {
        get { self[FetchPokemonPageUseCase.self] }
        set { self[FetchPokemonPageUseCase.self] = newValue }
    }
}
