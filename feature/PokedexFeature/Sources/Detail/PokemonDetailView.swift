import Dependencies
import DesignSystem
import Domain
import Foundation
import Model
import SwiftUI

struct PokemonDetailView: View {
    @State private var store: PokemonDetailStore

    init(id: Int) {
        self.init(store: PokemonDetailStore(id: id))
    }

    init(store: PokemonDetailStore) {
        _store = State(initialValue: store)
    }

    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .task { store.send(.onAppear) }
    }

    @ViewBuilder
    private var content: some View {
        let state = store.state
        if let detail = state.detail {
            ScrollView {
                DetailContent(detail: detail)
                    .padding(.horizontal, Spacing.large)
                    .padding(.bottom, Spacing.xLarge)
            }
        } else if case .failed(let error) = state.phase {
            VStack(spacing: Spacing.large) {
                Text(Self.message(for: error))
                    .multilineTextAlignment(.center)
                Button(.detailRetryButton) { store.send(.retryTapped) }
                    .buttonStyle(.glassProminent)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel(Text(.detailLoadingAccessibilityLabel))
        }
    }

    private static func message(for error: LoadError) -> LocalizedStringResource {
        switch error {
        case .offline: .detailErrorOffline
        case .unavailable: .detailErrorUnavailable
        }
    }
}

/// 読み込み済みの中身。上から、アートワーク、番号・名前・分類、タイプ、高さと重さ、種族値。
private struct DetailContent: View {
    let detail: PokemonDetail

    /// 種族値の棒の長さの基準。PokeAPI の種族値は最大 255（ヨガタ HP など）。
    private static let maxStat = 255.0

    var body: some View {
        VStack(spacing: Spacing.medium) {
            // 台は一覧の行と同じ灰色。タイプの色は着けない（札だけが色を持つ）。
            RemoteImage(url: detail.artworkURL, interpolation: .high)
                .frame(width: ImageSize.artwork, height: ImageSize.artwork)
                .background(
                    Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: CornerRadius.artwork)
                )
                .accessibilityLabel(Text(.detailArtworkAccessibilityLabel))
            VStack(spacing: Spacing.xSmall) {
                Text(String(format: "#%04d", detail.id))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                Text(detail.name)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                if let genus = detail.genus {
                    Text(genus)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            HStack(spacing: Spacing.small) {
                ForEach(detail.types, id: \.self) { type in
                    Text(type.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.medium)
                        .padding(.vertical, Spacing.xSmall)
                        .background(type.badgeColor, in: Capsule())
                }
            }
            HStack(spacing: Spacing.xLarge) {
                measurement(.detailHeightLabel, value: detail.heightInMeters, unit: "m")
                measurement(.detailWeightLabel, value: detail.weightInKilograms, unit: "kg")
            }
            .font(.subheadline.monospacedDigit())
            stats
                .padding(.top, Spacing.large)
        }
    }

    /// 高さと重さ。単位は m と kg に固定し、小数 1 桁で出す。
    private func measurement(_ label: LocalizedStringResource, value: Double, unit: String)
        -> some View
    {
        HStack(spacing: Spacing.xSmall) {
            Text(label).foregroundStyle(.secondary)
            Text(verbatim: "\(value.formatted(.number.precision(.fractionLength(1)))) \(unit)")
        }
        .accessibilityElement(children: .combine)
    }

    private var stats: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text(.detailStatsHeading)
                .font(.title3.weight(.semibold))
                .padding(.bottom, Spacing.xSmall)
            ForEach(detail.stats, id: \.kind) { stat in
                HStack(spacing: Spacing.medium) {
                    Text(stat.kind.displayName)
                        .foregroundStyle(.secondary)
                        .frame(width: ColumnWidth.statLabel, alignment: .leading)
                    Text("\(stat.value)")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .frame(width: ColumnWidth.statValue, alignment: .trailing)
                    // 棒は tint（テーマ色）。文字でもボタンでもなく、押せると誤解されにくいので、
                    // 「テーマ色は操作できる部品だけ」の例外にしている（README の Detail）。
                    ProgressView(value: Double(stat.value), total: Self.maxStat)
                }
                .font(.subheadline)
                .accessibilityElement(children: .combine)
            }
            Divider()
                .padding(.vertical, Spacing.xSmall)
            HStack(spacing: Spacing.medium) {
                Text(.detailStatTotal)
                    .foregroundStyle(.secondary)
                    .frame(width: ColumnWidth.statLabel, alignment: .leading)
                Text("\(detail.statTotal)")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .frame(width: ColumnWidth.statValue, alignment: .trailing)
            }
            .font(.subheadline)
            .accessibilityElement(children: .combine)
        }
    }
}

// Preview は fetchPokemonDetail だけを差し替える。feature は Domain の UseCase しか知らない。
private let previewDetail = PokemonDetail(
    id: 1, name: "フシギダネ", genus: "たねポケモン", types: [.grass, .poison],
    stats: [
        PokemonStat(kind: .hp, value: 45), PokemonStat(kind: .attack, value: 49),
        PokemonStat(kind: .defense, value: 49), PokemonStat(kind: .specialAttack, value: 65),
        PokemonStat(kind: .specialDefense, value: 65), PokemonStat(kind: .speed, value: 45),
    ],
    heightInMeters: 0.7, weightInKilograms: 6.9,
    artworkURL: URL(
        string:
            "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/1.png"
    ))

#Preview("読み込み済み") {
    let store = withDependencies {
        $0.fetchPokemonDetail.execute = { _ in previewDetail }
    } operation: {
        PokemonDetailStore(id: 1)
    }
    NavigationStack { PokemonDetailView(store: store) }
}

#Preview("読み込み中") {
    let store = withDependencies {
        $0.fetchPokemonDetail.execute = { _ in
            try await Task.sleep(for: .seconds(3600))
            return previewDetail
        }
    } operation: {
        PokemonDetailStore(id: 1)
    }
    NavigationStack { PokemonDetailView(store: store) }
}

#Preview("エラー（オフライン）") {
    let store = withDependencies {
        $0.fetchPokemonDetail.execute = { _ in throw LoadError.offline }
    } operation: {
        PokemonDetailStore(id: 1)
    }
    NavigationStack { PokemonDetailView(store: store) }
}
