import Dependencies
import Foundation
import Model
import NetworkClient
import Testing

@testable import Repository

struct PokemonDetailRepositoryTests {
    private static let artworkURL = URL(string: "https://example.com/artwork/1.png")!

    private static func detailDTO(
        id: Int = 1, speciesID: Int = 1, types: [String] = ["grass", "poison"],
        stats: [PokemonDetailDTO.Stat] = [
            .init(name: "hp", baseValue: 45),
            .init(name: "attack", baseValue: 49),
            .init(name: "defense", baseValue: 49),
            .init(name: "special-attack", baseValue: 65),
            .init(name: "special-defense", baseValue: 65),
            .init(name: "speed", baseValue: 45),
        ],
        height: Int = 7, weight: Int = 69, artworkURL: URL? = artworkURL
    ) -> PokemonDetailDTO {
        PokemonDetailDTO(
            id: id, name: "bulbasaur", speciesID: speciesID, types: types, stats: stats,
            height: height, weight: weight, artworkURL: artworkURL)
    }

    private static let speciesDTO = PokemonSpeciesDTO(
        names: [
            LocalizedNameDTO(languageCode: "ja-hrkt", name: "フシギダネ"),
            LocalizedNameDTO(languageCode: "en", name: "Bulbasaur"),
        ],
        genera: [
            LocalizedNameDTO(languageCode: "ja-hrkt", name: "たねポケモン"),
            LocalizedNameDTO(languageCode: "en", name: "Seed Pokémon"),
        ])

    private actor Recorder {
        private(set) var requestedSpeciesIDs: [Int] = []
        func record(speciesID: Int) { requestedSpeciesIDs.append(speciesID) }
    }

    private func fetchDetail(
        id: Int = 1,
        pokemon: @escaping @Sendable (Int) async throws -> PokemonDetailDTO,
        species: @escaping @Sendable (Int) async throws -> PokemonSpeciesDTO = { _ in
            PokemonDetailRepositoryTests.speciesDTO
        }
    ) async throws -> PokemonDetailEntry {
        try await withDependencies {
            $0.pokeAPIClient.fetchPokemonDetail = pokemon
            $0.pokeAPIClient.fetchPokemonSpecies = species
        } operation: {
            try await PokemonRepository.liveValue.fetchDetail(id: id)
        }
    }

