/// 種族値の種類 6 つ。rawValue は PokeAPI の識別子（`special-attack` など）。
public enum PokemonStatKind: String, CaseIterable, Hashable, Sendable {
    // PokeAPI の識別子そのままの名前にする（2 文字だが `identifier_name` の下限に合わせて崩さない）。
    // swiftlint:disable:next identifier_name
    case hp
    case attack
    case defense
    case specialAttack = "special-attack"
    case specialDefense = "special-defense"
    case speed
}

/// 種族値 1 つ。
public struct PokemonStat: Equatable, Hashable, Sendable {
    public var kind: PokemonStatKind
    public var value: Int

    public init(kind: PokemonStatKind, value: Int) {
        self.kind = kind
        self.value = value
    }
}
