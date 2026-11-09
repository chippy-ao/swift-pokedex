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

    private static func spriteURL(id: Int) -> URL {
        URL(string: "https://example.com/sprites/\(id).png")!
    }

    @Test("DTO の items が PokemonSummary（画像のURL含む）に移る") func mapsItemsToSummaries() async throws {
        let page = try await fetchList(
            returning: PokemonListDTO(
                items: [
                    .init(id: 25, name: "pikachu", spriteURL: Self.spriteURL(id: 25)),
                    .init(id: 10033, name: "venusaur-mega", spriteURL: Self.spriteURL(id: 10033)),
                ],
                hasNext: true
            ))

        #expect(
            page.items == [
                PokemonSummary(id: 25, name: "pikachu", spriteURL: Self.spriteURL(id: 25)),
                PokemonSummary(
                    id: 10033, name: "venusaur-mega", spriteURL: Self.spriteURL(id: 10033)),
            ])
    }

    @Test("DTO の hasNext が PokemonPage に移る", arguments: [true, false])
    func mapsHasNext(hasNext: Bool) async throws {
        let page = try await fetchList(
            returning: PokemonListDTO(
                items: [.init(id: 1, name: "bulbasaur", spriteURL: Self.spriteURL(id: 1))],
                hasNext: hasNext
            ))

        #expect(page.hasNext == hasNext)
    }

    @Test("PokeAPIError.offline は LoadError.offline になる") func offlineBecomesOffline() async {
        await #expect(throws: LoadError.offline) {
            try await fetchList(throwing: PokeAPIError.offline)
        }
    }

    @Test("PokeAPIError.unavailable は LoadError.unavailable になる")
    func unavailableBecomesUnavailable() async {
        await #expect(throws: LoadError.unavailable) {
            try await fetchList(throwing: PokeAPIError.unavailable)
        }
    }

    @Test("CancellationError はそのまま投げ直す") func rethrowsCancellationError() async {
        await #expect(throws: CancellationError.self) {
            try await fetchList(throwing: CancellationError())
        }
    }
}
