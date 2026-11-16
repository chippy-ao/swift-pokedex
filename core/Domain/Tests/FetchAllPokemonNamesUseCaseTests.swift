import Dependencies
import Foundation
import Model
import Repository
import Testing

@testable import Domain

struct FetchAllPokemonNamesUseCaseTests {
    private static func entry(id: Int, names: [LocalizedName]) -> PokemonNameEntry {
        PokemonNameEntry(
            id: id, names: names, spriteURL: URL(string: "https://example.com/sprites/\(id).png")!)
    }

    private static let pikachuNames = [
        LocalizedName(languageCode: .en, name: "Pikachu"),
        LocalizedName(languageCode: .jaHrkt, name: "ピカチュウ"),
    ]

    private func execute(
        localization: String?,
        entries: [PokemonNameEntry]
    ) async throws -> [PokemonSummary] {
        try await withDependencies {
            $0.pokemonRepository.fetchAllNames = { entries }
            $0.preferredLocalization = localization
        } operation: {
            try await FetchAllPokemonNamesUseCase.liveValue.execute()
        }
    }

    @Test("アプリの言語が ja ならカナの名前、en なら英語の名前を返す（番号と画像の URL はそのまま）")
    func usesPreferredLanguageName() async throws {
        let entries = [Self.entry(id: 25, names: Self.pikachuNames)]

        let japanese = try await execute(localization: "ja", entries: entries)
        let english = try await execute(localization: "en", entries: entries)

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
        let result = try await execute(
            localization: "ja",
            entries: [
                Self.entry(id: 25, names: [LocalizedName(languageCode: .en, name: "Pikachu")])
            ]
        )

        #expect(result.map(\.name) == ["Pikachu"])
    }

    @Test("ID が 10000 を超えるもの（フォーム違い）は含めない。10000 ちょうどは残す")
    func dropsFormsAbove10000() async throws {
        let result = try await execute(
            localization: "en",
            entries: [1, 1025, 10000, 10001, 10033].map {
                Self.entry(id: $0, names: Self.pikachuNames)
            }
        )

        #expect(result.map(\.id) == [1, 1025, 10000])
    }

    @Test("使える名前が 1 つも無い番号は含めない（表に無い番号と同じく、空の行を出さない）")
    func dropsEntriesWithoutNames() async throws {
        let result = try await execute(
            localization: "en",
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
                try await FetchAllPokemonNamesUseCase.liveValue.execute()
            }
        }
    }
}
