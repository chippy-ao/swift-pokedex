# 開発の進め方

セットアップ、コミット、Lint、テスト、Issue、PR のチェックのルールをまとめます。決定の経緯は各 ADR を参照してください。

> コードはまだ無いため、ここに書いたファイル（`mise.toml`、`committed.toml` など）とタスクは導入時に作ります。

## セットアップ

1. README の「動作環境」に書いたバージョンの Xcode を入れる
2. [mise](https://mise.jdx.dev/) を入れる
3. `mise run bootstrap` を実行する（ツールと Git フックのインストール）

## ツール

ツールのバージョンはルートの `mise.toml` で固定します（[ADR-0012](adr/0012-tool-version-management.md)）。Xcode と、Xcode に同梱されている swift-format は mise の管理外です。ローカルと CI の Xcode のバージョンは手で揃えます。

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
| `mise run lint` | swift-format と SwiftLint による検査 |
| `mise run test` | `xcodebuild test` によるビルドとテスト |

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
| CI | PR 内のすべてのコミットメッセージ | committed にベースから HEAD までの範囲を渡して実行 |
| CI | PR タイトル | [amannn/action-semantic-pull-request](https://github.com/amannn/action-semantic-pull-request) |

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
| CI | `swift format lint --strict` と `swiftlint --strict` をリポジトリ全体に実行する |

SwiftLint で無効にするルールは、導入時に swift-format と突き合わせて決めます。

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

- `.github/PULL_REQUEST_TEMPLATE.md` に従って書きます。テンプレートの項目は次のとおりです。
  - 概要と関連 Issue（`Closes #N`）
  - 変更内容
  - 確認方法（スクリーンショットを含む）
  - チェックリスト: feature の `README.md` を同じ PR で更新したか、仕様を変えた場合に Issue / PR で合意したか、既存テストの期待値を変えた場合にその理由を書いたか、設計を変えた場合に ADR を追加したか
- 機能の挙動を変えたら、該当 feature の `README.md` を同じ PR で更新します（[ADR-0001](adr/0001-documentation-policy.md)）。
- 設計を変えたら ADR を追加します。

### ステータスチェック

次のチェックがすべて通らないと main にマージできません（[ADR-0013](adr/0013-ci-status-checks.md)）。

| チェック | 内容 | ランナー |
| --- | --- | --- |
| PR タイトル | Conventional Commits 形式か | Linux |
| コミットメッセージ | PR 内の全コミットを committed で検査 | Linux |
| Lint | swift-format、SwiftLint、actionlint | macOS |
| Build / Test | `xcodebuild test` で全モジュールとアプリをビルドし、Swift Testing のテストを実行 | macOS |

- main のルールセットで必須にするのは、個々のジョブではなく、ワークフローごとの集約ジョブ（結果をまとめるだけのジョブ）です。変更のない領域のジョブをスキップしても、集約ジョブが成功すればマージできます。
- CI から呼ぶコマンドは mise のタスクに揃えます。

### GitHub Actions を書くとき

- `uses:` はタグではなくフルコミット SHA で固定し、末尾にバージョンをコメントで残します。

  ```yaml
  - uses: amannn/action-semantic-pull-request@48f256284bd46cdaab1048c3721360e808335d50 # v6.1.1
  ```

- SHA の固定は手で書かず、pinact で行います。`.github/` 配下の変更時に prek のフックで自動で実行されます。
- ワークフローとジョブの `permissions` は必要な最小限にします。
- `pull_request_target` では PR のコードを checkout しません。

## Xcode プロジェクト

`app/Pokedex` の Xcode プロジェクトは生成ツールを使わずに直接管理し、buildable folder を使います（[ADR-0014](adr/0014-xcode-project-management.md)）。モジュールの追加や依存の変更は、すべてルートの `Package.swift` で行い、Xcode プロジェクトはアプリの入口だけを持つ薄い殻にします。`project.pbxproj` を変更した PR は、Xcode で開けることを確認します。
