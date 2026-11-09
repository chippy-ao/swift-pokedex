# ADR-0017: NetworkClient の interface を通信方式に依らない形にする

- ステータス: 承認済み
- 日付: 2026-11-09
- 関連: [ADR-0004](0004-dependency-injection.md) の「API レベルの interface」に条件を足す(覆さない)

## コンテキスト

[ADR-0004](0004-dependency-injection.md) で、NetworkClient の interface を API レベル(一覧取得、詳細取得など)にすると決めました。ところが実際の DTO は REST のレスポンスの形のままでした。そのため、Repository が次のことを知っていました。

- 一覧の `results[].url` の末尾から番号を切り出すこと
- 次のページが `next` の URL で表されること
- 通信の失敗が `URLError` や HTTP ステータスで表されること

通信方式を変える(たとえば GraphQL にする)と、NetworkClient の実装だけでなく Repository まで直すことになります。API レベルにした意味が薄れていました。

## 決定

NetworkClient の interface が返す DTO とエラーに、通信方式(REST)の仕組みを前提にした値を入れません。

- DTO は、使う側が欲しい値だけを持つ(番号、名前、画像の URL、次があるか)。
- エラーは「通信できない」と「取得できない」の 2 種類だけにする。
- REST のレスポンスの読み取り、番号の取り出し、画像の URL づくり、エラーの仕分けは、通信の実装(`NetworkClientURLSession`)の中に閉じ込める。
- Repository は DTO を Model に移すことと、`PokeAPIError` を Model の `LoadError` に変えることだけを行う。Foundation の `URLError` は知らない。

避けるのは「REST の仕組みを知らないと使えない値」です。名前や形が REST と被ること自体は問題ありません。具体的な型とエラーの仕分けは [data-layer.md](../data-layer.md#networkclient-と-networkclienturlsession) を参照してください。

## 理由

- 依存性逆転の原則です。抽象(interface)は、実装の都合ではなく、使う側(Repository)の都合で決めます。使う側が欲しいのは番号と名前と画像と「次があるか」で、URL の切り出し方は欲しくありません。
- 通信方式を変えたときに直すのが `NetworkClientURLSession` だけで済みます。Repository とそのテストは変わりません。
- 切り出しやエラーの仕分けを通信の実装に寄せると、それらのテストも実装のテストに集まります。

## 検討した代替案

| 案 | 不採用理由 |
| --- | --- |
| REST の形のまま返す | Repository が URL の切り出しと `URLError` を知り続ける。通信方式を変えると Repository まで直すことになる |
| `PokeAPIError` に `httpStatus` を残す | HTTP を前提にした値が interface に残る。画面で必要な区別はオフラインかどうかだけで、ステータスごとの出し分けはしない |
| `LoadError` を NetworkClient から直接投げる | 画面向けのエラー(Model)を通信の層が知ることになり、層の責務が混ざる。interface は Model に依存しない |

## 影響

### 良い点

- 通信方式を変えても、影響が `NetworkClientURLSession` に閉じる。
- Repository が Foundation の `URLError` を知らなくなり、テストも単純になる。

### 悪い点・注意点

- DTO と Model がほぼ同じ形になり、変換が単純な写しに見える。ただし答える問いが違う(DTO は通信の層が返す値、Model はアプリが扱う値)ので分けておく。
- 通信の実装に、番号の取り出しとエラーの仕分けが増える。

## 参考リンク

- [Dependency inversion principle](https://en.wikipedia.org/wiki/Dependency_inversion_principle)