    @Test("pokemon と species が 1 つの PokemonDetailEntry にまとまる")
    func combinesPokemonAndSpecies() async throws {
        let entry = try await fetchDetail { _ in Self.detailDTO() }

        #expect(
            entry
                == PokemonDetailEntry(
                    id: 1, identifier: "bulbasaur",
                    names: [
                        LocalizedName(languageCode: .jaHrkt, name: "フシギダネ"),
                        LocalizedName(languageCode: .en, name: "Bulbasaur"),
                    ],
                    genera: [
                        LocalizedName(languageCode: .jaHrkt, name: "たねポケモン"),
                        LocalizedName(languageCode: .en, name: "Seed Pokémon"),
                    ],
                    types: [.grass, .poison],
                    stats: [
                        PokemonStat(kind: .hp, value: 45),
                        PokemonStat(kind: .attack, value: 49),
                        PokemonStat(kind: .defense, value: 49),
                        PokemonStat(kind: .specialAttack, value: 65),
                        PokemonStat(kind: .specialDefense, value: 65),
                        PokemonStat(kind: .speed, value: 45),
                    ],
                    heightInMeters: 0.7, weightInKilograms: 6.9, artworkURL: Self.artworkURL))
    }

    @Test(
        "高さと重さは 0.1 単位の整数から m と kg に直す",
        arguments: [
            (height: 7, weight: 69, meters: 0.7, kilograms: 6.9),
            (height: 20, weight: 1000, meters: 2.0, kilograms: 100.0),
            (height: 1, weight: 1, meters: 0.1, kilograms: 0.1),
        ])
    func convertsHeightAndWeight(height: Int, weight: Int, meters: Double, kilograms: Double)
        async throws
    {
        let entry = try await fetchDetail { _ in Self.detailDTO(height: height, weight: weight) }

        #expect(entry.heightInMeters == meters)
        #expect(entry.weightInKilograms == kilograms)
    }

    @Test("タイプはスロットの順のまま enum に変わる") func convertsTypesInOrder() async throws {
        let entry = try await fetchDetail { _ in
            Self.detailDTO(types: ["fairy", "steel"])
        }

        #expect(entry.types == [.fairy, .steel])
    }

    @Test("知らないタイプの識別子はそのタイプだけ落とす（取得は失敗にしない）")
    func dropsUnknownTypesOnly() async throws {
        let entry = try await fetchDetail { _ in
            Self.detailDTO(types: ["stellar", "fire", "shadow"])
        }

        #expect(entry.types == [.fire])
    }

    @Test("知らない種族値の識別子はその 1 つだけ落とす（取得は失敗にしない）")
    func dropsUnknownStatsOnly() async throws {
        let entry = try await fetchDetail { _ in
            Self.detailDTO(stats: [
                .init(name: "hp", baseValue: 10),
                .init(name: "accuracy", baseValue: 99),
                .init(name: "special-defense", baseValue: 30),
            ])
        }

        #expect(
            entry.stats == [
                PokemonStat(kind: .hp, value: 10),
                PokemonStat(kind: .specialDefense, value: 30),
            ])
    }

    @Test("アートワークが無ければ nil のまま") func keepsMissingArtwork() async throws {
        let entry = try await fetchDetail { _ in Self.detailDTO(artworkURL: nil) }

        #expect(entry.artworkURL == nil)
    }

    @Test("species は pokemon の番号ではなく、pokemon が返した speciesID で取る")
    func fetchesSpeciesWithSpeciesID() async throws {
        let recorder = Recorder()

        let entry = try await fetchDetail(
            id: 10056,
            pokemon: { _ in Self.detailDTO(id: 10056, speciesID: 354) },
            species: { speciesID in
                await recorder.record(speciesID: speciesID)
                return Self.speciesDTO
            })

        #expect(entry.id == 10056)
        #expect(await recorder.requestedSpeciesIDs == [354])
    }

    @Test("pokemon には渡された番号をそのまま渡す")
    func passesIDToPokemonEndpoint() async throws {
        let recorder = Recorder()

        _ = try await fetchDetail(
            id: 25,
            pokemon: { id in
                await recorder.record(speciesID: id)
                return Self.detailDTO(id: id, speciesID: id)
            })

        #expect(await recorder.requestedSpeciesIDs == [25])
    }

    @Test(
        "PokeAPIError は LoadError に移る",
        arguments: [
            (PokeAPIError.offline, LoadError.offline),
            (PokeAPIError.unavailable, LoadError.unavailable),
        ])
    func mapsPokeAPIErrorWhenPokemonFails(error: PokeAPIError, expected: LoadError) async {
        await #expect(throws: expected) {
            try await fetchDetail { _ in throw error }
        }
    }

    @Test(
        "species だけが失敗しても、全体が失敗になる",
        arguments: [
            (PokeAPIError.offline, LoadError.offline),
            (PokeAPIError.unavailable, LoadError.unavailable),
        ])
    func speciesFailureFailsWhole(error: PokeAPIError, expected: LoadError) async {
        await #expect(throws: expected) {
            try await fetchDetail(
                pokemon: { _ in Self.detailDTO() },
                species: { _ in throw error })
        }
    }

    @Test("キャンセルは変換せずそのまま投げる")
    func rethrowsCancellation() async {
        await #expect(throws: CancellationError.self) {
            try await fetchDetail { _ in throw CancellationError() }
        }
        await #expect(throws: CancellationError.self) {
            try await fetchDetail(
                pokemon: { _ in Self.detailDTO() },
                species: { _ in throw CancellationError() })
        }
    }

    @Test("PokeAPIError 以外の未知のエラーは unavailable にする")
    func unknownErrorBecomesUnavailable() async {
        struct Unknown: Error {}

        await #expect(throws: LoadError.unavailable) {
            try await fetchDetail { _ in throw Unknown() }
        }
    }
}
