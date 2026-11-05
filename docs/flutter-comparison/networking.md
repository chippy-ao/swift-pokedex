# 通信とエラー

JSON のデコード、URLSession、エラーの扱い、HTTP キャッシュ、テストでのスタブの対応です。表の書き方は [README](README.md#表の書き方) を参照してください。方針は [data-layer.md](../data-layer.md) にあります。

| Swift / iOS | Flutter での相当 | 違い | このリポジトリで使っている場所 |
| --- | --- | --- | --- |
| `Codable` + `JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase` | json_serializable の `fieldRename: FieldRename.snake` | どちらも snake_case のキーを camelCase のプロパティに対応させる。違いは、Swift はデコード時に実行時に変換し（コード生成が無い）、`CodingKeys` に snake_case を書くと変換後のキーと合わず `keyNotFound` になること。ハイフン入りのキーだけ `CodingKeys` で指定する | [PokeAPIClient+Live.swift](../../core/NetworkClientURLSession/Sources/PokeAPIClient+Live.swift) |
| `URLSession`（`data(for:)`） | Dio | `URLSession` は 404 や 500 でも投げず、`(Data, URLResponse)` を返す。ステータスは自分で調べる。Dio は 2xx 以外を既定で `DioException` として投げる | [PokeAPIClient+Live.swift](../../core/NetworkClientURLSession/Sources/PokeAPIClient+Live.swift) |
| `throws` / `try` / `do-catch` | Dart の `throw` / `try-catch` | Swift は投げる関数に `throws` の印が要り、呼ぶ側も `try` を書く。Dart は印が無く、どの関数が投げるかは型から分からない | [PokemonRepository.swift](../../core/Repository/Sources/PokemonRepository.swift) |
| `Result<Success, Failure>` | Riverpod の `AsyncValue` | `Result` は成功か失敗の 2 状態だけ。`AsyncValue` は読み込み中を加えた 3 状態で、再取得中に前の値を持てる。読み込み中は Swift では Store の `phase` で持つ | [PokedexFeature の README](../../feature/PokedexFeature/README.md) |
| `URLCache`（`requestCachePolicy = .useProtocolCachePolicy`） | dio_cache_interceptor | `URLSession` に標準で付いていて、サーバーの `cache-control` と `etag` に従う。1 件のレスポンスがディスク容量のおよそ 5% を超えるとキャッシュされない | [PokeAPISession.swift](../../core/NetworkClientURLSession/Sources/PokeAPISession.swift) |
| `URLProtocol` のスタブ（`URLSessionConfiguration.protocolClasses`） | http_mock_adapter | どちらも本物の通信を使わずにレスポンスを返す。http_mock_adapter は Dio のアダプターで、`URLProtocol` は `URLSession` の層で差し込む。スタブのハンドラを static で共有すると、テストを並列に走らせると競合するので `@Suite(.serialized)` にする | [NetworkClientURLSessionTests.swift](../../core/NetworkClientURLSession/Tests/NetworkClientURLSessionTests.swift) |

## 参考リンク

- [Apple JSONDecoder.KeyDecodingStrategy.convertFromSnakeCase](https://developer.apple.com/documentation/foundation/jsondecoder/keydecodingstrategy/convertfromsnakecase)
- [json_serializable（FieldRename）](https://pub.dev/documentation/json_annotation/latest/json_annotation/FieldRename.html)
- [Apple URLSession](https://developer.apple.com/documentation/foundation/urlsession) / [Dio](https://pub.dev/packages/dio)
- [Apple Error handling（The Swift Programming Language）](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/errorhandling/) / [Dart の例外](https://dart.dev/language/error-handling)
- [Apple Result](https://developer.apple.com/documentation/swift/result) / [Riverpod AsyncValue](https://pub.dev/documentation/riverpod/latest/riverpod/AsyncValue-class.html)
- [Apple URLCache](https://developer.apple.com/documentation/foundation/urlcache) / [dio_cache_interceptor](https://pub.dev/packages/dio_cache_interceptor)
- [Apple URLProtocol](https://developer.apple.com/documentation/foundation/urlprotocol) / [http_mock_adapter](https://pub.dev/packages/http_mock_adapter)
