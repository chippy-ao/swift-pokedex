import Dependencies
import Foundation
import NetworkClient

extension PokeAPIClient: DependencyKey {
    public static let liveValue = PokeAPIClient.live(session: .pokeAPI)

    /// テストから URLProtocol のスタブ入りの session を差し込めるようにするファクトリ。
    static func live(session: URLSession) -> PokeAPIClient {
        PokeAPIClient(
            fetchPokemonList: { _, _ in
                // 枠のみ。共通の GET とデコードは後続のコミットで実装する
                throw NotImplemented()
            }
        )
    }
}

private struct NotImplemented: Error {}
