import Dependencies
import Foundation
import Model
import NetworkClient
import Testing

@testable import Repository

struct RepositoryTests {
    private func fetchList(
        returning dto: PokemonListDTO
    ) async throws -> PokemonPage {
        try await withDependencies {
            $0.pokeAPIClient.fetchPokemonList = { _, _ in dto }
        } operation: {
            try await PokemonRepository.liveValue.fetchList(limit: 20, offset: 0)
        }
    }

    private func fetchList(
        throwing error: any Error
    ) async throws -> PokemonPage {
        try await withDependencies {
            $0.pokeAPIClient.fetchPokemonList = { _, _ in throw error }
        } operation: {
            try await PokemonRepository.liveValue.fetchList(limit: 20, offset: 0)
        }
    }

    @Test("url の末尾から ID を取り出す") func extractsIDFromURLTail() async throws {
        let page = try await fetchList(
            returning: PokemonListDTO(
                count: 1351,
                results: [
                    .init(name: "pikachu", url: "https://pokeapi.co/api/v2/pokemon/25/"),
                    .init(name: "venusaur-mega", url: "https://pokeapi.co/api/v2/pokemon/10033/"),
                ]
            ))

        #expect(
            page.items == [
                PokemonSummary(id: 25, name: "pikachu"),
                PokemonSummary(id: 10033, name: "venusaur-mega"),
            ])
    }

    @Test("IDを取り出せない要素があればページ全体が unavailable になる") func unparsableIDMakesPageUnavailable() async {
        await #expect(throws: LoadError.unavailable) {
            try await fetchList(
                returning: PokemonListDTO(
                    count: 2,
                    results: [
                        .init(name: "pikachu", url: "https://pokeapi.co/api/v2/pokemon/25/"),
                        .init(name: "broken", url: "https://pokeapi.co/api/v2/pokemon/"),
                    ]
                ))
        }
    }

    @Test(
        "nextからhasNextが決まる",
        arguments: [
            ("https://pokeapi.co/api/v2/pokemon?offset=20&limit=20", true),
            (nil, false),
        ] as [(String?, Bool)])
    func hasNextFollowsNext(next: String?, expected: Bool) async throws {
        let page = try await fetchList(
            returning: PokemonListDTO(
                count: 1351,
                next: next,
                results: [.init(name: "bulbasaur", url: "https://pokeapi.co/api/v2/pokemon/1/")]
            ))

        #expect(page.hasNext == expected)
    }

    @Test(
        "オフラインのURLErrorはofflineになる",
        arguments: [
            URLError.Code.notConnectedToInternet, .networkConnectionLost, .dataNotAllowed,
        ])
    func offlineURLErrorsBecomeOffline(code: URLError.Code) async {
        await #expect(throws: LoadError.offline) {
            try await fetchList(throwing: URLError(code))
        }
    }

    @Test(
        "それ以外のエラーはunavailableになる",
        arguments: [
            URLError(.timedOut) as any Error,
            URLError(.cannotFindHost),
            URLError(.badServerResponse),
            PokeAPIError.httpStatus(404),
            PokeAPIError.httpStatus(500),
            DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "broken")),
            NSError(domain: "test", code: 1),
        ])
    func otherErrorsBecomeUnavailable(error: any Error) async {
        await #expect(throws: LoadError.unavailable) {
            try await fetchList(throwing: error)
        }
    }

    @Test("CancellationError はそのまま投げ直す") func rethrowsCancellationError() async {
        await #expect(throws: CancellationError.self) {
            try await fetchList(throwing: CancellationError())
        }
    }

    @Test("URLError(.cancelled) はそのまま投げ直す") func rethrowsCancelledURLError() async {
        await #expect {
            try await fetchList(throwing: URLError(.cancelled))
        } throws: { error in
            (error as? URLError)?.code == .cancelled
        }
    }
}
