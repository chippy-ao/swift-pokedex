import SwiftUI

private struct ShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content
                .overlay {
                    // 白一色だとダークで明るすぎるので、透明度を低めにする。
                    GeometryReader { proxy in
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.25), .clear],
                            startPoint: .leading, endPoint: .trailing
                        )
                        .frame(width: proxy.size.width)
                        .rotationEffect(.degrees(20))
                        .offset(x: phase * proxy.size.width * 1.5)
                    }
                    .mask(content)
                    .allowsHitTesting(false)
                }
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        }
    }
}

extension View {
    /// 斜めの光を横に流して「読み込み中」を表す。
    /// 「視差効果を減らす」がオンのときは動かさない。
    package func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}
