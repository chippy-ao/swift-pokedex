# 開発の進め方

セットアップ、コミット、Lint、テスト、Issue、PR のチェックのルールをまとめます。決定の経緯は各 ADR を参照してください。

## セットアップ

1. README の「動作環境」に書いたバージョンの Xcode を入れる
2. [mise](https://mise.jdx.dev/) を入れる
3. `mise run bootstrap` を実行する（ツールと Git フックのインストール）

## ツール

ツールのバージョンはルートの `mise.toml` で固定します（[ADR-0012](adr/0012-tool-version-management.md)）。Xcode と、Xcode に同梱されている swift-format は mise の管理外です。ローカルと CI の Xcode のバージョンは手で揃えます（CI 側の指定は[ステータスチェック](#ステータスチェック)を参照）。

fastlane や CocoaPods を使わないので、Ruby と Bundler は入れません。必要になったら新しい ADR を追加します。

| ツール | 用途 |
| --- | --- |
| SwiftLint | Lint |
| prek | Git フックの管理 |
| committed | コミットメッセージの検査 |
| pinact | GitHub Actions を SHA で固定 |
| actionlint | GitHub Actions のワークフローの検査 |
| xcbeautify | `xcodebuild` のログを読みやすく整形 |

## タスク

人も AI も CI も、同じ mise のタスクを使います（[ADR-0012](adr/0012-tool-version-management.md)）。

| タスク | 内容 |
| --- | --- |
| `mise run bootstrap` | ツールと Git フックのインストール |
| `mise run format` | swift-format による整形 |
| `mise run lint` | swift-format、SwiftLint、actionlint による検査と、[依存チェック](package-dependencies.md#依存チェック) |
| `mise run test` | `xcodebuild test`（scheme `Pokedex`、テストプラン `AllTests`）によるビルドとテスト |

`mise run test` は iOS Simulator で実行します。既定では、利用できる iPhone のシミュレーターのうち最後のものを使います。別のものを使うときは、環境変数 `POKEDEX_TEST_DESTINATION` に `xcodebuild` の `-destination` の値（例: `platform=iOS Simulator,name=iPhone 17`）を指定します。

このタスクではマクロの承認ダイアログを `-skipMacroValidation` で省きます（理由は [mise.toml](../mise.toml) のコメント）。Xcode の GUI では引き続き承認を求められます。

## コミット

[Conventional Commits](https://www.conventionalcommits.org/ja/v1.0.0/) に従います（[ADR-0010](adr/0010-commit-and-pr-convention.md)）。

```text
<type>(<scope>): <日本語の説明>
```

- type: 英語で書く。`feat`、`fix`、`docs`、`style`、`refactor`、`perf`、`test`、`build`、`ci`、`chore`、`revert`
- 説明: 日本語で書く
- scope: 任意。付けるときは target 名（`PokedexFeature`、`NetworkClient` など）。許可する scope は `committed.toml` で管理するので、target を追加したら更新する
- 例: `feat(PokedexFeature): 一覧の無限スクロールを追加`

コミットメッセージは次の 3 か所で検査します。ルールは `committed.toml` 1 か所に置き、ローカルと CI で共有します。

| どこで | 何を | ツール |
| --- | --- | --- |
| ローカル | コミットメッセージ | [prek](https://github.com/j178/prek) の commit-msg フックで [committed](https://github.com/crate-ci/committed) を実行。形式が違えばコミットを止める |
| CI | PR 内のすべてのコミットメッセージ | committed にベースから HEAD までの範囲を渡し、`--no-merge-commit` を付けて実行（[conventions.yml](../.github/workflows/conventions.yml)） |
| CI | PR タイトル | committed の `--commit-file` にタイトルを書いたファイルを渡して実行（同上） |

PR タイトルの検査に action-semantic-pull-request を使わないのは、type と scope の一覧を `committed.toml` の 1 か所に保つためです。

## Lint と整形

2 つのツールで役割を分けます（[ADR-0011](adr/0011-lint-and-format.md)）。

| ツール | 役割 | 設定ファイル |
| --- | --- | --- |
| swift-format | 見た目の整形（インデント、改行、空白など）。ツールチェーン同梱の `swift format` を使う | `.swift-format` |
| SwiftLint | 書き方の検査（force unwrap、命名、複雑度など）。swift-format の整形結果とぶつかるルールは無効にする | `.swiftlint.yml` |

実行するタイミングは次のとおりです。

| タイミング | 実行内容 |
| --- | --- |
| コミット時（prek の pre-commit フック） | 変更したファイルに `swift format` を適用し、`swiftlint` で検査する |
| コミット時（prek の pre-commit フック） | `.github/` の変更時は、`pinact run` で GitHub Actions を SHA で固定する |
| CI | `mise run lint`（`swift format lint --strict`、`swiftlint --strict`、actionlint、依存チェック）をリポジトリ全体に実行する |

swift-format の設定は、インデントだけを 4 スペースに上書きしています（`.swift-format`）。Xcode の既定のインデントに合わせ、Xcode の自動インデントと整形結果をそろえるためです。JSON にはコメントを書けないので、理由はここに書いています。ほかの設定は swift-format の既定のままです。

SwiftLint で無効にしたルールと理由は `.swiftlint.yml` のコメントに書いています。swift-format で整形してから `swiftlint --strict` を実行し、整形結果とぶつかったルールだけを無効にしています。ルールを足すときも同じ手順で確かめます。

## テスト

テストは Swift Testing で書きます。書き方の例は [architecture.md の「テストでの待ち方」](architecture.md#テストでの待ち方) を参照してください。

### 進め方

テストが実装に引きずられないよう、テストを先に固めてから実装します。

1. feature の `README.md` の仕様から、テストを先に書く
2. テストを実行し、失敗することを確かめる
3. テストをコミットする
4. テストを変更せずに、テストが通る実装を書く

- 期待値は仕様から取ります。実装を動かして出た値を期待値にしません。
- Reducer（Store の `send`）は「状態とアクション → 次の状態」なので、仕様の表をパラメータ化テスト（`@Test(arguments:)`）にすると漏れを見つけやすくなります。

### 書かないテスト

次のテストは、通っても何も保証しないので書きません。

- 常に通るアサーション（`#expect(1 == 1)`、`#expect(true)` など）
- モックに返させた値を、そのまま検証するだけのテスト
- 実装の内部（private な値や呼び出し順）に依存し、挙動を検証しないテスト

### テストを変えるとき

- 失敗したテストの期待値を、実装に合わせて書き換えません。仕様が変わった場合だけ、合意のうえで変えます（[ドキュメントの運用ルール](README.md#機能の挙動を変えたら同じ-pr-で-readme-を更新する)）。
- 失敗するテストを、合意なしに削除・無効化（`.disabled`）しません。

### UI テスト

組み上げたアプリ（`Pokedex.app`）を起動して確かめるテストです。`app/PokedexUITests`（XCTest の XCUITest）にあり、`app/AllTests.xctestplan` に入っているので `mise run test` で一緒に走ります。単体テストは各層を DI で差し替えるため、アプリ本体が言語を持っているかや、同梱の名前の表と言語の読み取りが実際につながっているかを見られません。そこを見るために置いています。

- 今あるのは [LocalizedNameUITests](../app/PokedexUITests/LocalizedNameUITests.swift) です。起動引数 `-AppleLanguages (ja)` / `(en)` で言語を指定して起動し、一覧の 1 行目に「フシギダネ」/「Bulbasaur」が出るかを見ます。
- 差し替えるのは一覧の通信（`fetchPokemonList`）だけです。CI で PokeAPI を叩かず、結果を決まった値にするためです。環境変数 `POKEDEX_UI_TEST_FIXTURE=1` をテストが渡したときだけ、[PokedexApp.swift](../app/Pokedex/PokedexApp.swift) が差し替えます。
- 名前の表（同梱の JSON）と言語の読み取り（`PreferredLocalization`）は本物を通します。ここを差し替えると、見たいもの（組み上げたアプリでの言語の効き方）を見なくなるためです。
- 走らせ方は単体テストと同じ `mise run test` です（シミュレーターの選び方も同じ）。XCUITest なので、Swift Testing ではなく XCTest で書きます。

## Issue

`.github/ISSUE_TEMPLATE/` のテンプレートから作ります。空の Issue は作れません。

| テンプレート | 使うとき |
| --- | --- |
| 機能・タスク | 機能の実装、開発基盤の作業 |
| 検討 | 方針や仕様を決める議論 |
| バグ | 仕様（README）どおりに動かない |

- フェーズは Milestone で表します。
- ラベルの一覧と意味は [`.github/labels.yml`](../.github/labels.yml) に書きます。main への push 時に [ghaction-github-labeler](https://github.com/crazy-max/ghaction-github-labeler) で GitHub に同期し、ファイルに無いラベルは削除されるので、GitHub の画面では編集しません。テンプレートが付けるラベルは各テンプレートの `labels` を参照してください。
- 先のフェーズの Issue では、「決めること」を普通の箇条書きの検討メモにします。着手時に見直し、チェックボックスに直します。
- Issue で決まったことは Issue に残すだけにせず、[置き場所の表](README.md#置き場所)に従って反映します。

## PR

- [`.github/PULL_REQUEST_TEMPLATE.md`](../.github/PULL_REQUEST_TEMPLATE.md) に沿って書きます。タイトルはコミットと同じ形式で、ステータスチェックで検査します。
- 機能の挙動を変えたら、該当 feature の `README.md` を同じ PR で更新します（[ADR-0001](adr/0001-documentation-policy.md)）。
- 構造に関わる決定をしたら、ADR に残すかを相談します（[ADR を残す基準](README.md#adr-を残す基準)）。

### マージ

- マージ方式は通常のマージ（merge commit）だけを許可します。PR 内のコミットを main に残し、コミットメッセージの検査とテストを先に書いた順番を、履歴で確かめられるようにするためです。
- マージコミットの 1 行目は PR タイトル（例: `feat(PokedexFeature): 一覧の無限スクロールを追加 (#12)`）になり、本文は空です。PR 単位の履歴は `git log --first-parent --oneline` で読めます。
- マージ先の main が進んでいたら、PR のブランチを最新にしてからマージします（ルールセットの strict）。
- main の取り込みは rebase で行います。PR 内にマージコミットを作ると CI の `--no-merge-commit` で落ちます。PR 内のコミットをすべて main に残し、すべて検査するためです。

  ```sh
  git fetch origin
  git rebase origin/main
  git push --force-with-lease
  ```

- GitHub の「Update branch」ボタンは、PR のブランチに main のマージコミットを作るので、リポジトリの設定でオフにします。
- main には直接 push できません。管理者も、ルールを迂回できるのは PR のマージ時だけです。
- マージに承認は求めません。コラボレーターが 1 人で、自分の PR は承認できないためです。代わりに、必須のステータスチェックが通ることを条件にします。
- ルールを迂回する権限（bypass）は緊急用で、普段のマージでは使いません。bypass はステータスチェックも迂回するためです。

### ステータスチェック

次のチェックがすべて通らないと main にマージできません（[ADR-0013](adr/0013-ci-status-checks.md)）。

| チェック | 内容 | ランナー |
| --- | --- | --- |
| PR タイトル（`pr-title`） | Conventional Commits 形式か | `ubuntu-latest` |
| コミットメッセージ（`commit-messages`） | PR 内の全コミットを committed で検査 | `ubuntu-latest` |
| Lint（`lint`） | swift-format、SwiftLint、actionlint、依存チェック | `xcode-27` |
| Build / Test（`build-test`） | `xcodebuild test` で全モジュールとアプリをビルドし、Swift Testing のテストを実行 | `xcode-27` |

- main のルールセットで必須にするのは、個々のジョブではなく、ワークフローごとの集約ジョブ（結果をまとめるだけのジョブ）です。変更のない領域のジョブをスキップしても、集約ジョブが成功すればマージできます。

  | 必須にするジョブ | ワークフロー | まとめるジョブ |
  | --- | --- | --- |
  | `conventions-status` | [conventions.yml](../.github/workflows/conventions.yml) | `pr-title`、`commit-messages` |
  | `ci-status` | [ci.yml](../.github/workflows/ci.yml) | `changes`、`lint`、`build-test` |

- `ci.yml` は PR でだけ走り、main への push では走りません。理由は [ci.yml](../.github/workflows/ci.yml) 冒頭のコメントを参照してください。
- `lint` と `build-test` は、`changes` ジョブが PR の変更ファイルを調べた結果で走らせるかを決めます。対象ファイルの一覧は [ci.yml](../.github/workflows/ci.yml) の `changes` ジョブを参照してください。
  - Swift に関わる変更（Swift のコードや設定など）: `lint` と `build-test` を走らせる
  - ワークフローだけの変更: `lint` だけ走らせる（actionlint のため）
  - docs だけの変更など: どちらも走らせない（skipped）
- 走らせなかったジョブは skipped になり、成功として扱われます。`ci-status` は `changes` が success で、`lint` と `build-test` が success か skipped のときに成功します。`on.pull_request.paths` を使わない理由は [ci.yml](../.github/workflows/ci.yml) 冒頭のコメントを参照してください。
- `xcode-27` は Xcode 27 を入れた GitHub のプレビューのランナーイメージです。ジョブの環境変数 `DEVELOPER_DIR=/Applications/Xcode_27.2.app` で Xcode のバージョンを選び、README の「動作環境」と揃えます。正式なラベルになったら、`.github/actionlint.yaml` の登録を外します。
- CI から呼ぶコマンドは mise のタスクに揃えます。

### PR ラベル

PR を開く・タイトルを編集する・コミットを push するたびに、[pr-labels.yml](../.github/workflows/pr-labels.yml) が次のラベルを付け直します。ラベルの一覧と色は [`.github/labels.yml`](../.github/labels.yml) にあります。

| 種類 | 付くとき | 例 |
| --- | --- | --- |
| `type:<type>` | PR タイトル先頭の type | `feat(Domain)!: ...` なら `type:feat` |
| `package:<名前>` | 変更ファイルが `core/<名前>/`、`feature/<名前>/`、`app/`（`package:Pokedex`）にある | 複数にまたがれば複数付く |
| `size:<XS〜XL>` | 追加と削除の行数の合計 | 区切りは pr-labels.yml のスクリプトを参照 |

- 外すのは、今回付けるべきでない `type:` / `package:` / `size:` だけです。`dependencies` など他のラベルには触りません。
- type や package を足したら、`.github/labels.yml` にもラベルを足します。足し忘れるとワークフローが失敗します。ラベルは main への push で GitHub に同期されるため、足した PR 自身ではまだ付かず、警告になります。
- フォークからの PR では動きません。

### GitHub Actions を書くとき

- `uses:` はタグではなくフルコミット SHA で固定し、末尾にバージョンをコメントで残します。

  ```yaml
  - uses: amannn/action-semantic-pull-request@48f256284bd46cdaab1048c3721360e808335d50 # v6.1.1
  ```

- SHA の固定は手で書かず、pinact で行います。`.github/` 配下の変更時に prek のフックで自動で実行されます。
- ワークフローとジョブの `permissions` は必要な最小限にします。
- `pull_request_target` では PR のコードを checkout しません。

## 依存の更新

GitHub Actions、mise のツール、Swift のパッケージの更新は、[Mend Renovate App](https://github.com/apps/renovate) が PR を出します（[ADR-0016](adr/0016-dependency-updates.md)）。設定の値と理由は [`.github/renovate.json5`](../.github/renovate.json5) のコメントに書きます。

- 月 1 回、minor / patch / digest を「GitHub Actions」「mise のツール」「Swift のパッケージ」の 3 つの PR にまとめます。
- major はまとめず、依存ごとに別の PR にします。
- 自動マージはしません。差分を読み、ステータスチェックが通ってからマージします。
- 全 PR に `dependencies` ラベルが付きます。公開から 3 日たっていないリリースは更新の対象にしません。
- 脆弱性の修正は、月 1 回の予定を待たずに、タイトルの末尾に `[SECURITY]` が付いた PR が出ます。入力は GitHub の Dependabot alerts で、alerts はオン、Dependabot security updates はオフにします。`dependabot.yml` は作りません。
- Renovate の PR のタイトルとコミットは、`ci:`（GitHub Actions）か `build:`（mise と Swift のパッケージ）で始まる日本語の説明にして、コミット規約の検査を通します。

## Xcode プロジェクト

`app/App.xcodeproj` は生成ツールを使わずに直接管理し、buildable folder を使います（[ADR-0014](adr/0014-xcode-project-management.md)）。モジュールの追加や依存の変更は、すべてルートの `Package.swift` で行い、App ターゲットは `@main`、依存の注入、ルート画面と画面遷移だけを持ちます（app のフォルダ構成は [package-dependencies.md](./package-dependencies.md) を参照）。`project.pbxproj` を変更した PR は、Xcode で開けることを確認します。

テスト target を追加したら、`app/AllTests.xctestplan` にも登録します。登録漏れは依存チェックのスクリプトが検出します（[package-dependencies.md](package-dependencies.md#依存チェック)）。
