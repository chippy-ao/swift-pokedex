# ADR-0012: 開発ツールのバージョン管理

- ステータス: 承認済み
- 日付: 2026-10-28

## コンテキスト

SwiftLint や Git フック用のツールは Xcode に含まれないため、別途インストールが必要です。ローカルと CI でバージョンがずれると、片方だけで検査が落ちます。開発者の Flutter プロジェクトでは mise でツールとタスクを管理しています。

## 決定

- 開発ツール(SwiftLint、prek、committed、pinact、actionlint、xcbeautify)は、ルートの `mise.toml` でバージョンを固定します。
- Xcode 本体と、ツールチェーンに同梱されている swift-format は mise の管理外とし、Xcode のバージョンは README の「動作環境」に書きます。
- 定型の操作(セットアップ、整形、Lint、テスト)は mise のタスクにし、人も AI も CI も同じタスクを使います。
- fastlane や CocoaPods を使わないので、Ruby と Bundler は入れません。

ツールとタスクの一覧は [development.md](../development.md#ツール) に書きます。

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
