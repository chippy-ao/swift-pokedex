import SwiftUI

/// 角丸の大きさ。
package enum CornerRadius {
    /// 画像の台の角丸。56pt の画像に対して丸すぎず四角すぎない 12。
    package static let thumbnail: CGFloat = 12

    /// 詳細画面のアートワークの台の角丸。180pt の画像に対して `thumbnail` と同じ比率に近い 24。
    package static let artwork: CGFloat = 24
}
