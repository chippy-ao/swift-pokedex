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

- interface モジュールで `testValue` と `previewValue` を定義し、実装モジュールで `liveValue` を追加する。
- 実装モジュールをリンクするのは App ターゲットだけ。

具体的な書き方は [dependency-injection.md](../dependency-injection.md#interface-と実装を分ける) を参照してください。

### struct + クロージャで定義

依存は DependenciesMacros の `@DependencyClient` を使った「クロージャをプロパティに持つ struct」で定義します。protocol より mock が楽です。書き方は [dependency-injection.md](../dependency-injection.md) を参照してください。

### API レベルの interface

NetworkClient の interface は HTTP レベルではなく API レベル(`PokeAPIClient`: 一覧取得、詳細取得など)にします。

## 理由

- Repository のテストで、API レスポンスを直接差し替えられます。HTTP レベルだとリクエスト組み立てまでテストに現れます。
- 実装モジュールを App だけがリンクすれば、feature や Repository が実装に依存せず、テストやプレビューでネットワーク・DB に触れません。
- Riverpod の override に慣れた感覚で `withDependencies` を使えます。コード生成もグローバルな登録処理も不要で、Injectable / get_it より手数が少ないです。
- テスト用(`testValue`)・Preview 用(`previewValue`)・本番用(`liveValue`)を依存ごとに持てます。
- feature のビルドが軽くなります。URLSession、SwiftData、UserDefaults の実装ではなく interface だけをビルドすれば済みます。
- 依存ルールを target 単位で守れます。feature が実装モジュールを import しようとしてもビルドできません。
- Point-Free のライブラリなので、将来 TCA を試すときもそのまま使えます(TCA は不採用: [ADR-0002](0002-state-management-custom-mvi.md))。

## 検討した代替案

| 案 | 不採用理由 |
| --- | --- |
| Factory | swift-dependencies と同等の選択肢。Riverpod 経験から swift-dependencies を選ぶ(外部ライブラリの選定は [ADR-0005](0005-external-libraries.md)) |
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

## 参考リンク

- [swift-dependencies](https://github.com/pointfreeco/swift-dependencies)
- [Live, preview, and test dependencies](https://github.com/pointfreeco/swift-dependencies/blob/main/Sources/Dependencies/Documentation.docc/Articles/LivePreviewTest.md)
