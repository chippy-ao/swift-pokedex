import Foundation
import NetworkClient
import Synchronization
import Testing

@testable import NetworkClientURLSession

// JSON の fixture は PokeAPI の返事をそのまま写すので、行が長くなる。
// swiftlint:disable line_length
/// PokeAPI の `GET /api/v2/pokemon/1` の形に合わせた JSON（使わないキーは省いている）。
private let bulbasaurJSON = """
    {
      "id": 1,
      "name": "bulbasaur",
      "height": 7,
      "weight": 69,
      "abilities": [
        { "ability": { "name": "overgrow", "url": "https://pokeapi.co/api/v2/ability/65/" },
          "is_hidden": false, "slot": 1 }
      ],
      "species": { "name": "bulbasaur", "url": "https://pokeapi.co/api/v2/pokemon-species/1/" },
      "sprites": {
        "front_default": "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png",
        "other": {
          "dream_world": { "front_default": "https://example.com/dream/1.svg" },
          "official-artwork": {
            "front_default": "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/1.png",
            "front_shiny": "https://example.com/shiny/1.png"
          }
        }
      },
      "stats": [
        { "base_stat": 45, "effort": 0, "stat": { "name": "hp", "url": "https://pokeapi.co/api/v2/stat/1/" } },
        { "base_stat": 49, "effort": 0, "stat": { "name": "attack", "url": "https://pokeapi.co/api/v2/stat/2/" } },
        { "base_stat": 49, "effort": 0, "stat": { "name": "defense", "url": "https://pokeapi.co/api/v2/stat/3/" } },
        { "base_stat": 65, "effort": 1, "stat": { "name": "special-attack", "url": "https://pokeapi.co/api/v2/stat/4/" } },
        { "base_stat": 65, "effort": 0, "stat": { "name": "special-defense", "url": "https://pokeapi.co/api/v2/stat/5/" } },
        { "base_stat": 45, "effort": 0, "stat": { "name": "speed", "url": "https://pokeapi.co/api/v2/stat/6/" } }
      ],
      "types": [
        { "slot": 1, "type": { "name": "grass", "url": "https://pokeapi.co/api/v2/type/12/" } },
        { "slot": 2, "type": { "name": "poison", "url": "https://pokeapi.co/api/v2/type/4/" } }
      ]
    }
    """

/// フォーム違い（`GET /api/v2/pokemon/10056`、banette-mega）。pokemon の番号と species の番号が違う。
/// アートワークが無いときは `official-artwork.front_default` が null になる。
private let formJSON = """
    {
      "id": 10056,
      "name": "banette-mega",
      "height": 12,
      "weight": 130,
      "species": { "name": "banette", "url": "https://pokeapi.co/api/v2/pokemon-species/354/" },
      "sprites": {
        "front_default": null,
        "other": { "official-artwork": { "front_default": null, "front_shiny": null } }
      },
      "stats": [
        { "base_stat": 64, "effort": 0, "stat": { "name": "hp", "url": "https://pokeapi.co/api/v2/stat/1/" } }
      ],
      "types": [
        { "slot": 1, "type": { "name": "ghost", "url": "https://pokeapi.co/api/v2/type/8/" } }
      ]
    }
    """

/// PokeAPI の `GET /api/v2/pokemon-species/1` の形に合わせた JSON（使わないキーは省いている）。
private let bulbasaurSpeciesJSON = """
    {
      "id": 1,
      "name": "bulbasaur",
      "is_baby": false,
      "names": [
        { "language": { "name": "ja-hrkt", "url": "https://pokeapi.co/api/v2/language/1/" }, "name": "フシギダネ" },
        { "language": { "name": "ko", "url": "https://pokeapi.co/api/v2/language/3/" }, "name": "이상해씨" },
        { "language": { "name": "en", "url": "https://pokeapi.co/api/v2/language/9/" }, "name": "Bulbasaur" }
      ],
      "genera": [
        { "genus": "たねポケモン", "language": { "name": "ja-hrkt", "url": "https://pokeapi.co/api/v2/language/1/" } },
        { "genus": "Seed Pokémon", "language": { "name": "en", "url": "https://pokeapi.co/api/v2/language/9/" } }
      ],
      "evolution_chain": { "url": "https://pokeapi.co/api/v2/evolution-chain/1/" }
    }
    """
// swiftlint:enable line_length

extension NetworkClientURLSessionTests {
    private static let artworkBase =
        "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork"

