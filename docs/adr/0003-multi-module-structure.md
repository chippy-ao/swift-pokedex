# ADR-0003: app / feature / core の 3 層マルチモジュール構成

- ステータス: 承認済み
- 日付: 2026-10-27

## コンテキスト

開発者は実務で Now in Android 風の Flutter マルチパッケージ構成(`app/mobile`、`app/shared`、`core/*`、`feature/*`)を使っています。Swift でも同様に、依存の向きをコンパイラで強制できる構成にしたいです。

## 決定

### 3 層構成

`app` / `feature` / `core` の 3 層に分けます。ディレクトリと依存ルールの詳細は [architecture.md](../architecture.md) と [package-dependencies.md](../package-dependencies.md) を参照してください。

### Package.swift はルートに 1 つ

リポジトリのルートに `Package.swift` を 1 つ置き、各 target の `path` でディレクトリを指定します。Xcode プロジェクトは `app/Pokedex` に置き、ルートのパッケージをローカルパッケージとして参照します(Point-Free の isowords が同様の構成です)。ワークスペースの要否など Xcode プロジェクトの細部は Phase 0 で決めます。

```swift
// 例(抜粋)
.target(
    name: "Model",
    dependencies: ["Common"],
    path: "core/Model/Sources"
),
.testTarget(
    name: "ModelTests",
    dependencies: ["Model"],
    path: "core/Model/Tests"
),
```

### feature はドメイン単位

feature は画面単位ではなくドメイン単位で分けます。`PokedexFeature`(List / Detail / Favorites をフォルダで分ける)と `SettingsFeature` の 2 つです。お気に入りは図鑑ドメインなので `PokedexFeature` に含めます。feature 同士は依存しません。

### Domain 層を置く

feature は Repository / NetworkClient / Database / Datastore を直接 import せず、必ず `Domain` の UseCase 経由にします。開発者の Flutter プロジェクトと同じで、単純な委譲でも UseCase を置きます。

## 理由

- 依存は target 単位で宣言できるので、モジュールごとに `Package.swift` を置かなくても境界を表現できます。ただし推移的な依存は import できてしまう場合があるため、明示的な依存チェックを Phase 0 で確認します。
- ルートに 1 つなら記述量が少なく、依存関係を 1 ファイルで見渡せます。
- 画面単位で分けると、一覧・詳細・お気に入りが同じ型(Pokemon)を共有するため、feature 間依存が発生しやすくなります。
- UseCase を挟むと、言語フォールバックなどのルール([ADR-0007](0007-localization.md))を 1 か所に置けます。

## 検討した代替案

| 案 | 不採用理由 |
| --- | --- |
| モジュールごとに `Package.swift` を置く | 記述量が多い。境界は target 単位の import 制限で守れる |
| feature を画面単位で分ける | feature 間依存が増える |
| Favorites を独立した feature にする | 図鑑ドメインの一部で、Detail とも密接。分けると feature 間依存が必要になる |
| Domain 層を置かず feature が Repository を直接使う | Flutter 側の構成と揃わず、ドメインルールの置き場所が曖昧になる |
| 単一ターゲット(モジュール化しない) | 依存の向きを強制できず、学習目的の構成演習にならない |

## 影響

### 良い点

- 依存違反がビルドエラーになる。
- Flutter / Now in Android の構成と対応づけやすい。

### 悪い点・注意点

- 単純な委譲の UseCase が増える。
- ルートの `Package.swift` が長くなる。
- Xcode プロジェクトとの連携(ワークスペース要否など)は Phase 0 で確認する。

## 参考リンク

- [Now in Android のモジュール化](https://github.com/android/nowinandroid/blob/main/docs/ModularizationLearningJourney.md)
- [isowords](https://github.com/pointfreeco/isowords)
