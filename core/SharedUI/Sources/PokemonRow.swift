import DesignSystem
import Model
import SwiftUI

/// 一覧の 1 行。画像、ID、名前を出す。
/// タイプは出さない（1 行ごとに詳細 API を呼ぶことになるため。feature/PokedexFeature/README.md 参照）。
package struct PokemonRow: View {
    private let pokemon: PokemonSummary

    package init(pokemon: PokemonSummary) {
        self.pokemon = pokemon
    }

    package var body: some View {
        HStack(spacing: 16) {
            RemoteImage(url: pokemon.spriteURL)
                .frame(width: 56, height: 56)
            Text(String(format: "#%04d", pokemon.id))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            Text(pokemon.name.capitalized)
                .font(.headline)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}