    @Test("pokemon の JSON から、番号・識別子・species の番号・タイプ・種族値・高さ・重さ・アートワークが作られる")
    func buildsDetailFromPokemonJSON() async throws {
        let client = makeClient { request in
            (Self.response(for: request, status: 200), Data(bulbasaurJSON.utf8))
        }

        let dto = try await client.fetchPokemonDetail(1)

        #expect(
            dto
                == PokemonDetailDTO(
                    id: 1, name: "bulbasaur", speciesID: 1, types: ["grass", "poison"],
                    stats: [
                        .init(name: "hp", baseValue: 45),
                        .init(name: "attack", baseValue: 49),
                        .init(name: "defense", baseValue: 49),
                        .init(name: "special-attack", baseValue: 65),
                        .init(name: "special-defense", baseValue: 65),
                        .init(name: "speed", baseValue: 45),
                    ],
                    height: 7, weight: 69,
                    artworkURL: URL(string: "\(Self.artworkBase)/1.png")))
    }

    @Test("species の番号は species.url の末尾から取る（フォーム違いでは pokemon の番号と違う）")
    func speciesIDComesFromSpeciesURL() async throws {
        let client = makeClient { request in
            (Self.response(for: request, status: 200), Data(formJSON.utf8))
        }

        let dto = try await client.fetchPokemonDetail(10056)

        #expect(dto.id == 10056)
        #expect(dto.speciesID == 354)
    }

    @Test("アートワークが null なら artworkURL は nil") func nullArtworkBecomesNil() async throws {
        let client = makeClient { request in
            (Self.response(for: request, status: 200), Data(formJSON.utf8))
        }

        let dto = try await client.fetchPokemonDetail(10056)

        #expect(dto.artworkURL == nil)
    }

    @Test("知らないタイプの識別子も、DTO では文字列のまま運ぶ") func unknownTypeIdentifierIsKept() async throws {
        let client = makeClient { request in
            let json = bulbasaurJSON.replacingOccurrences(of: "\"grass\"", with: "\"stellar\"")
            return (Self.response(for: request, status: 200), Data(json.utf8))
        }

        let dto = try await client.fetchPokemonDetail(1)

        #expect(dto.types == ["stellar", "poison"])
    }

    @Test("species.url から番号を取り出せなければ unavailable になる")
    func unparsableSpeciesURLMakesDetailUnavailable() async {
        let client = makeClient { request in
            let json = bulbasaurJSON.replacingOccurrences(
                of: "https://pokeapi.co/api/v2/pokemon-species/1/",
                with: "https://pokeapi.co/api/v2/pokemon-species/")
            return (Self.response(for: request, status: 200), Data(json.utf8))
        }

        await #expect(throws: PokeAPIError.unavailable) {
            try await client.fetchPokemonDetail(1)
        }
    }

    @Test("詳細のリクエストは /api/v2/pokemon/{id}、species は /api/v2/pokemon-species/{id}")
    func detailRequestPaths() async throws {
        let paths = Mutex<[String]>([])
        let client = makeClient { request in
            let path = request.url?.path ?? ""
            paths.withLock { $0.append(path) }
            let json = path.contains("species") ? bulbasaurSpeciesJSON : bulbasaurJSON
            return (Self.response(for: request, status: 200), Data(json.utf8))
        }

        _ = try await client.fetchPokemonDetail(1)
        _ = try await client.fetchPokemonSpecies(354)

        #expect(paths.withLock { $0 } == ["/api/v2/pokemon/1", "/api/v2/pokemon-species/354"])
    }

    @Test("species の JSON から、全部の言語の名前と分類が作られる")
    func buildsSpeciesFromJSON() async throws {
        let client = makeClient { request in
            (Self.response(for: request, status: 200), Data(bulbasaurSpeciesJSON.utf8))
        }

        let dto = try await client.fetchPokemonSpecies(1)

        #expect(
            dto
                == PokemonSpeciesDTO(
                    names: [
                        LocalizedNameDTO(languageCode: "ja-hrkt", name: "フシギダネ"),
                        LocalizedNameDTO(languageCode: "ko", name: "이상해씨"),
                        LocalizedNameDTO(languageCode: "en", name: "Bulbasaur"),
                    ],
                    genera: [
                        LocalizedNameDTO(languageCode: "ja-hrkt", name: "たねポケモン"),
                        LocalizedNameDTO(languageCode: "en", name: "Seed Pokémon"),
                    ]))
    }

    @Test("詳細と species の、成功以外のステータスと壊れた JSON は unavailable になる")
    func detailFailuresBecomeUnavailable() async {
        let notFound = makeClient { request in
            (Self.response(for: request, status: 404), Data("{}".utf8))
        }
        await #expect(throws: PokeAPIError.unavailable) {
            try await notFound.fetchPokemonDetail(99999)
        }
        await #expect(throws: PokeAPIError.unavailable) {
            try await notFound.fetchPokemonSpecies(99999)
        }

        let broken = makeClient { request in
            (Self.response(for: request, status: 200), Data("{ \"id\": ".utf8))
        }
        await #expect(throws: PokeAPIError.unavailable) {
            try await broken.fetchPokemonDetail(1)
        }
        await #expect(throws: PokeAPIError.unavailable) {
            try await broken.fetchPokemonSpecies(1)
        }
    }

    @Test("詳細と species のオフラインは offline になる")
    func detailOfflineBecomesOffline() async {
        let client = makeClient { _ in throw URLError(.notConnectedToInternet) }

        await #expect(throws: PokeAPIError.offline) {
            try await client.fetchPokemonDetail(1)
        }
        await #expect(throws: PokeAPIError.offline) {
            try await client.fetchPokemonSpecies(1)
        }
    }
}
