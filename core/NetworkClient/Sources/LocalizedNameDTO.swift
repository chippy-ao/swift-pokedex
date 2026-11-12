/// ある言語での名前 1 つ。言語コードは PokeAPI の文字列のまま（Model の型への変換は Repository で行う）。
public struct LocalizedNameDTO: Equatable, Sendable {
    public var languageCode: String
    public var name: String

    public init(languageCode: String, name: String) {
        self.languageCode = languageCode
        self.name = name
    }
}
