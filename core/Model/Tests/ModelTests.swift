import Testing

@testable import Model

struct PokemonDetailTests {
    private func detail(stats: [PokemonStat]) -> PokemonDetail {
        PokemonDetail(
            id: 1, name: "フシギダネ", genus: nil, types: [.grass], stats: stats,
            heightInMeters: 0.7, weightInKilograms: 6.9, artworkURL: nil)
    }

    @Test("種族値の合計は 6 つの値の和（フシギダネは 318）")
    func statTotalIsSum() {
        let stats = [
            PokemonStat(kind: .hp, value: 45),
            PokemonStat(kind: .attack, value: 49),
            PokemonStat(kind: .defense, value: 49),
            PokemonStat(kind: .specialAttack, value: 65),
            PokemonStat(kind: .specialDefense, value: 65),
            PokemonStat(kind: .speed, value: 45),
        ]

        #expect(detail(stats: stats).statTotal == 318)
    }

    @Test("種族値が無ければ合計は 0") func statTotalIsZeroWithoutStats() {
        #expect(detail(stats: []).statTotal == 0)
    }

    @Test("タイプは 18 種類で、rawValue は PokeAPI の識別子")
    func typeRawValuesAreAPIIdentifiers() {
        #expect(PokemonType.allCases.count == 18)
        #expect(PokemonType(rawValue: "grass") == .grass)
        #expect(PokemonType(rawValue: "fighting") == .fighting)
        #expect(PokemonType(rawValue: "stellar") == nil)
    }

    @Test("種族値の種類は 6 つで、rawValue は PokeAPI の識別子")
    func statKindRawValuesAreAPIIdentifiers() {
        #expect(PokemonStatKind.allCases.count == 6)
        #expect(PokemonStatKind(rawValue: "special-attack") == .specialAttack)
        #expect(PokemonStatKind(rawValue: "special-defense") == .specialDefense)
        #expect(PokemonStatKind(rawValue: "accuracy") == nil)
    }
}
