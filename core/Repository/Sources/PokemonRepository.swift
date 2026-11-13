import Dependencies
import DependenciesMacros
import Foundation
import Model
import NetworkClient

@DependencyClient
public struct PokemonRepository: Sendable {
    public var fetchList: @Sendable (_ limit: Int, _ offset: Int) async throws -> PokemonListPage
    /// 詳細 1 件ぶん。pokemon と species を取ってくっつける。
    public var fetchDetail: @Sendable (_ id: Int) async throws -> PokemonDetailEntry
}

extension PokemonRepository: TestDependencyKey {
    public static let testValue = PokemonRepository()

    public static let previewValue = PokemonRepository(
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
    public static let liveValue = PokemonRepository(
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
        // 仮の中身（テスト先行の段階。実装で置き換える）
        fetchDetail: { _ in throw LoadError.unavailable }
    )
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
    public var pokemonRepository: PokemonRepository {
        get { self[PokemonRepository.self] }
        set { self[PokemonRepository.self] = newValue }
    }
}
