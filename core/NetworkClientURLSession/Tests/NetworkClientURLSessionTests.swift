import Foundation
import NetworkClient
import Synchronization
import Testing

@testable import NetworkClientURLSession

/// 本物の通信をしない URLProtocol のスタブ。ハンドラは static で共有するので、使うスイートは `.serialized` にする。
class StubURLProtocol: URLProtocol {
    typealias Handler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    private static let handler = Mutex<Handler?>(nil)

    static func setHandler(_ newHandler: Handler?) {
        handler.withLock { $0 = newHandler }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler.withLock({ $0 }) else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

/// PokeAPI の `GET /api/v2/pokemon?limit=2&offset=0` の形に合わせた最小の JSON。
private let listJSON = """
    {
      "count": 1351,
      "next": "https://pokeapi.co/api/v2/pokemon?offset=2&limit=2",
      "previous": null,
      "results": [
        { "name": "bulbasaur", "url": "https://pokeapi.co/api/v2/pokemon/1/" },
        { "name": "ivysaur", "url": "https://pokeapi.co/api/v2/pokemon/2/" }
      ]
    }
    """

@Suite(.serialized)
struct NetworkClientURLSessionTests {
    private func makeClient(
        handler: @escaping StubURLProtocol.Handler
    ) -> PokeAPIClient {
        StubURLProtocol.setHandler(handler)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return PokeAPIClient.live(session: URLSession(configuration: configuration))
    }

    private static func response(for request: URLRequest, status: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: request.url!, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)!
    }

    @Test("一覧のJSONがDTOになる") func decodesListJSONIntoDTO() async throws {
        let client = makeClient { request in
            (Self.response(for: request, status: 200), Data(listJSON.utf8))
        }

        let dto = try await client.fetchPokemonList(2, 0)

        #expect(
            dto
                == PokemonListDTO(
                    count: 1351,
                    next: "https://pokeapi.co/api/v2/pokemon?offset=2&limit=2",
                    previous: nil,
                    results: [
                        .init(name: "bulbasaur", url: "https://pokeapi.co/api/v2/pokemon/1/"),
                        .init(name: "ivysaur", url: "https://pokeapi.co/api/v2/pokemon/2/"),
                    ]
                ))
    }

    @Test("リクエストURLにlimitとoffsetが入る") func requestURLContainsLimitAndOffset() async throws {
        let requested = Mutex<URL?>(nil)
        let client = makeClient { request in
            requested.withLock { $0 = request.url }
            return (Self.response(for: request, status: 200), Data(listJSON.utf8))
        }

        _ = try await client.fetchPokemonList(20, 40)

        let url = try #require(requested.withLock { $0 })
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.host == "pokeapi.co")
        #expect(components.path == "/api/v2/pokemon")
        let items = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) })
        #expect(items == ["limit": "20", "offset": "40"])
    }

    @Test("成功以外のステータスはPokeAPIErrorになる", arguments: [404, 500])
    func nonSuccessStatusThrowsPokeAPIError(status: Int) async {
        let client = makeClient { request in
            (Self.response(for: request, status: status), Data("{}".utf8))
        }

        await #expect(throws: PokeAPIError.httpStatus(status)) {
            try await client.fetchPokemonList(20, 0)
        }
    }

    @Test("URLError は包まずにそのまま届く") func propagatesURLErrorUnwrapped() async {
        let client = makeClient { _ in throw URLError(.notConnectedToInternet) }

        await #expect(throws: URLError(.notConnectedToInternet)) {
            try await client.fetchPokemonList(20, 0)
        }
    }

    @Test("壊れたJSONはDecodingErrorになる") func brokenJSONThrowsDecodingError() async {
        let client = makeClient { request in
            (Self.response(for: request, status: 200), Data("{ \"count\": ".utf8))
        }

        await #expect {
            try await client.fetchPokemonList(20, 0)
        } throws: { error in
            error is DecodingError
        }
    }

    /// 2026-11-05 の実測で最大級の `/pokemon/6` の展開後サイズ。
    /// URLCache はディスク容量のおよそ 5% を超えるレスポンスをキャッシュしない。
    @Test("最大の詳細レスポンスがディスク容量の5パーセントに収まる") func largestDetailResponseFitsInCacheLimit() {
        let largestDetailResponseBytes = 373_845
        let cacheableLimit = PokeAPICacheConfiguration.diskCapacity / 20

        #expect(largestDetailResponseBytes <= cacheableLimit)
    }
}
