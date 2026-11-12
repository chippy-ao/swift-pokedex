# ADR-0018: ポケモン名を同梱の表から返す

- ステータス: 承認済み
- 日付: 2026-11-12
- 関連: [ADR-0009](0009-license.md) の「データはリポジトリに含めない」に例外を 1 つ足す(覆さない)。[ADR-0007](0007-localization.md) の言語の選び方はそのまま使う

## コンテキスト

一覧のポケモン名をアプリの言語(英語と日本語)で出したくなりました。ところが一覧の API(`GET /pokemon`)が返すのは識別子(`mr-mime`)だけで、日本語名は 1 件ずつ `GET /pokemon-species/{id}` を取らないと分かりません。

- 1 ページ(20 件)で 20 回、API を叩くことになる。
- 日本語名での検索([Issue #10](https://github.com/chippy-ao/swift-pokedex/issues/10))には、全 species の名前が要る。約 1000 回になる。

PokeAPI の Fair Use Policy は、リクエストを抑えることを求めています([data-layer.md](../data-layer.md#fair-use-policy-の要点))。

## 決定

- 名前は API から取らず、PokeAPI のリポジトリの CSV(`pokemon_species_names.csv`)から作った表(`en` と `ja-hrkt` だけ)を同梱して返す。本来は API で取れるものを、あえて取っていない。
- 表は `NetworkClientURLSession` の `Resources/` に置き、`PokeAPIClient.fetchAllPokemonSpeciesNames` の裏で返す。interface からは API と見分けがつかない([ADR-0017](0017-network-client-interface-independent-of-transport.md))。
- 表は Swift のスクリプトで作り、できた JSON をコミットする(`mise run generate-pokemon-names`)。ビルドのたびに通信しない。CSV は PokeAPI のコミット SHA で固定する。
- 名前は言語を選ばずに全部の言語で運び、Domain の UseCase が 1 回だけ選ぶ([ADR-0007](0007-localization.md))。
- ADR-0009 の例外として、この表をリポジトリに含める。表は MIT の対象外で、PokeAPI の BSD-3-Clause の対象。名前は Nintendo の商標。LICENSE を表と同じ場所に同梱し、リポジトリの README とアプリのライセンス画面([Issue #14](https://github.com/chippy-ao/swift-pokedex/issues/14))に書く。

## 理由

- API の回数が 0 回で済む。名前の取得失敗(オフラインなど)も起きない。
- interface の裏に置けば、まとめて名前を返す API が使えるようになったとき、実装だけを差し替えられる。

## 検討した代替案

| 案 | 不採用理由 |
| --- | --- |
| 行ごとに species を取る | 1 ページで 20 回、日本語検索には約 1000 回。Fair Use Policy に反しやすい |
| PokeAPI の GraphQL | beta で、1 時間 100 回 / IP の制限があり、毎日 1 AM UTC ごろに約 2 分止まる。アプリの土台にするには不安定 |
| 表を Repository に置く | 通信の層の答えが Repository に混ざる。interface の裏に置けば差し替えが実装だけで済む |
| 一覧の 1 件ずつに名前をくっつけて返す | 名前の表と一覧を別々に取れなくなり、言語が増えると型が変わる。全部の言語で運び、UseCase で選ぶほうが型が変わらない |
| 全 12 言語を入れる | 約 246KB。`en` と `ja-hrkt` だけなら約 52KB。使わない言語を同梱する理由が無い |

## 影響

### 良い点

- 一覧の表示で API の呼び出しが増えない。日本語名の検索([#10](https://github.com/chippy-ao/swift-pokedex/issues/10))も、全件の名前をローカルで持てる。
- 言語が増えても、型(`LocalizedName`)は変わらない。

### 悪い点・注意点

- 新しいポケモンが出たら、表を作り直す(`mise run generate-pokemon-names`)。表に無い番号は、英語、それも無ければ識別子で出る。
- `NetworkClientURLSession` が、通信しない答えを返す。名前に「URLSession の箱」と合わない。interface の裏のことなので、使う側からは見えない。
- 表と LICENSE を同梱するので、権利の表示を欠かさない。

## 参考リンク

- [PokeAPI Fair Use Policy](https://pokeapi.co/docs/v2)
- [PokeAPI のリポジトリ](https://github.com/PokeAPI/pokeapi)
