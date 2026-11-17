import Dependencies
import DependenciesMacros
import Foundation
import Model
import Repository

/// 名前で検索する。空の `query` は全件を返す。
///
/// 画面は「query を渡して結果を受け取る」ことだけを知る。全件の保持や絞り込みは画面に持たせない。
/// 絞り込みは NetworkClient の実装が行い、ここは一覧と同じ表示の規則（ID の範囲、名前の選び方）だけを担う。
///
/// 今は同梱の名前の表を端末内で絞っている。PokeAPI に名前検索の API が無く、一覧の `GET /pokemon` が
/// 日本語名を返さないための回避策である（理由は docs/adr/0018-bundled-pokemon-names-table.md）。
/// API で検索できるようになったら、`PokeAPIClient.searchPokemonNames` の実装だけを差し替える。
/// 通信するようになったら、画面側で debounce と、前の検索のキャンセルが要る
/// （今は端末内で一瞬で終わるので入れていない）。
@DependencyClient
package struct SearchPokemonByNameUseCase: Sendable {
    package var execute: @Sendable (_ query: String) async throws -> [PokemonSummary]
}

extension SearchPokemonByNameUseCase: TestDependencyKey {
    package static let testValue = SearchPokemonByNameUseCase()
}

extension SearchPokemonByNameUseCase: DependencyKey {
    package static let liveValue = SearchPokemonByNameUseCase(
        execute: { query in
            @Dependency(\.pokemonRepository) var repository
            @Dependency(\.preferredLocalization) var preferredLocalization
            let language = preferredLanguageCode(localization: preferredLocalization)
            let entries = try await repository.searchNames(query, language)
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
    package var searchPokemonByName: SearchPokemonByNameUseCase {
        get { self[SearchPokemonByNameUseCase.self] }
        set { self[SearchPokemonByNameUseCase.self] = newValue }
    }
}
