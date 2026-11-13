import Foundation
import Model
import Testing

@testable import PokedexFeature

struct TypeAppearanceTests {
    /// WCAG 2.x の相対輝度。https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
    private static func luminance(of hex: UInt32) -> Double {
        func linear(_ channel: UInt32) -> Double {
            let value = Double(channel) / 255
            return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        let red = linear((hex >> 16) & 0xFF)
        let green = linear((hex >> 8) & 0xFF)
        let blue = linear(hex & 0xFF)
        return 0.2126 * red + 0.7152 * green + 0.0722 * blue
    }

    /// 白い文字（#FFFFFF）との比。
    private static func contrastWithWhite(_ hex: UInt32) -> Double {
        1.05 / (luminance(of: hex) + 0.05)
    }

    @Test("白い文字とのコントラスト比が 4.5:1 以上（18 種類ぜんぶ）", arguments: PokemonType.allCases)
    func badgeColorHasEnoughContrastWithWhiteText(type: PokemonType) {
        #expect(Self.contrastWithWhite(type.badgeColorHex) >= 4.5)
    }

    @Test(
        "デザインで決めた 3 色",
        arguments: [
            (PokemonType.grass, UInt32(0x2E7D32)),
            (PokemonType.poison, UInt32(0x7B3FA0)),
            (PokemonType.fire, UInt32(0xC2410C)),
        ])
    func keepsDesignedColors(type: PokemonType, hex: UInt32) {
        #expect(type.badgeColorHex == hex)
    }

    @Test("18 種類の色はぜんぶ違う（見分けがつく）")
    func colorsAreDistinct() {
        let hexes = Set(PokemonType.allCases.map(\.badgeColorHex))

        #expect(hexes.count == PokemonType.allCases.count)
    }
}

struct DetailStringsTests {
    struct Case: Sendable {
        let key: String
        let language: String
        let expected: String
    }

    private struct TypeName {
        let type: PokemonType
        let english: String
        let japanese: String

        init(_ type: PokemonType, _ english: String, _ japanese: String) {
            self.type = type
            self.english = english
            self.japanese = japanese
        }
    }

    private struct StatName {
        let kind: PokemonStatKind
        let english: String
        let japanese: String

        init(_ kind: PokemonStatKind, _ english: String, _ japanese: String) {
            self.kind = kind
            self.english = english
            self.japanese = japanese
        }
    }

    private static let typeNames: [TypeName] = [
        TypeName(.normal, "Normal", "ノーマル"), TypeName(.fire, "Fire", "ほのお"),
        TypeName(.water, "Water", "みず"),
        TypeName(.electric, "Electric", "でんき"), TypeName(.grass, "Grass", "くさ"),
        TypeName(.ice, "Ice", "こおり"),
        TypeName(.fighting, "Fighting", "かくとう"), TypeName(.poison, "Poison", "どく"),
        TypeName(.ground, "Ground", "じめん"), TypeName(.flying, "Flying", "ひこう"),
        TypeName(.psychic, "Psychic", "エスパー"), TypeName(.bug, "Bug", "むし"),
        TypeName(.rock, "Rock", "いわ"),
        TypeName(.ghost, "Ghost", "ゴースト"), TypeName(.dragon, "Dragon", "ドラゴン"),
        TypeName(.dark, "Dark", "あく"),
        TypeName(.steel, "Steel", "はがね"), TypeName(.fairy, "Fairy", "フェアリー"),
    ]

    private static let statNames: [StatName] = [
        StatName(.hp, "HP", "HP"), StatName(.attack, "Attack", "こうげき"),
        StatName(.defense, "Defense", "ぼうぎょ"),
        StatName(.specialAttack, "Sp. Atk", "とくこう"), StatName(.specialDefense, "Sp. Def", "とくぼう"),
        StatName(.speed, "Speed", "すばやさ"),
    ]

    /// キーは `pokemonType.<rawValue>` と `pokemonStat.<rawValue>`。
    static let cases: [Case] =
        typeNames.flatMap { name in
            [
                Case(
                    key: "pokemonType.\(name.type.rawValue)", language: "en", expected: name.english
                ),
                Case(
                    key: "pokemonType.\(name.type.rawValue)", language: "ja",
                    expected: name.japanese),
            ]
        }
        + statNames.flatMap { name in
            [
                Case(
                    key: "pokemonStat.\(name.kind.rawValue)", language: "en", expected: name.english
                ),
                Case(
                    key: "pokemonStat.\(name.kind.rawValue)", language: "ja",
                    expected: name.japanese),
            ]
        }

    @Test("表が 18 種類と 6 つの種族値をぜんぶ含む")
    func tablesCoverEveryCase() {
        #expect(Set(Self.typeNames.map(\.type)) == Set(PokemonType.allCases))
        #expect(Set(Self.statNames.map(\.kind)) == Set(PokemonStatKind.allCases))
    }

    @Test("タイプと種族値の名前が言語ごとに引ける", arguments: cases)
    func catalogResolvesPerLanguage(_ testCase: Case) {
        // PokedexFeature の bundle は生成された記号から借りる（ListStringsTests と同じ）
        var resource = LocalizedStringResource(
            String.LocalizationValue(testCase.key),
            table: "Localizable",
            bundle: LocalizedStringResource.listNavigationTitle.bundle)
        resource.locale = Locale(identifier: testCase.language)

        #expect(String(localized: resource) == testCase.expected)
    }
}
