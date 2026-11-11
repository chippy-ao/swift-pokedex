import SwiftUI

/// 余白の段階。4 の倍数で揃え、画面ごとに値がばらつかないようにする。
package enum Spacing {
    /// 名前と番号のように、同じまとまりの中の行間。
    package static let xSmall: CGFloat = 4
    /// 近い部品どうしの間隔。
    package static let small: CGFloat = 8
    /// 画像と文字の間のように、別の部品を並べるときの間隔。
    package static let medium: CGFloat = 12
    /// 画面や部品まわりの標準の余白（iOS の標準の余白と同じ 16）。
    package static let large: CGFloat = 16
    /// 大きなまとまりの間隔。
    package static let xLarge: CGFloat = 24
}
