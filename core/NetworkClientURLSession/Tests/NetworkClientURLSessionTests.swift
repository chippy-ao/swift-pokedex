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

    private static func spriteURL(id: Int) -> URL {
        URL(
            string:
                "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png"
        )!
    }

    private static func response(for request: URLRequest, status: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: request.url!, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)!
    }

    @Test("一覧のJSONから id・name・画像のURL・hasNext が作られる")
    func buildsEntriesFromListJSON() async throws {
        let client = makeClient { request in
            (Self.response(for: request, status: 200), Data(listJSON.utf8))
        }

        let dto = try await client.fetchPokemonList(2, 0)

        #expect(
            dto
                == PokemonListDTO(
                    items: [
                        .init(id: 1, name: "bulbasaur", spriteURL: Self.spriteURL(id: 1)),
                        .init(id: 2, name: "ivysaur", spriteURL: Self.spriteURL(id: 2)),
                    ],
                    hasNext: true
                ))
    }

    @Test("番号は url の末尾から取り出す") func extractsIDFromURLTail() async throws {
        let client = makeClient { request in
            let json = """
                { "count": 2, "next": null, "previous": null, "results": [
                  { "name": "pikachu", "url": "https://pokeapi.co/api/v2/pokemon/25/" },
                  { "name": "venusaur-mega", "url": "https://pokeapi.co/api/v2/pokemon/10033/" }
                ] }
                """
            return (Self.response(for: request, status: 200), Data(json.utf8))
        }

        let dto = try await client.fetchPokemonList(2, 24)

        #expect(
            dto.items == [
                .init(id: 25, name: "pikachu", spriteURL: Self.spriteURL(id: 25)),
                .init(id: 10033, name: "venusaur-mega", spriteURL: Self.spriteURL(id: 10033)),
            ])
    }

    @Test("next が null なら hasNext は false") func hasNextIsFalseWhenNextIsNull() async throws {
        let client = makeClient { request in
            let json = """
                { "count": 1, "next": null, "previous": null, "results": [
                  { "name": "bulbasaur", "url": "https://pokeapi.co/api/v2/pokemon/1/" }
                ] }
                """
            return (Self.response(for: request, status: 200), Data(json.utf8))
        }

        let dto = try await client.fetchPokemonList(20, 0)

        #expect(dto.hasNext == false)
    }

    @Test("番号を取り出せない要素があれば一覧全体が unavailable になる")
    func unparsableIDMakesListUnavailable() async {
        let client = makeClient { request in
            let json = """
                { "count": 2, "next": null, "previous": null, "results": [
                  { "name": "pikachu", "url": "https://pokeapi.co/api/v2/pokemon/25/" },
                  { "name": "broken", "url": "https://pokeapi.co/api/v2/pokemon/" }
                ] }
                """
            return (Self.response(for: request, status: 200), Data(json.utf8))
        }

        await #expect(throws: PokeAPIError.unavailable) {
            try await client.fetchPokemonList(20, 0)
        }
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

    @Test("成功以外のステータスは unavailable になる", arguments: [404, 500])
    func nonSuccessStatusBecomesUnavailable(status: Int) async {
        let client = makeClient { request in
            (Self.response(for: request, status: status), Data("{}".utf8))
        }

        await #expect(throws: PokeAPIError.unavailable) {
            try await client.fetchPokemonList(20, 0)
        }
    }

    @Test(
        "オフラインのURLErrorは offline になる",
        arguments: [
            URLError.Code.notConnectedToInternet, .networkConnectionLost, .dataNotAllowed,
        ])
    func offlineURLErrorsBecomeOffline(code: URLError.Code) async {
        let client = makeClient { _ in throw URLError(code) }

        await #expect(throws: PokeAPIError.offline) {
            try await client.fetchPokemonList(20, 0)
        }
    }

    @Test(
        "それ以外のURLErrorは unavailable になる",
        arguments: [URLError.Code.timedOut, .cannotFindHost, .badServerResponse])
    func otherURLErrorsBecomeUnavailable(code: URLError.Code) async {
        let client = makeClient { _ in throw URLError(code) }

        await #expect(throws: PokeAPIError.unavailable) {
            try await client.fetchPokemonList(20, 0)
        }
    }

    @Test("壊れたJSONは unavailable になる") func brokenJSONBecomesUnavailable() async {
        let client = makeClient { request in
            (Self.response(for: request, status: 200), Data("{ \"count\": ".utf8))
        }

        await #expect(throws: PokeAPIError.unavailable) {
            try await client.fetchPokemonList(20, 0)
        }
    }

    @Test("results の形が違うJSONは unavailable になる") func wrongShapeBecomesUnavailable() async {
        let client = makeClient { request in
            (Self.response(for: request, status: 200), Data("{ \"count\": 1 }".utf8))
        }

        await #expect(throws: PokeAPIError.unavailable) {
            try await client.fetchPokemonList(20, 0)
        }
    }

    @Test("URLError(.cancelled) は CancellationError として投げる") func convertsCancelledURLError() async
    {
        let client = makeClient { _ in throw URLError(.cancelled) }

        await #expect(throws: CancellationError.self) {
            try await client.fetchPokemonList(20, 0)
        }
    }

    @Test("タスクのキャンセルは PokeAPIError にならずキャンセルとして届く")
    func taskCancellationIsNotConverted() async {
        let client = makeClient { request in
            Thread.sleep(forTimeInterval: 0.2)
            return (Self.response(for: request, status: 200), Data(listJSON.utf8))
        }

        let task = Task { try await client.fetchPokemonList(2, 0) }
        task.cancel()

        await #expect {
            try await task.value
        } throws: { error in
            error is CancellationError
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
