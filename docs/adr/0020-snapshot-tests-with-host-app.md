# ADR-0020: スナップショットテストはホストアプリ付きで撮る

- ステータス: 承認済み
- 日付: 2026-11-14
- 関連: [ADR-0005](0005-external-libraries.md)（外部ライブラリの選定方針）、[ADR-0014](0014-xcode-project-management.md)（Xcode プロジェクトの管理方法）

## コンテキスト

画面の見た目の回帰を、スナップショットテストで確かめたい（[Issue #9](https://github.com/chippy-ao/swift-pokedex/issues/9)）。ところが iOS 26 以降の Liquid Glass（`.glassProminent` のボタンなど）は、swift-snapshot-testing の標準の撮り方（`layer.render`）では白紙になる。ライブラリの作者は、ホストアプリ付きのテストと `drawHierarchyInKeyWindow: true` の組み合わせが要るとしている（[Issue #1029](https://github.com/pointfreeco/swift-snapshot-testing/issues/1029)）。SwiftUI の `ImageRenderer` も、画面に出ていない View を描くので同じ問題がある（[ImageRenderer](https://developer.apple.com/documentation/swiftui/imagerenderer)）。

## 決定

- ホストアプリ付きのテスト target（`app/PokedexSnapshotTests`）で、画面を実際に画面へ出し、`drawHierarchyInKeyWindow: true` で撮る。
- 撮る道具（環境の固定、ライトとダークで撮る関数）は `core/SnapshotTestSupport` に置く。swift-snapshot-testing に依存するのは、`Package.swift` 上でこの target だけにする。
- 撮る場面は PokedexFeature の `PokemonDetailScenario`（`#if DEBUG` の `public`）に置き、Preview と共有する。テストは App の `SnapshotScreens`（`@testable import Pokedex`）を通して使う。
- 環境は iPhone 17・iOS 27.2・英語に固定する。違う環境では撮らず、失敗にする。
- CI では参照画像を撮り直さない。撮り直しは `mise run snapshot-record` で、PR に理由を書く（[development.md](../development.md#スナップショットテスト)）。

## 理由

- Liquid Glass を撮るには、実際に画面へ出した階層を描く必要があり、それにはホストアプリが要る。
- テストが PokedexFeature を直接リンクすると、App と同じパッケージのモジュールを 2 つの target がリンクするため、動的ライブラリになって型が複製され、App の `liveValue` が見つからなくなる。そのため App に入口を 1 つ置く。
- ライブラリを `Package.swift` だけで持てば、Renovate と lint（`scripts/check-dependencies.swift`）の対象のままになる。

## 検討した代替案

| 案 | 不採用理由 |
| --- | --- |
| パッケージのテスト target だけで撮る | ホストアプリが無く、glass が白紙になる |
| テストのときだけ glass でないボタンにする | 本番と違う絵を撮ることになり、回帰を見る意味が薄れる |
| 妥協して、glass のボタンがあるエラー画面を撮らない | 撮れない画面を残して問題を避ける案。glass が増えるほど撮れない画面が増え、回帰を見たい画面ほど外れていく |
| `project.pbxproj` に直接ライブラリを足す | Renovate と lint の対象外になる |
| テスト専用の target を作り、`@testable import` で内部の宣言を使う | `@testable` はテスト可能性を有効にしたビルド（Debug）でしか使えない。Release をビルドするとその target が失敗し、Release のビルドが壊れる |

## 影響

### 良い点

- glass を含む画面の見た目の変化を、画像の差で検出できる。
- 場面は Preview と共有するので、定義が 1 か所で済む。

### 悪い点・注意点

- 端末と OS の描画の差で画像がずれるため、環境を固定する。環境を変えるときは、参照画像を全部撮り直す。
- 動き続ける View（ProgressView など）は、毎回違う画像になるので撮れない。
- ホストアプリ付きなので、テスト中にアプリが起動する。テスト中は画面を作らないようにしている（`PokedexApp`）。

## 参考リンク

- [swift-snapshot-testing Issue #1029](https://github.com/pointfreeco/swift-snapshot-testing/issues/1029)
- [ImageRenderer（Apple）](https://developer.apple.com/documentation/swiftui/imagerenderer)
