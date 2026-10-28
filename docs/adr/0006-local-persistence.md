# ADR-0006: ローカル永続化

- ステータス: 承認済み
- 日付: 2026-10-27

## コンテキスト

お気に入りの追加・削除・一覧と、設定値(テーマ色)を端末に保存する必要があります。Swift 6 の strict concurrency に沿った形で、モダンな Apple 標準 API を学ぶことも目的です。

## 決定

- お気に入りは SwiftData に保存します。
- Database interface の裏に隠すので、View で `@Query` は使いません。fetch 関数や `AsyncStream` で公開します。
- `ModelContext` は `Sendable` ではないので、実装は `@ModelActor` を付けた actor で包みます。
- SwiftData の `@Model` 型は `DatabaseSwiftData` の外に出しません。外へは `Model` モジュールの Entity を返します。
- 設定値(テーマ色)は UserDefaults に保存します(Datastore interface + `DatastoreUserDefaults` 実装)。

```swift
// 例(実装モジュール内の方針を示す抜粋)
@ModelActor
actor FavoriteStoreActor {
    // @Model 型はこの actor の内側に閉じ、外へは Sendable な Entity を返す
}
```

## 理由

- Apple 標準で学習目的に合い、追加の依存が不要です。
- interface の裏に隠すことで、View が永続化技術に依存せず、後から実装を差し替えられます([ADR-0004](0004-dependency-injection.md))。
- `@ModelActor` で並行性の境界が明確になり、Swift 6 言語モードに適合します。
- テーマ色のような小さな設定値に SwiftData は過剰で、UserDefaults で十分です。

## 検討した代替案

| 案 | 不採用理由 |
| --- | --- |
| Core Data | SwiftData の前身。新規で学ぶならモダンな SwiftData を優先する |
| GRDB / SQLiteData | まず Apple 標準を学ぶ |
| Realm | MongoDB が 2024 年 9 月に Atlas Device SDK の廃止を発表し、2025 年 9 月 30 日に EOL。DB 本体はオープンソースとして残るが新規採用は避ける |
| View で `@Query` を使う | View が SwiftData に直接依存し、interface の裏に隠せない |
| テーマ色も SwiftData に保存 | 単一の設定値には過剰 |

## 影響

### 良い点

- 永続化技術が `DatabaseSwiftData` に閉じる。
- テストでは Database interface の `testValue` で差し替えられる。

### 悪い点・注意点

- `@Model` 型と Entity の変換コードが必要。
- `@Query` の便利さは使えないため、変更監視は `AsyncStream` などで自前で公開する。
- 段階 2 のオフラインキャッシュで SwiftData を拡張する際は、Database interface の設計を見直す([data-layer.md](../data-layer.md) 参照)。

## 参考リンク

- [Apple SwiftData](https://developer.apple.com/documentation/swiftdata)
- [Realm の廃止(ドキュメント)](https://www.mongodb.com/docs/realm/)
- [Realm の廃止(フォーラム)](https://www.mongodb.com/community/forums/t/deprecation-of-realm-swift-sdk/300126)
