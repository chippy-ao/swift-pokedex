# ADR-0010: コミット規約と PR の運用

- ステータス: 承認済み
- 日付: 2026-10-28

## コンテキスト

AI と一緒に開発を進めるため、コミットや PR の書き方を人の注意力に頼らず機械的に守らせたいです。開発者の Flutter プロジェクトでは、ローカルの commit-msg フックと CI の PR タイトル検査を組み合わせています。ただしそこでは、CI で PR 内の個々のコミットまでは検査していません。

## 決定

### コミットメッセージ

- [Conventional Commits](https://www.conventionalcommits.org/ja/v1.0.0/) に従います。
- type は英語(`feat`、`fix`、`docs`、`style`、`refactor`、`perf`、`test`、`build`、`ci`、`chore`、`revert`)、説明文は日本語で書きます。例: `docs: ライセンスの ADR を追加`
- scope は任意です。付ける場合は target 名(`PokedexFeature`、`NetworkClient` など)を使います。許可する scope は `committed.toml` で管理します。

### 検査の仕組み

| どこで | 何を | ツール |
| --- | --- | --- |
| ローカル | コミットメッセージ | [prek](https://github.com/j178/prek) の commit-msg フックで [committed](https://github.com/crate-ci/committed) を実行 |
| CI | PR 内のすべてのコミットメッセージ | committed にベースから HEAD までの範囲を渡して実行 |
| CI | PR タイトル | [amannn/action-semantic-pull-request](https://github.com/amannn/action-semantic-pull-request) |

prek はフックの管理ツール、committed はメッセージの検査ツールです。ルールは `committed.toml` 1 か所に置き、ローカルと CI で共有します。

### PR テンプレート

`.github/PULL_REQUEST_TEMPLATE.md` を置き、次の項目を書きます。

- 概要と関連 Issue(`Closes #N`)
- 変更内容
- 確認方法(スクリーンショットを含む)
- チェックリスト: feature の `README.md` を同じ PR で更新したか、設計を変えた場合に ADR を追加したか([ADR-0001](0001-documentation-policy.md))

## 理由

- ローカルのフックは `--no-verify` で飛ばせるため、CI でもコミットを検査して抜け道を塞ぎます。
- PR タイトルも検査すると、マージ方式にかかわらず main の履歴とリリースノートの品質を保てます。
- 開発者の Flutter プロジェクトと同じツールにすると、設定を流用でき、運用で迷いません。
- PR テンプレートのチェックリストで、ADR-0001 の「仕様はコードと同じ PR で更新する」を忘れにくくします。

## 検討した代替案

| 案 | 不採用理由 |
| --- | --- |
| PR タイトルだけを検査する(squash マージ前提) | 開発者は個々のコミットも Conventional Commits にしたい |
| commitlint | Node.js が必要になる。committed は単体のバイナリで、mise で入れられる |
| ローカルのフックだけで検査する | `--no-verify` で回避できる |
| type も日本語にする | ツールの既定と合わず、設定が増える |

## 影響

### 良い点

- コミットと PR タイトルの両方が、ルールから外れたら CI で止まる。
- ルールが `committed.toml` に集約される。

### 悪い点・注意点

- マージ方式(squash / merge commit / rebase)は未決定。決めるときに、CI でコミットの範囲をどう渡すかも合わせて決める。
- 新しい target を追加したら、`committed.toml` の scope も更新する。

## 参考リンク

- [Conventional Commits 1.0.0](https://www.conventionalcommits.org/ja/v1.0.0/)
- [crate-ci/committed](https://github.com/crate-ci/committed)
- [j178/prek](https://github.com/j178/prek)
- [amannn/action-semantic-pull-request](https://github.com/amannn/action-semantic-pull-request)
