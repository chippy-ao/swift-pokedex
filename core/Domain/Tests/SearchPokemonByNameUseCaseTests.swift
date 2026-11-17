import Dependencies
import Foundation
import Model
import Repository
import Testing

@testable import Domain

struct SearchPokemonByNameUseCaseTests {
    private static func entry(id: Int, names: [LocalizedName]) -> PokemonNameEntry {
        PokemonNameEntry(
            id: id, names: names, spriteURL: URL(string: "https://example.com/sprites/\(id).png")!)
    }

    private static let pikachuNames = [
        LocalizedName(languageCode: .en, name: "Pikachu"),
        LocalizedName(languageCode: .jaHrkt, name: "ピカチュウ"),
    ]
    private static let raichuNames = [
        LocalizedName(languageCode: .en, name: "Raichu"),
        LocalizedName(languageCode: .jaHrkt, name: "ライチュウ"),
    ]

    private func search(
        _ query: String,
        localization: String? = "en",
        entries: [PokemonNameEntry]
    ) async throws -> [PokemonSummary] {
        try await withDependencies {
            $0.pokemonRepository.fetchAllNames = { entries }
            $0.preferredLocalization = localization
        } operation: {
            try await SearchPokemonByNameUseCase.liveValue.execute(query)
        }
    }

    private static let pikachuAndRaichu = [
        entry(id: 25, names: pikachuNames), entry(id: 26, names: raichuNames),
    ]

    @Test("query に当たる名前だけを、番号と画像の URL つきで返す")
    func filtersByQuery() async throws {
        let result = try await search("pika", entries: Self.pikachuAndRaichu)

        #expect(
            result == [
                PokemonSummary(
                    id: 25, name: "Pikachu",
                    spriteURL: URL(string: "https://example.com/sprites/25.png")!)
            ])
    }

    @Test("空文字は全件を返す")
    func emptyQueryReturnsAll() async throws {
        let result = try await search("", entries: Self.pikachuAndRaichu)

        #expect(result.map(\.id) == [25, 26])
    }

    @Test("探す対象はアプリの言語の名前だけ。ja ならカナで当たり、英語では当たらない")
    func searchesOnlyPreferredLanguage() async throws {
        let byKana = try await search(
            "ぴか", localization: "ja", entries: Self.pikachuAndRaichu)
        let byEnglish = try await search(
            "pika", localization: "ja", entries: Self.pikachuAndRaichu)
        let englishByKana = try await search(
            "ぴか", localization: "en", entries: Self.pikachuAndRaichu)

        #expect(byKana.map(\.name) == ["ピカチュウ"])
        #expect(byEnglish.isEmpty)
        #expect(englishByKana.isEmpty)
    }

    @Test("ja の名前が無い番号は、英語の名前で探して英語の名前で返す")
    func fallsBackToEnglish() async throws {
        let result = try await search(
            "pika", localization: "ja",
            entries: [
                Self.entry(id: 25, names: [LocalizedName(languageCode: .en, name: "Pikachu")])
            ]
        )

        #expect(result.map(\.name) == ["Pikachu"])
    }

    @Test("ID が 10000 を超えるもの（フォーム違い）は、当たっても含めない。10000 ちょうどは残す")
    func dropsFormsAbove10000() async throws {
        let result = try await search(
            "",
            entries: [1, 1025, 10000, 10001, 10033].map {
                Self.entry(id: $0, names: Self.pikachuNames)
            }
        )

        #expect(result.map(\.id) == [1, 1025, 10000])
    }

    @Test("使える名前が 1 つも無い番号は含めない（空の行を出さない）。空文字でも同じ")
    func dropsEntriesWithoutNames() async throws {
        let result = try await search(
            "",
            entries: [Self.entry(id: 1, names: []), Self.entry(id: 25, names: Self.pikachuNames)]
        )

        #expect(result.map(\.id) == [25])
    }

    @Test("LoadError はそのまま投げる", arguments: [LoadError.offline, LoadError.unavailable])
    func rethrowsLoadError(error: LoadError) async {
        await #expect(throws: error) {
            try await withDependencies {
                $0.pokemonRepository.fetchAllNames = { throw error }
            } operation: {
                try await SearchPokemonByNameUseCase.liveValue.execute("pika")
            }
        }
    }
}
