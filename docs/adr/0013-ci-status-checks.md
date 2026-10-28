# ADR-0013: CI と PR のステータスチェック

- ステータス: 承認済み
- 日付: 2026-10-28

## コンテキスト

AI が書いたコードも人が書いたコードも、同じ基準でマージ前に検査したいです。また、GitHub Actions はサードパーティのコードを CI 上で実行するため、サプライチェーン攻撃への対策が必要です。

## 決定

- GitHub Actions で PR のチェック(PR タイトル、コミットメッセージ、Lint、Build / Test)を実行し、main のルールセットで「Require status checks to pass」を有効にします。どれかが失敗した PR はマージできません。
- ルールセットで必須にするのは、個々のジョブではなく、ワークフローごとの集約ジョブ(結果をまとめるだけのジョブ)にします。
- Actions の `uses:` はタグではなくフルコミット SHA で固定し、SHA の固定は pinact で自動化します。`permissions` は最小限にします。
- CI から呼ぶコマンドは mise のタスクに揃えます([ADR-0012](0012-tool-version-management.md))。

チェックの一覧と Actions を書くときの手順は [development.md](../development.md#ステータスチェック) に書きます。

## 理由

- 必須チェックにすると、ローカルの検査を飛ばしても main に入る前に止まります。
- タグは後から別のコミットに付け替えられます。GitHub の公式ドキュメントでも、action を変更不可能な形で使う方法はフルコミット SHA での固定だけとされています。
- 集約ジョブを必須にすると、ジョブを追加・削除してもルールセットを触らずに済みます。
- 署名が要らない検査は Linux ランナーで実行し、macOS ランナーはビルドとテストなど必要なものに絞ります。

## 検討した代替案

| 案 | 不採用理由 |
| --- | --- |
| `uses:` をタグ(`@v6`)で書く | タグの付け替えで悪意あるコードが実行されうる |
| Lint だけを必須にする | コンパイルエラーやテストの失敗を見逃す |
| 個々のジョブを直接必須にする | パスでジョブをスキップすると必須チェックが待ち状態のまま残る |
| Xcode Cloud | 設定が Xcode と App Store Connect に寄り、開発者の Flutter プロジェクトの GitHub Actions の知見を流用しにくい |

## 影響

### 良い点

- main は常にビルドが通り、テストと検査を通過した状態に保たれる。
- Actions のバージョンが固定され、意図しない更新が入らない。

### 悪い点・注意点

- ランナーイメージに必要な Xcode のバージョンが入っているかは、導入時に確認する。
- 固定した SHA を更新する仕組み(Renovate または Dependabot)は未決定。
- 公開リポジトリでない場合、macOS ランナーは利用枠の消費が大きい。

## 参考リンク

- [GitHub Docs – Security hardening for GitHub Actions](https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions#using-third-party-actions)
- [GitHub Docs – Available rules for rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets)
- [suzuki-shunsuke/pinact](https://github.com/suzuki-shunsuke/pinact)
- [rhysd/actionlint](https://github.com/rhysd/actionlint)
