import Testing

@testable import NetworkClientURLSession

struct NameMatchingTests {
    struct Case: Sendable, CustomTestStringConvertible {
        var name: String
        var query: String
        var expected: Bool
        var testDescription: String { "\(name) / \(query) -> \(expected)" }
    }

    @Test(
        "部分一致。大文字小文字、半角全角、ひらがなカタカナを区別しない。空文字は全件に当たる",
        arguments: [
            Case(name: "ピカチュウ", query: "ぴか", expected: true),
            Case(name: "ピカチュウ", query: "ぴかちゅう", expected: true),
            Case(name: "ピカチュウ", query: "ﾋﾟｶ", expected: true),
            Case(name: "ピカチュウ", query: "チュウ", expected: true),
            Case(name: "ピカチュウ", query: "ひか", expected: false),
            Case(name: "Pikachu", query: "PIKA", expected: true),
            Case(name: "Flabébé", query: "flabebe", expected: true),
            Case(name: "Mr. Mime", query: "mr. mime", expected: true),
            Case(name: "ピカチュウ", query: "", expected: true),
            Case(name: "Pikachu", query: "", expected: true),
        ])
    func matches(testCase: Case) {
        #expect(matchesName(testCase.name, query: testCase.query) == testCase.expected)
    }
}
