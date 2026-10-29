# ドキュメント目次

swift-pokedex のドキュメントの入口です。

## ドキュメント一覧

| ドキュメント | 役割 |
| --- | --- |
| [../README.md](../README.md) | プロジェクトの概要、学習ゴール、技術スタックの要約 |
| [architecture.md](architecture.md) | 全体のアーキテクチャ（3層構成、MVI、ナビゲーション、テーマ色など） |
| [package-dependencies.md](package-dependencies.md) | モジュール構成と、target ごとの依存ルール |
| [dependency-injection.md](dependency-injection.md) | swift-dependencies による DI の方針と interface / 実装の分け方 |
| [data-layer.md](data-layer.md) | NetworkClient / Database / Datastore / Repository とキャッシュ方針、PokeAPI のメモ |
| [development.md](development.md) | 開発の進め方（セットアップ、コミット規約、Lint、テスト、Issue、PR のチェック） |
| [adr/README.md](adr/README.md) | ADR（Architecture Decision Record）の一覧と書き方 |
| [../feature/PokedexFeature/README.md](../feature/PokedexFeature/README.md) | Pokedex 機能（一覧 / 詳細 / お気に入り）の仕様 |
| [../feature/SettingsFeature/README.md](../feature/SettingsFeature/README.md) | Settings 機能の仕様 |

## ドキュメントの運用ルール

このルールを採用した理由は [ADR-0001](adr/0001-documentation-policy.md) を参照してください。

### 置き場所

| 置き場所 | 答える問い | 書かないもの |
| --- | --- | --- |
| `docs/adr/`（ADR） | なぜそれを選んだか、何を捨てたか（結論・理由・検討した代替案） | 手順、設定値、一覧表、コード例（`docs/` に一本化し、ADR からはリンクする） |
| `docs/` | プロジェクト全体の「今の」ルールと書き方 | 選んだ理由の長文（ADR へリンクする）、1 モジュールだけの話 |
| 各パッケージの `README.md`（`feature/*/README.md` など） | そのモジュールの責務と仕様（画面仕様、State / Action など） | 横断ルール（`docs/` へリンクする）、実装フェーズ、未決事項 |
| ルートの [README.md](../README.md) | プロジェクトの入口（概要、動作環境、リンク） | 詳細 |
| [CLAUDE.md](../CLAUDE.md) | AI が毎回守ることの要点と `docs/` へのリンク | `docs/` の中身のコピー |
| GitHub Issues / [Milestones](https://github.com/chippy-ao/swift-pokedex/milestones) | タスク、フェーズ、未決事項 | — |

### 2 つのルール

1. 同じことは 2 か所に書きません。書きたくなったらリンクを貼ります。
2. 理由は、決めたもののすぐ近くに書きます。
   - 値や実装の細部: コードのコメント
   - モジュールの仕様: パッケージの `README.md`
   - 全体ルール: `docs/`
   - 構造に関わる決定: ADR

### ADR を残す基準

- 開発者と AI の 2 人が「ADR に残そう」と合意したものだけを残します。
- 判断の目安は、Nygard の 5 領域（構造、非機能特性、依存、インターフェース、作り方）に影響し、かつ「戻すのが大変」か「複数の案を比べて捨てた」ことです。
- それ以外の判断は Issue / PR に書きます。
- ADR は承認後に書き換えません（誤字修正などを除く）。覆すときは新しい ADR を追加し、古い ADR を `Superseded` にします（書き方は [adr/README.md](adr/README.md)）。
- 流れ: Issue で議論 → （合意したら）ADR で決める → `docs/` にルールとして書く → PR で実装する。

### 機能の挙動を変えたら同じ PR で README を更新する

- 機能の挙動を変える PR では、該当 feature の `README.md` も同じ PR で更新します。コードとドキュメントのずれを防ぐためです。
- 仕様（feature の `README.md`）は「意図」を書く場所で、コードの説明ではありません。実装中に分かった事実（API の制約など）で仕様を変えるのはかまいませんが、先に Issue / PR で理由を示して合意してからコードを合わせます。書いたコードに合わせて README を後から書き換えると、バグまで仕様になってしまうためです。
