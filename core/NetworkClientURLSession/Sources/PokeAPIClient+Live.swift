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
                try await get(
                    PokemonListDTO.self,
                    path: "/api/v2/pokemon?limit=\(limit)&offset=\(offset)",
                    session: session
                )
            }
        )
    }
}

/// 共通の GET とデコード。URLSession は 2xx 以外でも投げないので、ここで `PokeAPIError` に変える。
/// `URLError` と `DecodingError` は包まずそのまま投げる。
private func get<Response: Decodable>(
    _ type: Response.Type,
    path: String,
    session: URLSession
) async throws -> Response {
    let request = HTTPRequest(method: .get, scheme: "https", authority: "pokeapi.co", path: path)
    let (data, response) = try await session.data(for: request)
    guard (200..<300).contains(response.status.code) else {
        throw PokeAPIError.httpStatus(response.status.code)
    }
    return try pokeAPIDecoder.decode(Response.self, from: data)
}

/// デコーダーは 1 か所で作って使い回す。
/// snake_case のキーは自動で camelCase になる。ハイフン入りのキーだけ CodingKeys に書く。
private let pokeAPIDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
}()
