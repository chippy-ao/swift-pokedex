import Dependencies
import Foundation
import Model
import Repository
import Testing

@testable import Domain

struct FetchPokemonPageUseCaseTests {
    private static func summary(id: Int) -> PokemonSummary {
        PokemonSummary(
            id: id, name: "pokemon-\(id)",
            spriteURL: URL(string: "https://example.com/sprites/\(id).png")!)
    }

    private static func page(ids: [Int], hasNext: Bool) -> PokemonPage {
        PokemonPage(items: ids.map(summary(id:)), hasNext: hasNext)
    }

    private func execute(
        offset: Int = 0,
        repository: @escaping @Sendable (_ limit: Int, _ offset: Int) async throws -> PokemonPage
    ) async throws -> PokemonPage {
        try await withDependencies {
            $0.pokemonRepository.fetchList = repository
        } operation: {
            try await FetchPokemonPageUseCase.liveValue.execute(offset)
        }
    }

    private actor Recorder {
        private(set) var calls: [[Int]] = []
        func record(limit: Int, offset: Int) { calls.append([limit, offset]) }
    }

    @Test("Repository には limit 20 と、渡された offset をそのまま渡す")
    func passesLimitAndOffset() async throws {
        let recorder = Recorder()

        _ = try await execute(offset: 40) { limit, offset in
            await recorder.record(limit: limit, offset: offset)
            return Self.page(ids: [41], hasNext: true)
        }

        #expect(await recorder.calls == [[20, 40]])
    }

    @Test("ID が 10000 を超えるものを捨て、hasNext を false にする")
    func dropsFormsAndStops() async throws {
        let result = try await execute { _, _ in
            Self.page(ids: [1024, 1025, 10001, 10002], hasNext: true)
        }

        #expect(result.items.map(\.id) == [1024, 1025])
        #expect(result.hasNext == false)
    }

    @Test("ID が 10000 ちょうどのものは残す。超えるものが無ければ Repository の hasNext を使う", arguments: [true, false])
    func keepsRepositoryHasNext(hasNext: Bool) async throws {
        let result = try await execute { _, _ in
            Self.page(ids: [9999, 10000], hasNext: hasNext)
        }

        #expect(result.items.map(\.id) == [9999, 10000])
        #expect(result.hasNext == hasNext)
    }

    @Test("LoadError はそのまま投げる", arguments: [LoadError.offline, LoadError.unavailable])
    func rethrowsLoadError(error: LoadError) async {
        await #expect(throws: error) {
            try await execute { _, _ in throw error }
        }
    }

    @Test("CancellationError はそのまま投げる") func rethrowsCancellationError() async {
        await #expect(throws: CancellationError.self) {
            try await execute { _, _ in throw CancellationError() }
        }
    }
}
