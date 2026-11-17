# ADR-0022: NetworkClient が Model を見てよいことにする

- ステータス: 承認済み
- 日付: 2026-11-17
- 関連: [ADR-0017](0017-network-client-interface-independent-of-transport.md)（代替案の表の「interface は Model に依存しない」だけを改める。ほかの決定は変えない）、[ADR-0018](0018-bundled-pokemon-names-table.md)（名前の表）、[ADR-0007](0007-localization.md)（言語の選び方）、[Issue #10](https://github.com/chippy-ao/swift-pokedex/issues/10)

## コンテキスト

名前検索（#10）を、同梱の名前の表の中で、設定言語の名前だけを対象にして行う。そのため、通信の層（`NetworkClient`）の interface が「どの言語で探すか」を受け取る必要がある。

言語コード（`LanguageCode`）は Model にある。ところが `NetworkClient` は Model に依存しておらず（ADR-0017 の代替案の表に「interface は Model に依存しない」とある）、言語を文字列（`"ja-hrkt"`）で受け取り、Repository が `LanguageCode` と文字列を相互に変換することになる。

Model には性質の違う 2 種類が混ざっている。

- ただの値: `LanguageCode`、`LocalizedName`、`PokemonType`、`PokemonStat` など
- アプリ向けの型: `LoadError`（画面に見せるエラー）、`PokemonSummary`、`PokemonDetail` など

ADR-0017 が避けたかったのは、後者の `LoadError` を通信の層が知ることだった。前者を通信の層が見ることは、避けたい対象ではなかった。

## 決定

- `NetworkClient` が `Model` に依存してよいことにする（依存グラフに `NetworkClient --> Model` を足す）。実装の `NetworkClientURLSession` も、interface の引数や戻りに出てくる Model の値を使うので、`Model` に依存してよい（`NetworkClientURLSession --> Model`）。
- 通信の層は、`LoadError` を投げない。ADR-0017 のとおり `PokeAPIError`（「通信できない」と「取得できない」の 2 種類）だけを投げ、Repository が `LoadError` に変換する。
- DTO は残す。DTO を Model に置き換えるかは、この ADR では決めない。
- Model のフォルダ構成は変えない。モジュール名も `Model` のままにする。

## 理由

- 公開されている実例は、通信の層が共有モデルを見る形になっている。Now in Android は `core:network` が `core:model` に依存している（`core:model` はどのモジュールにも依存しない）。isowords は `ApiClient` と `ApiClientLive` が `SharedModels` に依存している。
- `LanguageCode` のような値を、通信の層が文字列で受け取って Repository が変換する、という往復が要らなくなる。
- `Model` は `Common` にしか依存しないので、`NetworkClient` が `Model` を見ても循環しない。

## 検討した代替案

| 案 | 不採用理由 |
| --- | --- |
| 言語を文字列のまま渡す | ADR-0017 を守れるが、変換が 1 回増える。同じ悩みが、次に Model の値を通信の層が欲しくなったときにも出る |
| `LanguageCode` を `Common` に置く | `Common` は道具の置き場（Now in Android では dispatcher や `Result`）で、ドメインの値を置く場所ではない。言語コードは Model の仲間 |
| Model を「ただの値」と「アプリ向け」に割る | `LoadError` を通信の層から隠せるが、新しいモジュールが要り、型の振り分けと全 import の見直しが大きい。`Repository` が `LoadError` を作るので、置き場所も `Model` と `Common` の 2 つしかない |
| `Model` を `SharedModel` に改名する | 通信の層も見てよいことは名前でなく依存グラフで決まる。core は全部共有なので `Shared` の効果が薄く、全 import が変わる |

## 影響

### 良い点

- 言語を `LanguageCode` のまま、通信の層まで渡せる。
- 同じ形（通信の層が共有の値を見る）の実例と揃う。

### 悪い点・注意点

- 通信の層から `LoadError` も見えるようになる。「通信の層は `LoadError` を投げない」は、依存では防げず、決まりとして守る。
- DTO と Model が同じ形に見える悩み（ADR-0017 の「悪い点」）が強くなる。DTO を残すか消すかは、別の機会に決める。

## 参考リンク

- [Now in Android: core/network の build.gradle.kts](https://github.com/android/nowinandroid/blob/main/core/network/build.gradle.kts)
- [Now in Android: モジュール化の説明](https://github.com/android/nowinandroid/blob/main/docs/ModularizationLearningJourney.md)
- [isowords の Package.swift](https://github.com/pointfreeco/isowords/blob/main/Package.swift)
