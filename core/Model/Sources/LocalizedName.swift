/// ある言語での名前 1 つ。
public struct LocalizedName: Equatable, Hashable, Sendable {
    public var languageCode: LanguageCode
    public var name: String

    public init(languageCode: LanguageCode, name: String) {
        self.languageCode = languageCode
        self.name = name
    }
}
