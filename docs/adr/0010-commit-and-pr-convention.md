# ADR-0010: コミット規約と PR の運用

- ステータス: 承認済み
- 日付: 2026-10-28

## コンテキスト

AI と一緒に開発を進めるため、コミットや PR の書き方を人の注意力に頼らず機械的に守らせたいです。開発者の Flutter プロジェクトでは、ローカルの commit-msg フックと CI の PR タイトル検査を組み合わせています。ただしそこでは、CI で PR 内の個々のコミットまでは検査していません。

## 決定

- コミットメッセージは [Conventional Commits](https://www.conventionalcommits.org/ja/v1.0.0/) に従い、type は英語、説明文は日本語で書きます。
- ローカルの commit-msg フック([prek](https://github.com/j178/prek) 経由の [committed](https://github.com/crate-ci/committed))と、CI での PR 内の全コミットと PR タイトルの検査を組み合わせます。ルールは `committed.toml` 1 か所に置き、ローカルと CI で共有します。
- PR は `.github/PULL_REQUEST_TEMPLATE.md` に従って書きます。

type や scope の一覧、検査の仕組み、PR テンプレートの項目は [development.md](../development.md#コミット) に書きます。

## 理由

- ローカルのフックは `--no-verify` で飛ばせるため、CI でもコミットを検査して抜け道を塞ぎます。
- PR タイトルも検査すると、マージ方式にかかわらず main の履歴とリリースノートの品質を保てます。
- 開発者の Flutter プロジェクトと同じツールにすると、設定を流用でき、運用で迷いません。
- PR テンプレートにチェックリストを置くと、ADR-0001 の「仕様はコードと同じ PR で更新する」を忘れにくくなります。

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
- scope は `committed.toml` で管理するため、target を追加したら更新が要る(手順は [development.md](../development.md#コミット))。

## 参考リンク

- [Conventional Commits 1.0.0](https://www.conventionalcommits.org/ja/v1.0.0/)
- [crate-ci/committed](https://github.com/crate-ci/committed)
- [j178/prek](https://github.com/j178/prek)
- [amannn/action-semantic-pull-request](https://github.com/amannn/action-semantic-pull-request)
