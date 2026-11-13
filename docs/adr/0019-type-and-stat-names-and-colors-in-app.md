# ADR-0019: タイプと種族値の名前と色をアプリに持つ

- ステータス: 承認済み
- 日付: 2026-11-13
- 関連: [ADR-0007](0007-localization.md) の言語の選び方はそのまま使う。[ADR-0018](0018-bundled-pokemon-names-table.md) とは違い、NetworkClient の裏には置かない

## コンテキスト

詳細画面([Issue #8](https://github.com/chippy-ao/swift-pokedex/issues/8))で、タイプ名(「くさ」「どく」)と種族値の名前(「こうげき」)をアプリの言語で出したくなりました。これらの名前は API(`GET /type/{name}`、`GET /stat/{name}`)の `names` で取れます。

## 決定

- タイプ(18 種類)と種族値(6 種類)を、Model の enum(`PokemonType`、`PokemonStatKind`)で持つ。`rawValue` は PokeAPI の識別子(`"grass"`、`"special-attack"`)にする。
- 名前は PokedexFeature の `Localizable.xcstrings` に en / ja で持つ。色は PokedexFeature のコードに置く。
- API の識別子は Repository で enum に変える。知らない識別子は、その 1 つだけ落とす(取得の失敗にはしない)。DTO は `String` のままにする([data-layer.md](../data-layer.md#言語コードと変換ルール))。

## 理由

- タイプと種族値は数が決まっていて、ほぼ変わらない。
- `/type` と `/stat` を叩かずに済む。詳細 1 件で最大 8 回(タイプ 2 + 種族値 6)の余分な取得が要らず、その取得に失敗したときの扱いも要らない。
- 色は API に無いので、アプリに置くしかない。名前も同じ場所に置ける。
- タイプ相性(別の Issue)も、同じ enum を使える。
- enum なら `switch` の網羅チェックが効き、色や名前の書き忘れがコンパイルエラーになる。

## 検討した代替案

| 案 | 不採用理由 |
| --- | --- |
| API の `names` から取る | 詳細 1 件で最大 8 回の取得が増える。失敗したときの表示も決める必要がある。色は API に無いので、結局アプリにも持つことになる |
| ADR-0018 のように、NetworkClient の裏に表を置く | ポケモン名は本来 API から取るデータなので、あとで API に戻す余地を残せた。タイプは色や相性を含む「アプリの言葉」なので、その余地を捨てる。名前と色で置き場所が 2 か所に割れる |
| `LanguageCode` のような `RawRepresentable` の struct | 未知の値を運べても、出す色も名前も無い。`switch` の網羅チェックが効かない |

## 影響

### 良い点

- 詳細の表示で API の呼び出しが増えない。
- 色と名前の書き忘れが、コンパイルエラーで分かる。

### 悪い点・注意点

- 新しいタイプや種族値が増えたら、手で足す。enum、`Localizable.xcstrings`、色の表を更新する。それまで、知らない識別子は表示されない。

## 参考リンク

- [PokeAPI の Type](https://pokeapi.co/docs/v2#type)
- [PokeAPI の Stat](https://pokeapi.co/docs/v2#stat)
