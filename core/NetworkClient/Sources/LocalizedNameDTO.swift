/// ある言語での名前 1 つ。言語コードは PokeAPI の文字列のまま（Model の型への変換は Repository で行う）。
package struct LocalizedNameDTO: Equatable, Sendable {
    package var languageCode: String
    package var name: String

    package init(languageCode: String, name: String) {
        self.languageCode = languageCode
        self.name = name
    }
}
