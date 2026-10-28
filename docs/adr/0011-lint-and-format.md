# ADR-0011: Lint と整形の運用

- ステータス: 承認済み
- 日付: 2026-10-28

## コンテキスト

[ADR-0005](0005-external-libraries.md) で SwiftLint と swift-format の採用を決めました。2 つのツールは一部のルールが重なるため、役割の分け方と実行方法を決める必要があります。

## 決定

- 見た目の整形は [swift-format](https://github.com/swiftlang/swift-format)、書き方の検査は [SwiftLint](https://github.com/realm/SwiftLint) と役割を分けます。見た目に関するルールは swift-format に任せ、SwiftLint で整形結果とぶつかるルールは無効にします。
- swift-format は Swift ツールチェーンに同梱されている `swift format` を使います。SwiftLint は mise でバージョンを固定して入れます([ADR-0012](0012-tool-version-management.md))。
- コミット時に整形と検査を行い、CI でリポジトリ全体を検査します。

設定ファイルと実行するタイミングは [development.md](../development.md#lint-と整形) に書きます。

## 理由

- 整形は自動で直せるので、formatter に任せて人や AI が気にしなくて済むようにします。
- 整形結果に linter が警告を出すと、直しても消えない警告になります。担当を分けて衝突を防ぎます。
- swift-format はツールチェーンに同梱されているため、Xcode のバージョンに合わせて自動で更新されます。
- SwiftLint を SwiftPM のビルドツールプラグインにすると、パッケージの依存に開発ツールが混ざり、Xcode でプラグインの信頼確認も必要になります。mise で入れればローカルと CI で同じバージョンを使えます。

## 検討した代替案

| 案 | 不採用理由 |
| --- | --- |
| SwiftLint だけを使う | 整形の機能は限定的で、formatter の代わりにならない |
| swift-format だけを使う | lint のルールが SwiftLint より少ない |
| SwiftFormat(nicklockwood) | swift-format と同等の選択肢。ツールチェーンに同梱されている swift-format を優先する |
| SwiftLint を SwiftPM プラグインで入れる | 上記「理由」を参照 |

## 影響

### 良い点

- 整形の差分がレビューに混ざらない。
- ローカルと CI で同じ検査が走る。

### 悪い点・注意点

- SwiftLint で無効にするルールは、導入時に swift-format と実際に突き合わせて決める。
- swift-format のバージョンは Xcode に依存するため、ローカルと CI の Xcode のバージョンを揃える。

## 参考リンク

- [realm/SwiftLint](https://github.com/realm/SwiftLint)
- [swiftlang/swift-format](https://github.com/swiftlang/swift-format)
