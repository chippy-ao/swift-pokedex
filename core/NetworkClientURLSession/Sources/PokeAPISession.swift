import Foundation

/// API 専用の URLCache の設定。テストから参照できるよう internal にしている。
enum PokeAPICacheConfiguration {
    // 値の理由は実装ステップでここに書く
    static let memoryCapacity = 20 * 1024 * 1024
    static let diskCapacity = 200 * 1024 * 1024
}

extension URLSession {
    /// API 専用の session。`URLCache.shared` は書き換えない。
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
