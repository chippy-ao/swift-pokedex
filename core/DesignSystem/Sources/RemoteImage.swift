import NukeUI
import SwiftUI

/// URL の画像を表示する。画像のキャッシュは Nuke が担当する。
/// 画像ライブラリはここだけが知っていて、他のモジュールはこの View を使う。
package struct RemoteImage: View {
    private let url: URL?

    package init(url: URL?) {
        self.url = url
    }

    package var body: some View {
        LazyImage(url: url) { state in
            if let image = state.image {
                image.resizable().interpolation(.none).scaledToFit()
            } else if state.error != nil {
                Image(systemName: "photo").foregroundStyle(.secondary)
            } else {
                Color.clear
            }
        }
    }
}
