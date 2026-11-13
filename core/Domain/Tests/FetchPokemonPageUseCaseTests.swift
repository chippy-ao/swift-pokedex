import Dependencies
import Foundation
import Model
import Repository
import Testing

@testable import Domain

struct FetchPokemonPageUseCaseTests {
    private static func entry(id: Int, names: [LocalizedName] = []) -> PokemonListEntry {
        PokemonListEntry(
            id: id, identifier: "pokemon-\(id)", names: names,
            spriteURL: URL(string: "https://example.com/sprites/\(id).png")!)
    }

    private static func page(ids: [Int], hasNext: Bool) -> PokemonListPage {
        PokemonListPage(items: ids.map { entry(id: $0) }, hasNext: hasNext)
    }

    private static let mrMimeNames = [
        LocalizedName(languageCode: .en, name: "Mr. Mime"),
        LocalizedName(languageCode: .jaHrkt, name: "バリヤード"),
    ]

    private func execute(
        offset: Int = 0,
        localization: String? = "en",
        repository:
            @escaping @Sendable (_ limit: Int, _ offset: Int) async throws ->
            PokemonListPage
    ) async throws -> PokemonPage {
        try await withDependencies {
            $0.pokemonRepository.fetchList = repository
            $0.preferredLocalization = localization
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

    private func displayedName(
        localization: String?, names: [LocalizedName]
    ) async throws -> String {
        let result = try await execute(localization: localization) { _, _ in
            PokemonListPage(items: [Self.entry(id: 122, names: names)], hasNext: false)
        }
        return try #require(result.items.first).name
    }

    @Test("アプリの言語が ja なら ja-hrkt の名前を出す")
    func japaneseUsesKana() async throws {
        let name = try await displayedName(localization: "ja", names: Self.mrMimeNames)
        #expect(name == "バリヤード")
    }

    @Test("アプリの言語が en なら英語の名前を出す")
    func englishUsesEnglish() async throws {
        let name = try await displayedName(localization: "en", names: Self.mrMimeNames)
        #expect(name == "Mr. Mime")
    }

    @Test("ja と en 以外の言語や言語が分からないときは英語の名前を出す", arguments: ["fr", nil])
    func otherLanguageUsesEnglish(localization: String?) async throws {
        let name = try await displayedName(localization: localization, names: Self.mrMimeNames)
        #expect(name == "Mr. Mime")
    }

    @Test("ja で ja-hrkt の名前が無ければ英語の名前にフォールバックする")
    func missingJapaneseFallsBackToEnglish() async throws {
        let name = try await displayedName(
            localization: "ja", names: [LocalizedName(languageCode: .en, name: "Mr. Mime")])
        #expect(name == "Mr. Mime")
    }

    @Test("名前が 1 つも無ければ識別子の頭を大文字にしたものを出す", arguments: ["ja", "en"])
    func noNamesFallsBackToIdentifier(localization: String) async throws {
        let name = try await displayedName(localization: localization, names: [])
        #expect(name == "Pokemon-122")
    }
}
