import SwiftUI

/// 画像の大きさ。
package enum ImageSize {
    /// 一覧の行の画像。ドット絵（96pt 四方）を 56pt に縮めて、1 画面に多く並べる。
    package static let thumbnail: CGFloat = 56

    /// 詳細画面の公式アートワーク。画面の幅（390pt 前後）の半分より少し小さく、名前と種族値が
    /// 1 画面に収まる大きさ。
    package static let artwork: CGFloat = 180
}
