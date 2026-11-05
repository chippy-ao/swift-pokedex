import Foundation

/// API 専用の URLCache の設定。テストから参照できるよう internal にしている。
enum PokeAPICacheConfiguration {
    /// メモリ側。一覧と直近に開いた詳細を保持できれば足りる。
    static let memoryCapacity = 20 * 1024 * 1024

    /// ディスク側。URLCache は 1 件のレスポンスがディスク容量のおよそ 5% を超えるとキャッシュしない
    /// （Apple のドキュメント）。2026-11-05 の実測で最大級の `/pokemon/6` が展開後 373,845 バイト、
    /// `/pokemon/25` が 309,106 バイトなので、200 MB なら 5%（10 MB）に十分収まり、
    /// 詳細と species で数百匹分を保持できる。
    /// 全件のオフライン保存はここの役目ではなく、段階 2 の #18 で行う。
    /// 置き場所は Caches ディレクトリなので、OS が必要に応じて消す。
    static let diskCapacity = 200 * 1024 * 1024
}

extension URLSession {
    /// API 専用の session。`URLCache.shared` は書き換えない。
    /// キャッシュ方針は `.useProtocolCachePolicy` で、PokeAPI の `cache-control: public, max-age=86400` と
    /// `etag` に従う。
    static let pokeAPI: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: PokeAPICacheConfiguration.memoryCapacity,
            diskCapacity: PokeAPICacheConfiguration.diskCapacity
        )
        configuration.requestCachePolicy = .useProtocolCachePolicy
        return URLSession(configuration: configuration)
    }()
}
