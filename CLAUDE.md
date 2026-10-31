# swift-pokedex

SwiftUI 製のポケモン図鑑アプリ（学習用）。進み具合は GitHub の [Milestones](https://github.com/chippy-ao/swift-pokedex/milestones) と Issues で管理している。

## ドキュメント

- [docs/README.md](docs/README.md): 目次とドキュメントの運用ルール（置き場所、ADR を残す基準）
- [docs/architecture.md](docs/architecture.md): 全体のアーキテクチャ
- [docs/package-dependencies.md](docs/package-dependencies.md): モジュール構成と依存ルール
- [docs/dependency-injection.md](docs/dependency-injection.md): DI の方針
- [docs/data-layer.md](docs/data-layer.md): データ層とキャッシュ方針
- [docs/development.md](docs/development.md): コミット規約、Lint、テスト、Issue、PR のチェック
- [docs/flutter-comparison/README.md](docs/flutter-comparison/README.md): Swift / iOS と Flutter の対応表（学習用）
- [docs/adr/README.md](docs/adr/README.md): ADR の一覧と書式
- [feature/PokedexFeature/README.md](feature/PokedexFeature/README.md): Pokedex 機能の仕様
- [feature/SettingsFeature/README.md](feature/SettingsFeature/README.md): Settings 機能の仕様

## ルール

### ドキュメント

- [MUST] 同じことは 2 か所に書かない。書きたくなったらリンクを貼る。
- [MUST] 理由は、決めたもののすぐ近くに書く（値や実装の細部はコードのコメント、モジュールの仕様は README、全体ルールは docs、構造に関わる決定は ADR）。
- [MUST] 何をどこに書くかは [docs/README.md](docs/README.md) の置き場所の表に従う。
- [MUST] 新しいツールや概念を入れたら、同じ PR で docs/flutter-comparison/ の該当ファイルに Flutter での相当を足す。
- [MUST] feature の挙動を変えたら、同じ PR でその feature の README を更新する。
- [MUST] 実装中に仕様（feature の README）を変えたくなったら、先に理由を示してユーザーの合意を取る。
- [Forbidden] 書いたコードに合わせて README を黙って書き換えること。
- [Forbidden] ユーザーと合意していない ADR の追加。
- [Forbidden] 承認済み ADR の書き換え（誤字修正を除く）。覆すときは新しい ADR を追加し、古い ADR を Superseded にする。
- [Forbidden] CLAUDE.md への docs の中身のコピー。要点とリンクだけを書く。

### 開発

- [MUST] PR を出す前に `mise run lint` と `mise run test` を通す（[docs/development.md](docs/development.md#タスク) 参照）。
- [MUST] モジュールの追加と依存の変更は `Package.swift` で行う。テスト target を足したら `app/AllTests.xctestplan` にも登録する（[docs/development.md](docs/development.md#xcode-プロジェクト) 参照）。
- [MUST] `project.pbxproj` を変えた PR は、Xcode で開けるかをユーザーに確かめてもらう。

### テスト

- [MUST] 仕様からテストを先に書き、失敗を確かめてコミットしてから実装する（[docs/development.md](docs/development.md#テスト) 参照）。
- [Forbidden] 常に通るアサーション、モックの戻り値をそのまま検証するだけのテスト。
- [Forbidden] 失敗したテストの期待値を実装に合わせて書き換えること、合意なしにテストを削除・無効化すること。

### Git / CI

- [MUST] コミットは Conventional Commits で、説明文は日本語で書く（[docs/development.md](docs/development.md) 参照）。
- [MUST] GitHub Actions の `uses:` はフルコミット SHA で固定する。
