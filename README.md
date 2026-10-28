# swift-pokedex

PokeAPI を使ったポケモン図鑑アプリです。久しぶりの Swift 学習として、モダン Swift の機能を総復習することを目的にしています。

## 学習ゴール

- Swift 6 言語モード（strict concurrency）での実装に慣れる
- Observation（`@Observable`）を使った状態管理を、自作の MVI で組み立てる
- SwiftData、Swift Testing、NavigationStack などの最新 API を一通り使う
- app / feature / core の3層によるモジュール分割を、SwiftPM で実践する

## 主な機能

| 領域 | 内容 |
| --- | --- |
| Pokedex | 一覧（無限スクロール）、名前検索、タイプフィルタ、詳細（画像、タイプ、ステータス、説明文、進化チェーン） |
| お気に入り | 追加・削除、お気に入り一覧 |
| Settings | メインカラー（テーマ色）の変更、ライセンス表示、言語変更（iOS のアプリ別言語設定へ誘導） |

## 技術スタックの要約

| 領域 | 採用 |
| --- | --- |
| UI | SwiftUI のみ（NavigationStack） |
| 状態管理 | 自作 MVI（`@Observable` な Store） |
| DI | swift-dependencies |
| 通信 | URLSession + swift-http-types |
| 画像 | Nuke（NukeUI） |
| 永続化 | SwiftData（お気に入り）、UserDefaults（設定値） |
| ライセンス表示 | LicenseList |
| Lint / 整形 | SwiftLint、swift-format |
| テスト | Swift Testing（swift-snapshot-testing は余裕が出たら） |

選定の理由や不採用にしたものは [docs/adr/README.md](docs/adr/README.md) の ADR にまとめています。

## 動作環境

- Xcode 27.0
- Swift 6.4（Swift 6 言語モード）
- iOS 26 以上（暫定。最新 API を学ぶため）

## ステータス

計画段階です。コードはまだありません。ドキュメントから先に整備しています。

## ドキュメント

- [docs/README.md](docs/README.md)（ドキュメントの目次と運用ルール）
- [docs/development.md](docs/development.md)（セットアップと開発の進め方）
- ロードマップとタスクは GitHub の [Milestones](https://github.com/chippy-ao/swift-pokedex/milestones) と Issues で管理しています。

## クレジット

ポケモンのデータは [PokeAPI](https://pokeapi.co/docs/v2) から取得します。

## ライセンス

このリポジトリのコードは [MIT License](LICENSE) で公開しています。

ポケモンの名前、画像などの権利は任天堂、クリーチャーズ、ゲームフリーク、株式会社ポケモンに帰属し、MIT License の対象外です。このプロジェクトは個人の学習用の非公式アプリで、これらの権利者とは関係ありません。
