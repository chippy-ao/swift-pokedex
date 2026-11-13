/// ある言語での名前 1 つ。
package struct LocalizedName: Equatable, Hashable, Sendable {
    package var languageCode: LanguageCode
    package var name: String

    package init(languageCode: LanguageCode, name: String) {
        self.languageCode = languageCode
        self.name = name
    }
}
