import Foundation
import Model
import SwiftUI

extension PokemonType {
    /// タイプの札の背景色（0xRRGGBB）。白い文字とのコントラスト比 4.5:1 以上（WCAG AA の通常の文字）。
    /// 18 色ぶん、`TypeAppearanceTests` が計算で確かめている。
    /// 色味はゲームのタイプ色に寄せ、白い文字で読める濃さまで落としている。
    /// `switch` に `default` を置かないので、タイプを足すとここがコンパイルエラーになる。
    var badgeColorHex: UInt32 {
        switch self {
        case .normal: 0x6B6B78
        case .fire: 0xC2410C
        case .water: 0x1D4ED8
        case .electric: 0x8A6A00
        case .grass: 0x2E7D32
        case .ice: 0x0E7490
        case .fighting: 0xB91C1C
        case .poison: 0x7B3FA0
        case .ground: 0x8B5A2B
        case .flying: 0x4F5FC0
        case .psychic: 0xC2185B
        case .bug: 0x5F7A12
        case .rock: 0x7A6A4F
        case .ghost: 0x4A3F8F
        case .dragon: 0x4338CA
        case .dark: 0x3F3F46
        case .steel: 0x4B6A7D
        case .fairy: 0xB0368F
        }
    }

    var badgeColor: Color {
        Color(
            red: Double((badgeColorHex >> 16) & 0xFF) / 255,
            green: Double((badgeColorHex >> 8) & 0xFF) / 255,
            blue: Double(badgeColorHex & 0xFF) / 255)
    }

    /// 画面に出す名前。カタログのキーは `pokemonType.<rawValue>`。
    var displayName: LocalizedStringResource {
        let key = "pokemonType.\(rawValue)"
        return LocalizedStringResource(
            String.LocalizationValue(key), table: "Localizable",
            bundle: .atURL(Bundle.module.bundleURL))
    }
}

extension PokemonStatKind {
    /// 画面に出す名前。カタログのキーは `pokemonStat.<rawValue>`。
    var displayName: LocalizedStringResource {
        let key = "pokemonStat.\(rawValue)"
        return LocalizedStringResource(
            String.LocalizationValue(key), table: "Localizable",
            bundle: .atURL(Bundle.module.bundleURL))
    }
}
