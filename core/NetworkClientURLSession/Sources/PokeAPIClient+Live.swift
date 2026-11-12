import Dependencies
import Foundation
import HTTPTypes
import HTTPTypesFoundation
import NetworkClient

extension PokeAPIClient: DependencyKey {
    public static let liveValue = PokeAPIClient.live(session: .pokeAPI)

    /// テストから URLProtocol のスタブ入りの session を差し込めるようにするファクトリ。
    static func live(session: URLSession) -> PokeAPIClient {
        PokeAPIClient(
            fetchPokemonList: { limit, offset in
                let response = try await get(
                    PokemonListResponse.self,
                    path: "/api/v2/pokemon?limit=\(limit)&offset=\(offset)",
                    session: session
                )
                return try response.toDTO()
            },
            // session は使わない。URLSession の箱だが、PokeAPI のデータを返す本物の実装として
            // 同梱の表から答える。API を叩きすぎないため（ADR-0018）。
            fetchAllPokemonSpeciesNames: {
                try bundledSpeciesNames.get()
            }
        )
    }
}

/// 同梱の `pokemon-species-names.json`。読むのは 1 回だけ（グローバルの定数は最初に使われた
/// ときに 1 度だけ作られる）。読めなければ以後も同じ失敗を返す（同梱物の不具合なので再試行しても直らない）。
private let bundledSpeciesNames: Result<[Int: [LocalizedNameDTO]], PokeAPIError> = {
    guard
        let url = Bundle.module.url(forResource: "pokemon-species-names", withExtension: "json"),
        let data = try? Data(contentsOf: url),
        let rows = try? JSONDecoder().decode([BundledSpeciesNames].self, from: data)
    else {
        return .failure(.unavailable)
    }
    // id が重複しても落とさない（手で JSON を直したときにクラッシュさせない）。後ろの行を使う。
    let table = Dictionary(
        rows.map { row in
            (
                row.id,
                row.names.sorted { $0.key < $1.key }
                    .map { LocalizedNameDTO(languageCode: $0.key, name: $0.value) }
            )
        },
        uniquingKeysWith: { _, last in last }
    )
    return .success(table)
}()

/// `pokemon-species-names.json` の 1 件。形は scripts/generate-pokemon-names.swift が決める。
private struct BundledSpeciesNames: Decodable {
    var id: Int
    var names: [String: String]
}

/// REST の `GET /api/v2/pokemon` のレスポンス。REST の形はこのモジュールの中に閉じ込める。
private struct PokemonListResponse: Decodable {
    struct Entry: Decodable {
        var name: String
        var url: String
    }

    var next: String?
    var results: [Entry]

    func toDTO() throws -> PokemonListDTO {
        let items = try results.map { entry in
            // 1 件でも番号を取り出せなければ、ページ全体を失敗にする
            guard let id = pokemonID(fromURL: entry.url) else {
                throw PokeAPIError.unavailable
            }
            return PokemonListDTO.Entry(id: id, name: entry.name, spriteURL: spriteURL(id: id))
        }
        return PokemonListDTO(items: items, hasNext: next != nil)
    }
}

/// `https://pokeapi.co/api/v2/pokemon/25/` の末尾の `25` を取り出す。
private func pokemonID(fromURL url: String) -> Int? {
    url.split(separator: "/").last.flatMap { Int($0) }
}

/// 小さいドット絵の URL。REST のレスポンスには入っていないので、番号から作る。
private func spriteURL(id: Int) -> URL {
    URL(
        string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png"
    )!
}

/// 共通の GET とデコード。URLSession は 2xx 以外でも投げないので、ここで失敗にする。
/// 通信方式のエラーは `PokeAPIError` に仕分ける。キャンセルは `URLError(.cancelled)` も含めて `CancellationError` にそろえて投げる。
private func get<Response: Decodable>(
    _ type: Response.Type,
    path: String,
    session: URLSession
) async throws -> Response {
    let request = HTTPRequest(method: .get, scheme: "https", authority: "pokeapi.co", path: path)
    do {
        let (data, response) = try await session.data(for: request)
        guard response.status.kind == .successful else {
            throw PokeAPIError.unavailable
        }
        return try pokeAPIDecoder.decode(Response.self, from: data)
    } catch {
        throw pokeAPIError(from: error)
    }
}

private func pokeAPIError(from error: any Error) -> any Error {
    if error is CancellationError || error is PokeAPIError {
        return error
    }
    if let urlError = error as? URLError {
        switch urlError.code {
        case .cancelled:
            // 上の層が Foundation を知らずに、CancellationError 1 種類だけで
            // キャンセルを見分けられるようにそろえる。
            return CancellationError()
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            return PokeAPIError.offline
        default:
            return PokeAPIError.unavailable
        }
    }
    // DecodingError など
    return PokeAPIError.unavailable
}

/// デコーダーは 1 か所で作って使い回す。
/// snake_case のキーは自動で camelCase になる。ハイフン入りのキーだけ CodingKeys に書く。
private let pokeAPIDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
}()
