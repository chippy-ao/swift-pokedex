# ADR-0004: DI に swift-dependencies を採用する

- ステータス: 承認済み
- 日付: 2026-10-27

## コンテキスト

NetworkClient・Database・Datastore は、本番実装、プレビュー、テストで差し替えたい依存です。開発者は Flutter で Riverpod、Injectable / get_it を使っています。

## 決定

### DI ライブラリ

swift-dependencies(Point-Free)を採用します。Riverpod の `ProviderScope` の `overrides` は `withDependencies` に近い存在です。

### interface と実装の分離

NetworkClient・Database・Datastore は interface モジュールと実装モジュールに分けます。swift-dependencies 公式ドキュメントの「interface と live 実装を別モジュールにする」パターンに従います。

- interface モジュール: 依存を `TestDependencyKey` に準拠させ、`testValue`(と `previewValue`)を定義する。公式ドキュメントによると `previewValue` は interface モジュール側で定義する必要がある。
- 実装モジュール: `DependencyKey` に準拠させ、`liveValue` を追加する。
- 実装モジュールをリンクするのは App ターゲットだけ。

### struct + クロージャで定義

依存は DependenciesMacros の `@DependencyClient` を使った「クロージャをプロパティに持つ struct」で定義します。protocol より mock が楽です。

```swift
// 例(interface 側。API 名は例示)
@DependencyClient
struct PokeAPIClient: Sendable {
    var fetchList: @Sendable (_ limit: Int, _ offset: Int) async throws -> PokemonListDTO
}

extension PokeAPIClient: TestDependencyKey {
    static let testValue = PokeAPIClient()
}
```

### API レベルの interface

NetworkClient の interface は HTTP レベルではなく API レベル(`PokeAPIClient`: 一覧取得、詳細取得など)にします。

## 理由

- Repository のテストで、API レスポンスを直接差し替えられます。HTTP レベルだとリクエスト組み立てまでテストに現れます。
- 実装モジュールを App だけがリンクすれば、feature や Repository が実装に依存せず、テストやプレビューでネットワーク・DB に触れません。
- Riverpod の override に慣れた感覚で `withDependencies` を使えます。

## 検討した代替案

| 案 | 不採用理由 |
| --- | --- |
| Factory | swift-dependencies と同等の選択肢。Riverpod 経験から swift-dependencies を選ぶ |
| イニシャライザ注入 + Environment | 階層が深くなると引き回しが増える。Environment は View 向けで Store や UseCase への注入には不便 |
| protocol ベースの依存 | mock の定義量が多い |
| HTTP レベルの interface | Repository のテストでレスポンスを差し替えにくい |

## 影響

### 良い点

- テスト・プレビューで依存を簡単に差し替えられる。
- 本番実装への依存を App に閉じ込められる。

### 悪い点・注意点

- マクロ(`@DependencyClient`)を使うため、ビルド時間とエラーメッセージの読みやすさに注意が必要。
- Point-Free のライブラリに依存する。
- 詳細な書き方は [dependency-injection.md](../dependency-injection.md) を参照。

## 参考リンク

- [swift-dependencies](https://github.com/pointfreeco/swift-dependencies)
- [Live, preview, and test dependencies](https://github.com/pointfreeco/swift-dependencies/blob/main/Sources/Dependencies/Documentation.docc/Articles/LivePreviewTest.md)
