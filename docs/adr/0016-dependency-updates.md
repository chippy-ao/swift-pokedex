# ADR-0016: 依存の更新に Renovate を使う

- ステータス: 承認済み
- 日付: 2026-11-04

## コンテキスト

[ADR-0013](0013-ci-status-checks.md) で、GitHub Actions の `uses:` をフルコミット SHA で固定すると決めました。一方、固定した SHA を更新する仕組みは決めていませんでした。

GitHub の Dependabot alerts は、GitHub Actions では SemVer のタグを使う action にしか出ません。SHA で固定した action には出ないので、更新の仕組みが無いと、使っている action の脆弱性に気づけません。mise のツールと Swift のパッケージも同じく、更新を見張る仕組みが要ります。

## 決定

- 依存の更新は [Mend Renovate App](https://github.com/apps/renovate) で行います。このリポジトリだけに入れます。
- GitHub Actions、mise のツール、Swift のパッケージを対象にします。
- 月 1 回（日本時間）に、minor / patch / digest を 3 つ（GitHub Actions、mise のツール、Swift のパッケージ）の PR にまとめます。major はまとめず、1 つずつ別の PR にします。
- 自動マージはしません。全 PR に `dependencies` ラベルを付けます。
- 脆弱性の修正は、月 1 回の予定を待たずに PR を出します。入力は Dependabot alerts で、alerts はオン、Dependabot security updates はオフにします。`dependabot.yml` は作りません。
- Renovate の PR のタイトルとコミットは、コミット規約（[ADR-0010](0010-commit-and-pr-convention.md)）の形にします。
- 設定の値と理由は [`.github/renovate.json5`](../../.github/renovate.json5) のコメントに書き、運用は [development.md](../development.md#依存の更新) に書きます。

## 理由

- Dependabot は `mise.toml` に対応していません（[対応するエコシステムの一覧](https://docs.github.com/en/code-security/dependabot/ecosystems-supported-by-dependabot/supported-ecosystems-and-repositories)に mise が無い）。Renovate は [mise](https://docs.renovatebot.com/modules/manager/mise/)、[swift](https://docs.renovatebot.com/modules/manager/swift/)、[github-actions](https://docs.renovatebot.com/modules/manager/github-actions/) のマネージャーを持ちます。
- Renovate は `vulnerabilityAlerts` で Dependabot alerts を読み、脆弱性の修正をスケジュールの外で出せます（[Renovate Docs](https://docs.renovatebot.com/configuration-options/#vulnerabilityalerts)）。そのため alerts はオンにします。PR は Renovate が出すので、Dependabot security updates は重複を避けるためにオフにします。
- 自動マージしないので、Renovate App が乗っ取られても、main に届く前にルールセット（PR 必須、レビュー、署名、必須チェック）で止まります。Mend には書き込み権限を渡すことになるため、この前提を崩さないことを優先します。
- 自前ホストの Renovate は、GitHub App の秘密鍵を Secrets に置くことになり、その管理が新しい危険になります。`GITHUB_TOKEN` で動かすと、そのトークンが作った PR の CI は承認待ちになり、自動では動きません（[GitHub Docs](https://docs.github.com/en/actions/concepts/security/github_token)）。
- 月 1 回のグループ化は、学習用のリポジトリで PR の数と確認の手間を抑えるためです。major は破壊的変更を含むので、1 つずつ読めるように分けます。

## 検討した代替案

| 案 | 不採用理由 |
| --- | --- |
| Dependabot だけ | mise のツールを更新できない。SHA 固定の action には alerts も出ない |
| Renovate を GitHub Actions で自前ホスト | GitHub App の秘密鍵の管理が増える。`GITHUB_TOKEN` では PR の CI が自動で動かない |
| ボットなしで `pinact run -u` と `mise outdated` を手で回す | 回すのを忘れると更新も脆弱性も気づけない |
| minor / patch の自動マージ（レビュー必須のルールセットを分けて Renovate を bypass） | ルールセットが 2 系統になる。App が乗っ取られると、レビューなしで main に届く |

## 影響

### 良い点

- SHA 固定の action、mise のツール、Swift のパッケージの更新と脆弱性に、同じ仕組みで気づける。
- PR は月 1 回の 3 つと major に絞られ、確認の手間が小さい。

### 悪い点・注意点

- Mend の App に書き込み権限を渡す。Secrets は最小にし、`pull_request_target` は使わない（[ADR-0013](0013-ci-status-checks.md)）。
- Renovate は外部のサービスで、App のインストールは手作業になる。
- CI は GitHub のプレビューのランナーイメージ `xcode-27` に依存する。正式なラベルになったら、`.github/actionlint.yaml` の登録を外す。
- グループの PR のタイトルは、最初の月次の PR が出たときに、コミット規約を通るか確かめる。

## 参考リンク

- [Renovate Docs – Configuration Options](https://docs.renovatebot.com/configuration-options/)
- [Renovate Docs – mise manager](https://docs.renovatebot.com/modules/manager/mise/)
- [GitHub Docs – About Dependabot alerts](https://docs.github.com/en/code-security/dependabot/dependabot-alerts/about-dependabot-alerts)
- [GitHub Docs – Dependabot の対応するエコシステム](https://docs.github.com/en/code-security/dependabot/ecosystems-supported-by-dependabot/supported-ecosystems-and-repositories)
- [GitHub Docs – GITHUB_TOKEN](https://docs.github.com/en/actions/concepts/security/github_token)
