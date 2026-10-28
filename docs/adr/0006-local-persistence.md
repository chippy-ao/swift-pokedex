# ADR-0006: ローカル永続化

- ステータス: 承認済み
- 日付: 2026-10-27

## コンテキスト

お気に入りの追加・削除・一覧と、設定値(テーマ色)を端末に保存する必要があります。Swift 6 の strict concurrency に沿った形で、モダンな Apple 標準 API を学ぶことも目的です。

## 決定

- お気に入りは SwiftData に保存します。Database interface の裏に隠し、View で `@Query` は使いません。
- 設定値(テーマ色)は UserDefaults に保存します(Datastore interface + `DatastoreUserDefaults` 実装)。
- 実装の方針(`@ModelActor`、`@Model` 型を外に出さないこと、公開方法)は [data-layer.md](../data-layer.md#database-と-databaseswiftdata) を参照してください。

## 理由

- Apple 標準で学習目的に合い、追加の依存が不要です。
- interface の裏に隠すことで、View が永続化技術に依存せず、後から実装を差し替えられます([ADR-0004](0004-dependency-injection.md))。
- `@Model` 型が View や Store に漏れると、feature が実装モジュールに依存してモジュール境界が崩れます。interface 越しなら、Store のテストで Database を差し替えられ、SwiftData なしでテストできます。
- `ModelContext` は `Sendable` ではないため、`@ModelActor` の actor で包むと並行性の境界が明確になり、Swift 6 言語モードに適合します。
- テーマ色のような小さな設定値に SwiftData は過剰で、UserDefaults で十分です。

## 検討した代替案

| 案 | 不採用理由 |
| --- | --- |
| Core Data | SwiftData の前身。新規で学ぶならモダンな SwiftData を優先する |
| GRDB / SQLiteData | まず Apple 標準を学ぶ |
| Realm | MongoDB が 2024 年 9 月に Atlas Device SDK の廃止を発表し、2025 年 9 月 30 日に EOL。DB 本体はオープンソースとして残るが新規採用は避ける |
| View で `@Query` を使う | View が SwiftData の `@Model` と `ModelContext` に直接依存し、interface の裏に隠せない。`@Model` が漏れるとモジュール境界が崩れる |
| テーマ色も SwiftData に保存 | 単一の設定値には過剰 |

## 影響

### 良い点

- 永続化技術が `DatabaseSwiftData` に閉じる。
- テストでは Database interface の `testValue` で差し替えられる。

### 悪い点・注意点

- `@Model` 型と Entity の変換コードが必要。
- `@Query` の便利さは使えないため、変更監視は `AsyncStream` などで自前で公開する。
- オフラインキャッシュ([キャッシュ方針](../data-layer.md#キャッシュ方針)の段階2)で SwiftData を拡張する際は、Database interface の設計を見直す。

## 参考リンク

- [Apple SwiftData](https://developer.apple.com/documentation/swiftdata)
- [Realm の廃止(ドキュメント)](https://www.mongodb.com/docs/realm/)
- [Realm の廃止(フォーラム)](https://www.mongodb.com/community/forums/t/deprecation-of-realm-swift-sdk/300126)
