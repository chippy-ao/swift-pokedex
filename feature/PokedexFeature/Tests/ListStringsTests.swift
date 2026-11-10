import Foundation
import Testing

@testable import PokedexFeature

struct ListStringsTests {
    struct Case: Sendable {
        let key: String
        let language: String
        let expected: String
    }

    static let cases: [Case] = [
        Case(key: "listNavigationTitle", language: "en", expected: "Pokédex"),
        Case(key: "listNavigationTitle", language: "ja", expected: "ポケモン図鑑"),
        Case(key: "listRetryButton", language: "en", expected: "Retry"),
        Case(key: "listRetryButton", language: "ja", expected: "再試行"),
        Case(
            key: "listErrorOffline", language: "en",
            expected: "You're offline. Check your connection."),
        Case(
            key: "listErrorOffline", language: "ja",
            expected: "ネットワークに接続できません。接続を確認してください。"),
        Case(
            key: "listErrorUnavailable", language: "en",
            expected: "Couldn't load. Please try again later."),
        Case(
            key: "listErrorUnavailable", language: "ja",
            expected: "読み込めませんでした。時間をおいて再試行してください。"),
    ]

    @Test("カタログの訳が言語ごとに引ける", arguments: cases)
    func catalogResolvesPerLanguage(_ testCase: Case) {
        // PokedexFeature の bundle は生成された記号から借りる（モジュールの bundle は外から触れない）
        var resource = LocalizedStringResource(
            String.LocalizationValue(testCase.key),
            table: "Localizable",
            bundle: LocalizedStringResource.listNavigationTitle.bundle)
        resource.locale = Locale(identifier: testCase.language)

        #expect(String(localized: resource) == testCase.expected)
    }
}
