# ADR-0015: Xcode プロジェクトの構成と名前

- ステータス: 承認済み
- 日付: 2026-10-31

## コンテキスト

[ADR-0003](0003-multi-module-structure.md) で、ルートの `Package.swift` を Xcode プロジェクトからローカルパッケージとして参照すると決め、ワークスペースの要否など Xcode プロジェクトとの連携は導入時に確認することにしました。Issue #2 で骨組みを作るにあたり、これを決めます。今のエントリーポイントは Pokedex アプリだけですが、デザインシステムのカタログアプリやアプリ拡張(Widget など)が増える可能性があります。

## 決定

- ワークスペースは作りません。`app/` に Xcode プロジェクトを 1 つだけ置き、エントリーポイントはターゲット(`app/<ターゲット名>/`)として足します。
- Xcode プロジェクトの名前は `App.xcodeproj`、テストプランの名前は `AllTests.xctestplan` にします。
- テストプランには、リポジトリの全テスト target を登録します。

## 理由

- ターゲットごとにリンクする product を選べるので、1 つの Xcode プロジェクトでもエントリーポイントごとに依存を分けられます。
- エントリーポイントごとに Xcode プロジェクトを分けると、1 つのウィンドウで開くためにワークスペースが必要になり、管理するものが増えます。
- アプリ拡張も、同じ Xcode プロジェクトにターゲットを足すのが Xcode の標準的なやり方です。
- Xcode プロジェクトは複数のエントリーポイントを入れる入れ物です。アプリ名(Pokedex)にすると、カタログアプリなどを足したときに名前と中身が合わなくなります。Flutter がアプリ名に関係なく `ios/Runner.xcodeproj` にするのと同じく、汎用の名前にします。
- テストプランも特定のアプリ用ではなく全テスト target の一覧なので、中身に合わせた名前にします。
- App の scheme は、ルートのパッケージのテスト target を自動では実行しません。そのため、テストプランに登録して実行します。

## 検討した代替案

| 案 | 不採用理由 |
| --- | --- |
| エントリーポイントごとに Xcode プロジェクトを分け、ワークスペースで束ねる | ワークスペースの管理が増える。ターゲットで依存を分けられるので、分ける利点が少ない |
| `Pokedex.xcodeproj`(製品名。isowords は `isowords.xcodeproj` に本体とプレビュー用アプリを入れている) | エントリーポイントが増えると、名前と中身が合わない |
| `swift-pokedex.xcodeproj`(リポジトリ名) | Xcode のナビゲーターで、ルートのパッケージと同じ名前が 2 回並ぶ |
| テストプランを `Pokedex.xctestplan` にする | 中身は Pokedex アプリ専用ではない |

## 影響

### 良い点

- エントリーポイントを足しても、フォルダとターゲットを足すだけで済み、名前を変える必要がない。
- ワークスペースが要らず、`xcodebuild -project app/App.xcodeproj` で全テストを実行できる。

### 悪い点・注意点

- Xcode のウィンドウ名がアプリ名にならないので、アプリは scheme 名(Pokedex、Catalog など)で区別する。
- テスト target を足したら、テストプランへの登録が必要。登録漏れは依存チェックのスクリプトで検出する([package-dependencies.md](../package-dependencies.md#依存チェック))。

## 参考リンク

- [isowords](https://github.com/pointfreeco/isowords)
- [Improving code assessment by organizing tests into test plans](https://developer.apple.com/documentation/xcode/improving-code-assessment-by-organizing-tests-into-test-plans)
