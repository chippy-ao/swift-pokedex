import Foundation
import Model
import NetworkClient
import Testing

@testable import NetworkClientURLSession

struct NameSearchTests {
    private static let table: [Int: [LocalizedNameDTO]] = [
        26: [
            LocalizedNameDTO(languageCode: "en", name: "Raichu"),
            LocalizedNameDTO(languageCode: "ja-hrkt", name: "ライチュウ"),
        ],
        25: [
            LocalizedNameDTO(languageCode: "en", name: "Pikachu"),
            LocalizedNameDTO(languageCode: "ja-hrkt", name: "ピカチュウ"),
        ],
        999: [LocalizedNameDTO(languageCode: "en", name: "Pikamystery")],
    ]

    @Test("language の名前に当たったものだけを、番号の小さい順に返す")
    func filtersByLanguageName() {
        let result = searchNames(in: Self.table, query: "ちゅう", language: .jaHrkt)

        #expect(result.map(\.id) == [25, 26])
        #expect(searchNames(in: Self.table, query: "ライ", language: .jaHrkt).map(\.id) == [26])
    }

    @Test("探すのは language の名前だけ。ja で英語の綴りは当たらない")
    func searchesOnlyGivenLanguage() {
        #expect(searchNames(in: Self.table, query: "rai", language: .jaHrkt).isEmpty)
        #expect(searchNames(in: Self.table, query: "ぴか", language: .en).isEmpty)
    }

    @Test("当たった番号の名前は、全部の言語で返す")
    func returnsNamesOfAllLanguages() {
        let result = searchNames(in: Self.table, query: "pika", language: .en)

        #expect(result.first?.id == 25)
        #expect(
            result.first?.names.map(\.languageCode).sorted() == ["en", "ja-hrkt"])
    }

    @Test("language の名前が無い番号は、英語の名前では探さず、結果に入れない（空文字でも）")
    func dropsEntriesWithoutNameInLanguage() {
        #expect(searchNames(in: Self.table, query: "mystery", language: .jaHrkt).isEmpty)
        #expect(searchNames(in: Self.table, query: "", language: .jaHrkt).map(\.id) == [25, 26])
    }

    @Test("空文字は全件を、番号の小さい順に返す")
    func emptyQueryReturnsAllSorted() {
        let result = searchNames(in: Self.table, query: "", language: .en)

        #expect(result.map(\.id) == [25, 26, 999])
    }
}

/// 同梱の本物の表を通す。表が読めること、実際のポケモンで引けることを確かめる。
struct BundledTableSearchTests {
    private func search(_ query: String, _ language: LanguageCode) async throws -> [Int] {
        try await PokeAPIClient.live(session: .shared)
            .searchPokemonNames(query, language).map(\.id)
    }

    @Test("同梱の表を、日本語（かな・カタカナ）と英語（大文字小文字）で引ける")
    func searchesBundledTable() async throws {
        #expect(try await search("ぴかちゅう", .jaHrkt).contains(25))
        #expect(try await search("PIKACHU", .en).contains(25))
        #expect(try await search("flabebe", .en).contains(669))
    }

    @Test("空文字は表の全件に当たる")
    func emptyQueryMatchesWholeTable() async throws {
        let all = try await PokeAPIClient.live(session: .shared).fetchAllPokemonSpeciesNames()
        let ids = try await search("", .en)

        #expect(ids == all.keys.sorted())
    }
}
