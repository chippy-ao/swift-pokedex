import Dependencies
import Foundation
import Model
import NetworkClient
import Testing

@testable import Repository

struct RepositoryTests {
    private func fetchList(
        returning dto: PokemonListDTO,
        names: [Int: [LocalizedNameDTO]] = [:]
    ) async throws -> PokemonListPage {
        try await withDependencies {
            $0.pokeAPIClient.fetchPokemonList = { _, _ in dto }
            $0.pokeAPIClient.fetchAllPokemonSpeciesNames = { names }
        } operation: {
            try await PokemonRepository.liveValue.fetchList(limit: 20, offset: 0)
        }
    }

    private func fetchList(
        throwing error: any Error,
        namesThrowing namesError: (any Error)? = nil
    ) async throws -> PokemonListPage {
        try await withDependencies {
            $0.pokeAPIClient.fetchPokemonList = { _, _ in throw error }
            $0.pokeAPIClient.fetchAllPokemonSpeciesNames = { throw namesError ?? error }
        } operation: {
            try await PokemonRepository.liveValue.fetchList(limit: 20, offset: 0)
        }
    }

    private static func spriteURL(id: Int) -> URL {
        URL(string: "https://example.com/sprites/\(id).png")!
    }

    @Test("DTO の items が PokemonListEntry（識別子と画像のURL含む）に移る")
    func mapsItemsToEntries() async throws {
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
                PokemonListEntry(
                    id: 25, identifier: "pikachu", names: [], spriteURL: Self.spriteURL(id: 25)),
                PokemonListEntry(
                    id: 10033, identifier: "venusaur-mega", names: [],
                    spriteURL: Self.spriteURL(id: 10033)),
            ])
    }

    @Test("名前の表が id でくっつき、DTO の言語コードは LanguageCode になる")
    func attachesNamesByID() async throws {
        let page = try await fetchList(
            returning: PokemonListDTO(
                items: [
                    .init(id: 122, name: "mr-mime", spriteURL: Self.spriteURL(id: 122)),
                    .init(id: 25, name: "pikachu", spriteURL: Self.spriteURL(id: 25)),
                ],
                hasNext: false
            ),
            names: [
                122: [
                    LocalizedNameDTO(languageCode: "en", name: "Mr. Mime"),
                    LocalizedNameDTO(languageCode: "ja-hrkt", name: "バリヤード"),
                ],
                25: [LocalizedNameDTO(languageCode: "en", name: "Pikachu")],
            ])

        #expect(
            page.items.map(\.names) == [
                [
                    LocalizedName(languageCode: .en, name: "Mr. Mime"),
                    LocalizedName(languageCode: .jaHrkt, name: "バリヤード"),
                ],
                [LocalizedName(languageCode: .en, name: "Pikachu")],
            ])
    }

    @Test("名前の表に無い id は名前が空になる")
    func missingIDHasNoNames() async throws {
        let page = try await fetchList(
            returning: PokemonListDTO(
                items: [
                    .init(id: 1, name: "bulbasaur", spriteURL: Self.spriteURL(id: 1)),
                    .init(id: 2, name: "ivysaur", spriteURL: Self.spriteURL(id: 2)),
                ],
                hasNext: false
            ),
            names: [1: [LocalizedNameDTO(languageCode: "en", name: "Bulbasaur")]])

        #expect(page.items.map(\.names.count) == [1, 0])
    }

    @Test("名前の表の取得が失敗したら LoadError になる")
    func namesFailureBecomesLoadError() async {
        await #expect(throws: LoadError.offline) {
            try await withDependencies {
                $0.pokeAPIClient.fetchPokemonList = { _, _ in
                    PokemonListDTO(items: [], hasNext: false)
                }
                $0.pokeAPIClient.fetchAllPokemonSpeciesNames = { throw PokeAPIError.offline }
            } operation: {
                try await PokemonRepository.liveValue.fetchList(limit: 20, offset: 0)
            }
        }
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
