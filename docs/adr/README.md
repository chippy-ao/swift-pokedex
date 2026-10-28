# ADR (Architecture Decision Record)

ADR は「なぜその設計にしたか」を 1 決定 1 ファイルで残す記録です。設計ルールそのもの(変わりにくい前提)は [docs/](../README.md) に書き、ADR には決定の経緯と、検討して捨てた案を残します。

## 運用ルール

- ADR は書き換えません。誤字の修正などを除き、承認済みの内容は変更しません。
- 方針を覆すときは新しい ADR を追加し、古い ADR のステータスを `Superseded` にします。新旧の ADR は相互にリンクします。
  - 古い側: `ステータス: Superseded (ADR-00XX により置き換え)`
  - 新しい側: `ステータス: 承認済み (ADR-00YY を置き換える)`
- 番号は連番(4 桁ゼロ埋め)で、欠番を作りません。ファイル名は `NNNN-kebab-case-title.md` です。
- ステータスは `提案中` / `承認済み` / `Superseded` / `却下` のいずれかです。
- ロードマップやタスクは ADR にも docs にも書かず、GitHub Issues と Milestones で管理します([ADR-0001](0001-documentation-policy.md) 参照)。

## 一覧

| 番号 | タイトル | ステータス | 日付 |
| --- | --- | --- | --- |
| [0001](0001-documentation-policy.md) | ドキュメント運用方針 | 承認済み | 2026-10-27 |
| [0002](0002-state-management-custom-mvi.md) | 状態管理に自作 MVI を採用する | 承認済み | 2026-10-27 |
| [0003](0003-multi-module-structure.md) | app / feature / core の 3 層マルチモジュール構成 | 承認済み | 2026-10-27 |
| [0004](0004-dependency-injection.md) | DI に swift-dependencies を採用する | 承認済み | 2026-10-27 |
| [0005](0005-external-libraries.md) | 外部ライブラリの選定方針 | 承認済み | 2026-10-27 |
| [0006](0006-local-persistence.md) | ローカル永続化 | 承認済み | 2026-10-27 |
| [0007](0007-localization.md) | 言語切り替えとデータの言語 | 承認済み | 2026-10-27 |
| [0008](0008-module-naming.md) | モジュール命名規約 | 承認済み | 2026-10-27 |
| [0009](0009-license.md) | ライセンス | 承認済み | 2026-10-28 |
| [0010](0010-commit-and-pr-convention.md) | コミット規約と PR の運用 | 承認済み | 2026-10-28 |
| [0011](0011-lint-and-format.md) | Lint と整形の運用 | 承認済み | 2026-10-28 |
| [0012](0012-tool-version-management.md) | 開発ツールのバージョン管理 | 承認済み | 2026-10-28 |
| [0013](0013-ci-status-checks.md) | CI と PR のステータスチェック | 承認済み | 2026-10-28 |
| [0014](0014-xcode-project-management.md) | Xcode プロジェクトの管理方法 | 承認済み | 2026-10-28 |

## テンプレート

````markdown
# ADR-000N: タイトル

- ステータス: 提案中 | 承認済み | Superseded (ADR-00XX により置き換え)
- 日付: YYYY-MM-DD

## コンテキスト

決定が必要になった背景と制約。

## 決定

何をするか。

## 理由

なぜそうするか。

## 検討した代替案

| 案 | 不採用理由 |
| --- | --- |
| 案 A | ... |

## 影響

### 良い点

- ...

### 悪い点・注意点

- ...

## 参考リンク

- [名前](URL)
````
