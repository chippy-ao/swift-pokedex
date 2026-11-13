import Foundation
import Model

/// 画面に出す名前を 1 つ選ぶ。規則は docs/data-layer.md の「言語コードと変換ルール」。
/// 一覧と詳細で同じ規則を使うため、UseCase から取り出して共通にしている。
package func displayName(
    from names: [LocalizedName], identifier: String, localization: String?
) -> String {
    localizedText(in: names, localization: localization) ?? identifier.capitalized
}

/// 言語の規則で 1 つ選ぶ。ja は ja-hrkt、無ければ en。どちらも無ければ nil。
/// 分類（genus）のように、無ければ出さないものに使う。
package func localizedText(in texts: [LocalizedName], localization: String?) -> String? {
    let preferred: LanguageCode = localization == "ja" ? .jaHrkt : .en
    func text(in code: LanguageCode) -> String? {
        texts.first { $0.languageCode == code }?.name
    }
    return text(in: preferred) ?? text(in: .en)
}
