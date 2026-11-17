import Foundation
import Model
import NetworkClient

/// 名前が検索語に当たるか（部分一致）。
/// 大文字小文字、半角全角、濁点などの記号、ひらがなカタカナを区別しない。空の検索語は全件に当たる。
/// ひらがなは先にカタカナへそろえる（`range(of:options:)` の標準のオプションにはかな同士の区別を消すものが無い）。
func matchesName(_ name: String, query: String) -> Bool {
    guard !query.isEmpty else { return true }
    return katakana(name).range(
        of: katakana(query),
        options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive]) != nil
}

private func katakana(_ text: String) -> String {
    text.applyingTransform(.hiraganaToKatakana, reverse: false) ?? text
}

/// 表を `language` の名前で絞る。番号の小さい順。
///
/// PokeAPI に名前検索の API が無く、`GET /pokemon` が日本語名を返さないので、同梱の表を端末内で
/// 絞っている（docs/adr/0018-bundled-pokemon-names-table.md）。API で検索できるようになったら、
/// この絞り込みごと、`PokeAPIClient.searchPokemonNames` の実装を API 呼び出しに差し替える。
///
/// 探す名前は `language` のものだけ。表示名の選び方（フォールバック）は UseCase が持つ規則で、ここには
/// 持たない（規則を 1 か所にするため）。表に抜けが出たら、ここと UseCase の規則を見直す。
/// その言語の名前が無い番号は、空の行になるので結果に入れない（UseCase も同じ扱い）。
func searchNames(
    in table: [Int: [LocalizedNameDTO]], query: String, language: LanguageCode
) -> [PokemonNameMatchDTO] {
    return table.keys.sorted().compactMap { id in
        let names = table[id] ?? []
        guard let name = names.first(where: { $0.languageCode == language.rawValue })?.name,
            matchesName(name, query: query)
        else { return nil }
        return PokemonNameMatchDTO(id: id, names: names)
    }
}
