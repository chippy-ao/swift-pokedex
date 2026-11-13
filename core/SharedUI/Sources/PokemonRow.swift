import DesignSystem
import Foundation
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
        HStack(spacing: Spacing.medium) {
            RemoteImage(url: pokemon.spriteURL)
                .frame(width: ImageSize.thumbnail, height: ImageSize.thumbnail)
                .background(
                    Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: CornerRadius.thumbnail))
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(pokemon.name)
                    .font(.headline)
                Text(String(format: "#%04d", pokemon.id))
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    PokemonRow(
        pokemon: PokemonSummary(
            id: 25, name: "Pikachu",
            spriteURL: URL(
                string:
                    "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png"
            )!)
    )
    .padding()
}
