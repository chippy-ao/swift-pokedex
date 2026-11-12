import Dependencies
import DependenciesMacros
import Foundation
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
            @Dependency(\.preferredLocalization) var preferredLocalization
            let page = try await repository.fetchList(pageSize, offset)
            let entries = page.items.filter { $0.id <= lastListedID }
            let reachedEnd = entries.count < page.items.count
            let items = entries.map {
                PokemonSummary(
                    id: $0.id, name: displayName(of: $0, localization: preferredLocalization),
                    spriteURL: $0.spriteURL)
            }
            return PokemonPage(items: items, hasNext: reachedEnd ? false : page.hasNext)
        }
    )
}

/// 画面に出す名前を 1 つ選ぶ。規則は docs/data-layer.md の「言語コードと変換ルール」。
/// アプリの言語が `ja` なら `ja-hrkt`、それ以外は `en`。その言語が無ければ `en`、
/// `en` も無ければ識別子の頭を大文字にしたもの。
private func displayName(of entry: PokemonListEntry, localization: String?) -> String {
    let preferred: LanguageCode = localization == "ja" ? .jaHrkt : .en
    func name(in code: LanguageCode) -> String? {
        entry.names.first { $0.languageCode == code }?.name
    }
    return name(in: preferred) ?? name(in: .en) ?? entry.identifier.capitalized
}

extension DependencyValues {
    package var fetchPokemonPage: FetchPokemonPageUseCase {
        get { self[FetchPokemonPageUseCase.self] }
        set { self[FetchPokemonPageUseCase.self] = newValue }
    }
}
