import Dependencies
import DependenciesMacros
import Foundation
import Model
import NetworkClient

@DependencyClient
package struct PokemonRepository: Sendable {
    package var fetchList: @Sendable (_ limit: Int, _ offset: Int) async throws -> PokemonListPage
    /// 詳細 1 件ぶん。pokemon と species を取ってくっつける。
    package var fetchDetail: @Sendable (_ id: Int) async throws -> PokemonDetailEntry
}

extension PokemonRepository: TestDependencyKey {
    package static let testValue = PokemonRepository()

    package static let previewValue = PokemonRepository(
        fetchList: { _, _ in
            PokemonListPage(
                items: [
                    PokemonListEntry(
                        id: 1, identifier: "bulbasaur",
                        names: [
                            LocalizedName(languageCode: .en, name: "Bulbasaur"),
                            LocalizedName(languageCode: .jaHrkt, name: "フシギダネ"),
                        ],
                        spriteURL: URL(
                            string:
                                "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png"
                        )!)
                ],
                hasNext: false)
        },
        fetchDetail: { id in
            PokemonDetailEntry(
                id: id, identifier: "bulbasaur",
                names: [
                    LocalizedName(languageCode: .en, name: "Bulbasaur"),
                    LocalizedName(languageCode: .jaHrkt, name: "フシギダネ"),
                ],
                genera: [
                    LocalizedName(languageCode: .en, name: "Seed Pokémon"),
                    LocalizedName(languageCode: .jaHrkt, name: "たねポケモン"),
                ],
                types: [.grass, .poison],
                stats: [
                    PokemonStat(kind: .hp, value: 45), PokemonStat(kind: .attack, value: 49),
                    PokemonStat(kind: .defense, value: 49),
                    PokemonStat(kind: .specialAttack, value: 65),
                    PokemonStat(kind: .specialDefense, value: 65),
                    PokemonStat(kind: .speed, value: 45),
                ],
                heightInMeters: 0.7, weightInKilograms: 6.9,
                artworkURL: URL(
                    string:
                        "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/"
                        + "official-artwork/1.png"
                ))
        }
    )
}

extension PokemonRepository: DependencyKey {
    package static let liveValue = PokemonRepository(
        fetchList: { limit, offset in
            @Dependency(\.pokeAPIClient) var client
            do {
                // @Dependency のラッパーを async let に渡すとデータ競合の警告になるので、
                // Sendable なクロージャだけを取り出して使う
                let fetchPokemonList = client.fetchPokemonList
                let fetchSpeciesNames = client.fetchAllPokemonSpeciesNames
                async let list = fetchPokemonList(limit, offset)
                async let namesByID = fetchSpeciesNames()
                let (dto, names) = try await (list, namesByID)
                let items = dto.items.map { item in
                    PokemonListEntry(
                        id: item.id, identifier: item.name,
                        // 表に無い ID は名前が空（どの名前を出すかは UseCase が決める）
                        names: (names[item.id] ?? []).map {
                            LocalizedName(
                                languageCode: LanguageCode(rawValue: $0.languageCode), name: $0.name
                            )
                        },
                        spriteURL: item.spriteURL)
                }
                return PokemonListPage(items: items, hasNext: dto.hasNext)
            } catch {
                throw loadError(from: error)
            }
        },
        fetchDetail: { id in
            @Dependency(\.pokeAPIClient) var client
            do {
                // species の番号は pokemon の返事に入っている（フォーム違いでは pokemon の番号と
                // 違う）ので、同時には取れない。pokemon を取ってから species を取る。
                let pokemon = try await client.fetchPokemonDetail(id)
                let species = try await client.fetchPokemonSpecies(pokemon.speciesID)
                // 知らない識別子はその 1 つだけ落とす（compactMap）。取得の失敗にはしない。
                return PokemonDetailEntry(
                    id: pokemon.id, identifier: pokemon.name,
                    names: species.names.map(localizedName),
                    genera: species.genera.map(localizedName),
                    types: pokemon.types.compactMap { PokemonType(rawValue: $0) },
                    stats: pokemon.stats.compactMap { stat in
                        PokemonStatKind(rawValue: stat.name).map {
                            PokemonStat(kind: $0, value: stat.baseValue)
                        }
                    },
                    heightInMeters: Double(pokemon.height) / 10,
                    weightInKilograms: Double(pokemon.weight) / 10,
                    artworkURL: pokemon.artworkURL)
            } catch {
                throw loadError(from: error)
            }
        }
    )
}

private func localizedName(from dto: LocalizedNameDTO) -> LocalizedName {
    LocalizedName(languageCode: LanguageCode(rawValue: dto.languageCode), name: dto.name)
}

/// NetworkClient のエラーを画面に見せる `LoadError` に変える。
/// キャンセルは失敗ではないので変換せずそのまま投げ直す。
private func loadError(from error: any Error) -> any Error {
    switch error {
    case is CancellationError, is LoadError:
        return error
    case PokeAPIError.offline:
        return LoadError.offline
    default:
        return LoadError.unavailable
    }
}

extension DependencyValues {
    package var pokemonRepository: PokemonRepository {
        get { self[PokemonRepository.self] }
        set { self[PokemonRepository.self] = newValue }
    }
}
