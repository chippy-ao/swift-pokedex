import NukeUI
import SwiftUI

/// URL の画像を表示する。画像のキャッシュは Nuke が担当する。
/// 画像ライブラリはここだけが知っていて、他のモジュールはこの View を使う。
package struct RemoteImage: View {
    private let url: URL?
    private let interpolation: Image.Interpolation

    /// - Parameter interpolation: 拡大縮小のなめらかさ。既定の `.none` はドット絵向け
    ///   （ぼかさずに縮める）。写真やイラストは `.high` にする。
    package init(url: URL?, interpolation: Image.Interpolation = .none) {
        self.url = url
        self.interpolation = interpolation
    }

    package var body: some View {
        LazyImage(url: url) { state in
            if let image = state.image {
                image.resizable().interpolation(interpolation).scaledToFit()
            } else if state.error != nil {
                Image(systemName: "photo").foregroundStyle(.secondary)
            } else {
                Color.clear
            }
        }
    }
}
