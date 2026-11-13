# swift-pokedex

SwiftUI 製のポケモン図鑑アプリ（学習用）。進み具合は GitHub の [Milestones](https://github.com/chippy-ao/swift-pokedex/milestones) と Issues で管理している。

## ドキュメント

- [docs/README.md](docs/README.md): 目次とドキュメントの運用ルール（置き場所、ADR を残す基準）
- [docs/architecture.md](docs/architecture.md): 全体のアーキテクチャ
- [docs/package-dependencies.md](docs/package-dependencies.md): モジュール構成と依存ルール
- [docs/dependency-injection.md](docs/dependency-injection.md): DI の方針
- [docs/data-layer.md](docs/data-layer.md): データ層とキャッシュ方針
- [docs/development.md](docs/development.md): コミット規約、Lint、テスト、Issue、PR のチェック
- [docs/flutter-comparison/README.md](docs/flutter-comparison/README.md): Swift と Dart / Flutter の比較ノート（学習用、Issue ごと）
- [docs/adr/README.md](docs/adr/README.md): ADR の一覧と書式
- [feature/PokedexFeature/README.md](feature/PokedexFeature/README.md): Pokedex 機能の仕様
- [feature/SettingsFeature/README.md](feature/SettingsFeature/README.md): Settings 機能の仕様

## ルール

### ドキュメント

- 同じことは 2 か所に書かない。書きたくなったらリンクを貼る（片方だけ直されてずれるため）。
- 理由は、決めたもののすぐ近くに書く（値や実装の細部はコードのコメント、モジュールの仕様は README、全体ルールは docs、構造に関わる決定は ADR）。
- 何をどこに書くかは [docs/README.md](docs/README.md) の置き場所の表に従う。
- Issue で Swift の新しい言語機能、Apple 標準、Swift のツール、外部ライブラリを使ったら、同じ PR で docs/flutter-comparison/ のその Issue のノートに Dart / Flutter との比較を足す。言語に依らないツールは載せない。
- feature の挙動を変えたら、同じ PR でその feature の README を更新する。
- 実装中に仕様（feature の README）を変えたくなったら、先に理由を示してユーザーの合意を取る。
- 書いたコードに合わせて README を黙って書き換えない。
- ユーザーと合意していない ADR は追加しない。
- 承認済みの ADR は書き換えない（誤字の修正を除く）。覆すときは新しい ADR を追加し、古い ADR を Superseded にする。
- CLAUDE.md に docs の中身をコピーしない。要点とリンクだけを書く。

### 開発

- PR を出す前に `mise run lint` と `mise run test` を通す（[docs/development.md](docs/development.md#タスク) 参照）。
- モジュールの追加と依存の変更は `Package.swift` で行う。テスト target を足したら `app/AllTests.xctestplan` にも登録する（[docs/development.md](docs/development.md#xcode-プロジェクト) 参照）。
- `project.pbxproj` を変えた PR は、Xcode で開けるかをユーザーに確かめてもらう。

### テスト

- 仕様からテストを先に書き、失敗を確かめてコミットしてから実装する（[docs/development.md](docs/development.md#テスト) 参照）。
- 常に通るアサーションや、モックの戻り値をそのまま検証するだけのテストは書かない。
- 失敗したテストの期待値を実装に合わせて書き換えない。合意なしにテストを削除・無効化しない。

### Git / CI

- コミットは Conventional Commits で、説明文は日本語で書く（[docs/development.md](docs/development.md) 参照）。
- GitHub Actions の `uses:` はフルコミット SHA で固定する（タグは付け替えられるため）。
