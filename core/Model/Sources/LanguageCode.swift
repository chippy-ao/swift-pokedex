/// PokeAPI の言語コード（`en`、`ja-hrkt` など）。
///
/// `typealias LanguageCode = String` にしないのは、型の上で普通の `String`（名前や識別子）と
/// 区別されず、取り違えてもコンパイルが通ってしまうため。
/// `enum` にしないのは、PokeAPI が将来コードを足したときに、未知のコードを受け取った時点で
/// 失敗（デコードエラーなど）になってしまうため。`RawRepresentable` の struct なら、未知のコードも
/// そのまま運べる。
public struct LanguageCode: RawRepresentable, Hashable, Sendable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    // PokeAPI のコードそのままの名前にする（2 文字だが `identifier_name` の下限に合わせて崩さない）。
    // swiftlint:disable identifier_name
    /// 英語。
    public static let en = LanguageCode(rawValue: "en")
    // swiftlint:enable identifier_name
    /// 日本語（カナ表記）。
    public static let jaHrkt = LanguageCode(rawValue: "ja-hrkt")
}
