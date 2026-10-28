# 開発の進め方

セットアップ、コミット、Lint、PR のチェックのルールをまとめます。決定の経緯は各 ADR を参照してください。

> コードはまだ無いため、ここに書いたファイル（`mise.toml`、`committed.toml` など）とタスクは Phase 0 で作ります。

## セットアップ

1. README の「動作環境」に書いたバージョンの Xcode を入れる
2. [mise](https://mise.jdx.dev/) を入れる
3. `mise run bootstrap` を実行する（ツールと Git フックのインストール）

## ツール

ツールのバージョンはルートの `mise.toml` で固定します（[ADR-0012](adr/0012-tool-version-management.md)）。Xcode と、Xcode に同梱されている swift-format は mise の管理外です。

| ツール | 用途 |
| --- | --- |
| SwiftLint | Lint |
| prek | Git フックの管理 |
| committed | コミットメッセージの検査 |
| pinact | GitHub Actions を SHA で固定 |
| actionlint | GitHub Actions のワークフローの検査 |
| xcbeautify | `xcodebuild` のログの整形 |

## タスク

人も AI も CI も、同じ mise のタスクを使います。

| タスク | 内容 |
| --- | --- |
| `mise run bootstrap` | ツールと Git フックのインストール |
| `mise run format` | swift-format による整形 |
| `mise run lint` | swift-format と SwiftLint による検査 |
| `mise run test` | ビルドとテスト |

## コミット

[Conventional Commits](https://www.conventionalcommits.org/ja/v1.0.0/) に従います（[ADR-0010](adr/0010-commit-and-pr-convention.md)）。

```text
<type>(<scope>): <日本語の説明>
```

- type: `feat`、`fix`、`docs`、`style`、`refactor`、`perf`、`test`、`build`、`ci`、`chore`、`revert`
- scope: 任意。付けるときは target 名（`PokedexFeature`、`NetworkClient` など）
- 例: `feat(PokedexFeature): 一覧の無限スクロールを追加`

コミット時に prek の commit-msg フックが committed を実行し、形式が違えばコミットを止めます。ルールは `committed.toml` にあります。

## Lint と整形

2 つのツールで役割を分けます（[ADR-0011](adr/0011-lint-and-format.md)）。

| ツール | 役割 |
| --- | --- |
| swift-format | 見た目の整形。コミット時に変更ファイルへ自動で適用される |
| SwiftLint | 書き方の検査。見た目のルールは swift-format に任せて無効にする |

## PR

- `.github/PULL_REQUEST_TEMPLATE.md` に従って書きます。
- 機能の挙動を変えたら、該当 feature の `README.md` を同じ PR で更新します（[ADR-0001](adr/0001-documentation-policy.md)）。
- 設計を変えたら ADR を追加します。

### ステータスチェック

次のチェックがすべて通らないと main にマージできません（[ADR-0013](adr/0013-ci-status-checks.md)）。

| チェック | 内容 |
| --- | --- |
| PR タイトル | Conventional Commits 形式か |
| コミットメッセージ | PR 内の全コミットを committed で検査 |
| Lint | swift-format、SwiftLint、actionlint |
| Build / Test | `xcodebuild test` によるビルドとテスト |

### GitHub Actions を書くとき

- `uses:` はフルコミット SHA で固定し、末尾にバージョンをコメントで残します。pinact が prek のフックで自動で固定します。
- `permissions` は必要な最小限にします。
- `pull_request_target` では PR のコードを checkout しません。

## Xcode プロジェクト

`app/Pokedex` の Xcode プロジェクトは生成ツールを使わずに直接管理し、buildable folder を使います（[ADR-0014](adr/0014-xcode-project-management.md)）。モジュールの追加や依存の変更は `Package.swift` で行います。
