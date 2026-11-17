import Dependencies
import Foundation
import Model
import Repository
import Testing

@testable import Domain

/// 絞り込み自体（部分一致、かな・大文字・全角の区別など）は NetworkClientURLSession のテストで確かめる。
/// ここでは、UseCase が決めること（言語の渡し方、ID の除外、名前の選び方）を確かめる。
struct SearchPokemonByNameUseCaseTests {
    private static func entry(id: Int, names: [LocalizedName]) -> PokemonNameEntry {
        PokemonNameEntry(
            id: id, names: names, spriteURL: URL(string: "https://example.com/sprites/\(id).png")!)
    }

    private static let pikachuNames = [
        LocalizedName(languageCode: .en, name: "Pikachu"),
        LocalizedName(languageCode: .jaHrkt, name: "ピカチュウ"),
    ]

    private actor Recorder {
        /// `[query, 言語コード]` の組。
        private(set) var calls: [[String]] = []
        func record(query: String, language: LanguageCode) {
            calls.append([query, language.rawValue])
        }
    }

    private func search(
        _ query: String = "pika",
        localization: String? = "en",
        entries: [PokemonNameEntry],
        recorder: Recorder = Recorder()
    ) async throws -> [PokemonSummary] {
        try await withDependencies {
            $0.pokemonRepository.searchNames = { query, language in
                await recorder.record(query: query, language: language)
                return entries
            }
            $0.preferredLocalization = localization
        } operation: {
            try await SearchPokemonByNameUseCase.liveValue.execute(query)
        }
    }

    private static let languageCases: [(String?, LanguageCode)] = [
        ("ja", .jaHrkt), ("en", .en), ("fr", .en), (nil, .en),
    ]

    @Test("アプリの言語に当たる言語コードで検索する。ja は ja-hrkt、それ以外は en", arguments: languageCases)
    func passesLanguageOfApp(localization: String?, expected: LanguageCode) async throws {
        let recorder = Recorder()

        _ = try await search("ぴか", localization: localization, entries: [], recorder: recorder)

        #expect(await recorder.calls == [["ぴか", expected.rawValue]])
    }

    @Test("結果は、設定言語の名前を選び、番号と画像の URL をそのまま持つ")
    func choosesNameOfPreferredLanguage() async throws {
        let entries = [Self.entry(id: 25, names: Self.pikachuNames)]

        let japanese = try await search(localization: "ja", entries: entries)
        let english = try await search(localization: "en", entries: entries)

        #expect(
            japanese == [
                PokemonSummary(
                    id: 25, name: "ピカチュウ",
                    spriteURL: URL(string: "https://example.com/sprites/25.png")!)
            ])
        #expect(english.map(\.name) == ["Pikachu"])
    }

    @Test("ja の名前が無ければ英語の名前にフォールバックする")
    func fallsBackToEnglish() async throws {
        let result = try await search(
            localization: "ja",
            entries: [
                Self.entry(id: 25, names: [LocalizedName(languageCode: .en, name: "Pikachu")])
            ]
        )

        #expect(result.map(\.name) == ["Pikachu"])
    }

    @Test("ID が 10000 を超えるもの（フォーム違い）は含めない。10000 ちょうどは残す")
    func dropsFormsAbove10000() async throws {
        let result = try await search(
            entries: [1, 1025, 10000, 10001, 10033].map {
                Self.entry(id: $0, names: Self.pikachuNames)
            }
        )

        #expect(result.map(\.id) == [1, 1025, 10000])
    }

    @Test("使える名前が 1 つも無い番号は含めない（空の行を出さない）")
    func dropsEntriesWithoutNames() async throws {
        let result = try await search(
            entries: [Self.entry(id: 1, names: []), Self.entry(id: 25, names: Self.pikachuNames)]
        )

        #expect(result.map(\.id) == [25])
    }

    @Test("Repository の順番をそのまま保つ")
    func keepsOrder() async throws {
        let result = try await search(
            entries: [26, 25, 27].map { Self.entry(id: $0, names: Self.pikachuNames) })

        #expect(result.map(\.id) == [26, 25, 27])
    }

    @Test("LoadError はそのまま投げる", arguments: [LoadError.offline, LoadError.unavailable])
    func rethrowsLoadError(error: LoadError) async {
        await #expect(throws: error) {
            try await withDependencies {
                $0.pokemonRepository.searchNames = { _, _ in throw error }
            } operation: {
                try await SearchPokemonByNameUseCase.liveValue.execute("pika")
            }
        }
    }
}
