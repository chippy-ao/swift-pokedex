# ADR-0012: 開発ツールのバージョン管理

- ステータス: 承認済み
- 日付: 2026-10-28

## コンテキスト

SwiftLint や Git フック用のツールは Xcode に含まれないため、別途インストールが必要です。ローカルと CI でバージョンがずれると、片方だけで検査が落ちます。開発者の Flutter プロジェクトでは mise でツールとタスクを管理しています。

## 決定

### ツールは mise で固定する

リポジトリのルートに `mise.toml` を置き、次のツールのバージョンを固定します。

| ツール | 用途 |
| --- | --- |
| SwiftLint | Lint([ADR-0011](0011-lint-and-format.md)) |
| prek | Git フックの管理 |
| committed | コミットメッセージの検査([ADR-0010](0010-commit-and-pr-convention.md)) |
| pinact | GitHub Actions を SHA で固定([ADR-0013](0013-ci-status-checks.md)) |
| actionlint | GitHub Actions のワークフローの検査 |
| xcbeautify | `xcodebuild` のログを読みやすくする |

Xcode 本体と、ツールチェーンに同梱されている swift-format は mise の管理外です。Xcode のバージョンは README の「動作環境」に書きます。

### 定型の操作は mise のタスクにする

| タスク | 内容 |
| --- | --- |
| `mise run bootstrap` | ツールのインストールと prek のフックのインストール |
| `mise run format` | swift-format による整形 |
| `mise run lint` | swift-format と SwiftLint による検査 |
| `mise run test` | `xcodebuild test` の実行 |

CI からも同じタスクを呼びます。

### Ruby は使わない

fastlane や CocoaPods を使わないので、Ruby と Bundler は入れません。

## 理由

- バージョンを `mise.toml` に書けば、ローカルと CI で同じツールが使えます。
- タスクにまとめると、人も AI も CI も同じコマンドで操作でき、手順書とスクリプトがずれません。
- 開発者の Flutter プロジェクトと同じ仕組みにすると、使い方を覚え直さなくて済みます。

## 検討した代替案

| 案 | 不採用理由 |
| --- | --- |
| Homebrew で入れる | バージョンを固定しにくく、CI と揃えにくい |
| SwiftLint を SwiftPM プラグインで入れる | [ADR-0011](0011-lint-and-format.md) を参照 |
| シェルスクリプト(`scripts/bootstrap.sh` など)だけで管理する | ツールのバージョン固定は別の仕組みが必要になる |
| mise で Ruby も入れる | Ruby を使うツールが無い |

## 影響

### 良い点

- `mise run bootstrap` だけで開発を始められる。
- ツールの更新が `mise.toml` の差分としてレビューできる。

### 悪い点・注意点

- Xcode のバージョンは mise で揃えられないので、README と CI の設定を手で揃える。
- fastlane など Ruby のツールが必要になったら、新しい ADR を追加する。

## 参考リンク

- [mise](https://mise.jdx.dev/)
- [mise Tasks](https://mise.jdx.dev/tasks/)
