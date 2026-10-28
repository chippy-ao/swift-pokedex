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
| [development.md](development.md) | 開発の進め方（セットアップ、コミット規約、Lint、PR のチェック） |
| [adr/README.md](adr/README.md) | ADR（Architecture Decision Record）の一覧と書き方 |
| [../feature/PokedexFeature/README.md](../feature/PokedexFeature/README.md) | Pokedex 機能（一覧 / 詳細 / お気に入り）の仕様 |
| [../feature/SettingsFeature/README.md](../feature/SettingsFeature/README.md) | Settings 機能の仕様 |

## ドキュメントの運用ルール

何をどこに書くかを、変更されやすさで分けます。

| 書く内容 | 置き場所 | 更新の方針 |
| --- | --- | --- |
| 変わりにくい設計ルール | `docs/` | 設計が変わったときに更新する |
| 決定の経緯 | `docs/adr/` | 書き換えない（下記） |
| 機能仕様 | 各 feature モジュールの `README.md` | コードと同じ PR で更新する |
| ロードマップとタスク | GitHub Issues + [Milestones](https://github.com/chippy-ao/swift-pokedex/milestones) | ドキュメントには書かない |

### ADR は書き換えない

- ADR は決定した時点の記録なので、後から内容を書き換えません。
- 方針を覆すときは、新しい ADR を追加します。そのうえで、古い ADR のステータスを `Superseded` にします。

### 機能仕様はコードと同じ PR で更新する

- 機能の挙動を変える PR では、該当 feature の `README.md` も同じ PR で更新します。
- コードとドキュメントのずれを防ぐためです。

### タスクは Issues / Milestones で管理する

- フェーズごとの進捗は Milestones、個別のタスクは Issues で管理します。
- ドキュメントには、フェーズの一覧と Milestones ページへのリンクだけを書きます。
