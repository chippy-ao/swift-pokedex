# ADR-0007: 言語切り替えとデータの言語

- ステータス: 承認済み
- 日付: 2026-10-27

## コンテキスト

Settings に言語変更の機能を置きます。また、ポケモン名など PokeAPI のデータは多言語(`ja-hrkt`、`ja`、`en` など)で返るため、どの言語で表示するかも決める必要があります。対応言語は最初は ja と en(String Catalog)です。

## 決定

### UI の言語

UI の言語は iOS のアプリ別言語設定(iOS 13〜)に従います。Settings 画面からは設定アプリのこのアプリのページを開きます(`UIApplication.openSettingsURLString`)。アプリ内の言語切り替えは実装しません。

### データの言語

ポケモン名など PokeAPI のデータの言語もアプリの言語に追従させ、別設定にはしません。

- `Bundle.main.preferredLocalizations.first` を PokeAPI の言語コードに変換します(`ja` → `ja-hrkt`、`en` → `en`)。
- 該当言語の名前が無ければ `en` にフォールバックします。
- この変換とフォールバックは Domain の UseCase で行います。

```swift
// 例(変換の考え方を示す。実際の実装は Phase 5 で決める)
func pokeAPILanguageCode(preferred: String?) -> String {
    switch preferred {
    case "ja": "ja-hrkt"
    default: "en"
    }
}
```

## 理由

- OS 標準の仕組みに任せるのが最も安全で、実装が少なくて済みます。
- アプリ内切り替え(`.environment(\.locale, ...)`)は SwiftUI の `Text("key")` には効きますが `String(localized:)` には効きません。全体に効かせるには Bundle を差し替える裏技が必要になります。
- UI とデータの言語が別だと、設定が二重になり混乱します。

## 検討した代替案

| 案 | 内容 | 不採用理由 |
| --- | --- | --- |
| 方式 A(採用) | iOS のアプリ別言語設定に従う | - |
| 方式 B | アプリ内で切り替える(`.environment(\.locale, ...)`) | `String(localized:)` に効かず、全体に効かせるには Bundle 差し替えが必要 |
| ポケモン名だけ別設定にする | UI は OS 設定、データ言語はアプリ内設定 | 設定が二重になり、UI とデータの言語がずれる |

## 影響

### 良い点

- 実装が小さく、OS の挙動と一致する。
- 言語コードの変換が UseCase に集約され、テストしやすい。

### 悪い点・注意点

- アプリ別言語設定で選べるのは、アプリ自体がローカライズしている言語だけ。
- アプリ内で即座に切り替えることはできず、設定アプリへの遷移が必要。
- 日本語名での検索は全 species の名前が必要になるため、拡張フェーズで方式を検討する(要調査)。

## 参考リンク

- [WWDC19 Creating Apps for a Global Audience](https://developer.apple.com/videos/play/wwdc2019/403/)
- [Bundle.preferredLocalizations](https://developer.apple.com/documentation/foundation/bundle/preferredlocalizations)
- [String Catalog](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)
- [PokeAPI docs](https://pokeapi.co/docs/v2)
