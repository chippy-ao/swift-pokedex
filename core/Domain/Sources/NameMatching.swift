import Foundation

/// 名前が検索語に当たるか（部分一致）。
/// 端末内で絞るための関数。API で検索できるなら、判定はサーバー側になり、これは要らなくなる
/// （理由は docs/adr/0018-bundled-pokemon-names-table.md）。
/// 大文字小文字、半角全角、濁点などの記号、ひらがなカタカナを区別しない。空の検索語は全件に当たる。
/// ひらがなは先にカタカナへそろえる（`range(of:options:)` の標準のオプションにはかな同士の区別を消すものが無い）。
package func matchesName(_ name: String, query: String) -> Bool {
    guard !query.isEmpty else { return true }
    return katakana(name).range(
        of: katakana(query),
        options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive]) != nil
}

private func katakana(_ text: String) -> String {
    text.applyingTransform(.hiraganaToKatakana, reverse: false) ?? text
}
