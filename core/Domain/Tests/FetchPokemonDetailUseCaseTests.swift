import Dependencies
import Foundation
import Model
import Repository
import Testing

@testable import Domain

struct FetchPokemonDetailUseCaseTests {
    private static func entry(
        identifier: String = "mr-mime", names: [LocalizedName] = [],
        genera: [LocalizedName] = []
    ) -> PokemonDetailEntry {
        PokemonDetailEntry(
            id: 122, identifier: identifier, names: names, genera: genera,
            types: [.psychic, .fairy],
            stats: [
                PokemonStat(kind: .hp, value: 40),
                PokemonStat(kind: .speed, value: 90),
            ],
            heightInMeters: 1.3, weightInKilograms: 54.5,
            artworkURL: URL(string: "https://example.com/artwork/122.png"))
    }

    private static let allNames = [
        LocalizedName(languageCode: .en, name: "Mr. Mime"),
        LocalizedName(languageCode: .jaHrkt, name: "バリヤード"),
    ]
    private static let allGenera = [
        LocalizedName(languageCode: .en, name: "Barrier Pokémon"),
        LocalizedName(languageCode: .jaHrkt, name: "バリアポケモン"),
    ]

    private func execute(
        id: Int = 122, localization: String? = "en",
        repository: @escaping @Sendable (_ id: Int) async throws -> PokemonDetailEntry
    ) async throws -> PokemonDetail {
        try await withDependencies {
            $0.pokemonRepository.fetchDetail = repository
            $0.preferredLocalization = localization
        } operation: {
            try await FetchPokemonDetailUseCase.liveValue.execute(id)
        }
    }

    private actor Recorder {
        private(set) var ids: [Int] = []
        func record(_ id: Int) { ids.append(id) }
    }

    @Test("Repository には渡された番号をそのまま渡す")
    func passesID() async throws {
        let recorder = Recorder()

        _ = try await execute(id: 122) { id in
            await recorder.record(id)
            return Self.entry()
        }

        #expect(await recorder.ids == [122])
    }

    @Test("番号・タイプ・種族値・高さ・重さ・アートワークはそのまま画面用のモデルに移る")
    func carriesOverValues() async throws {
        let detail = try await execute { _ in
            Self.entry(names: Self.allNames, genera: Self.allGenera)
        }

        #expect(detail.id == 122)
        #expect(detail.types == [.psychic, .fairy])
        #expect(
            detail.stats == [
                PokemonStat(kind: .hp, value: 40),
                PokemonStat(kind: .speed, value: 90),
            ])
        #expect(detail.heightInMeters == 1.3)
        #expect(detail.weightInKilograms == 54.5)
        #expect(detail.artworkURL == URL(string: "https://example.com/artwork/122.png"))
    }

    struct LanguageCase: Sendable {
        let localization: String?
        let names: [LocalizedName]
        let genera: [LocalizedName]
        let expectedName: String
        let expectedGenus: String?
    }

    static let languageCases: [LanguageCase] = [
        // ja は ja-hrkt
        LanguageCase(
            localization: "ja", names: allNames, genera: allGenera,
            expectedName: "バリヤード", expectedGenus: "バリアポケモン"),
        // en は en
        LanguageCase(
            localization: "en", names: allNames, genera: allGenera,
            expectedName: "Mr. Mime", expectedGenus: "Barrier Pokémon"),
        // ja 以外の言語は en
        LanguageCase(
            localization: "fr", names: allNames, genera: allGenera,
            expectedName: "Mr. Mime", expectedGenus: "Barrier Pokémon"),
        // 言語が読めないときは en
        LanguageCase(
            localization: nil, names: allNames, genera: allGenera,
            expectedName: "Mr. Mime", expectedGenus: "Barrier Pokémon"),
        // ja-hrkt が無ければ en
        LanguageCase(
            localization: "ja", names: [allNames[0]], genera: [allGenera[0]],
            expectedName: "Mr. Mime", expectedGenus: "Barrier Pokémon"),
        // en も無ければ、名前は識別子の capitalized、分類は無し
        LanguageCase(
            localization: "ja",
            names: [LocalizedName(languageCode: LanguageCode(rawValue: "ko"), name: "마임맨")],
            genera: [LocalizedName(languageCode: LanguageCode(rawValue: "ko"), name: "배리어포켓몬")],
            expectedName: "Mr-Mime", expectedGenus: nil),
        // 名前も分類も空
        LanguageCase(
            localization: "en", names: [], genera: [],
            expectedName: "Mr-Mime", expectedGenus: nil),
        // 名前だけ ja-hrkt があり、分類は en だけのとき（言語ごとに別々に選ぶ）
        LanguageCase(
            localization: "ja", names: allNames, genera: [allGenera[0]],
            expectedName: "バリヤード", expectedGenus: "Barrier Pokémon"),
    ]

    @Test("名前と分類を、アプリの言語の規則で 1 つずつ選ぶ", arguments: languageCases)
    func choosesNameAndGenus(_ testCase: LanguageCase) async throws {
        let detail = try await execute(localization: testCase.localization) { _ in
            Self.entry(names: testCase.names, genera: testCase.genera)
        }

        #expect(detail.name == testCase.expectedName)
        #expect(detail.genus == testCase.expectedGenus)
    }

    @Test("LoadError はそのまま投げる", arguments: [LoadError.offline, LoadError.unavailable])
    func rethrowsLoadError(error: LoadError) async {
        await #expect(throws: error) {
            try await execute { _ in throw error }
        }
    }

    @Test("キャンセルはそのまま投げる") func rethrowsCancellation() async {
        await #expect(throws: CancellationError.self) {
            try await execute { _ in throw CancellationError() }
        }
    }
}
