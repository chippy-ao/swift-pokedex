import Foundation
import Model
import NetworkClient

/// 名前が検索語に当たるか（部分一致）。
package func matchesName(_ name: String, query: String) -> Bool {
    false
}

/// 表を `language` の名前で絞る。番号の小さい順。
func searchNames(
    in table: [Int: [LocalizedNameDTO]], query: String, language: LanguageCode
) -> [PokemonNameMatchDTO] {
    []
}
