import Foundation
import SnapshotTesting
import UIKit

/// スナップショットを撮る環境。
/// 画像は端末と OS の描画の差でずれるので、参照画像を撮った環境（iPhone 17・iOS 27.2）以外では撮らない。
/// 環境を変えるときは、ここと mise.toml の既定のシミュレーターを同時に変えて、参照画像を撮り直す。
package enum SnapshotEnvironment {
    package static let simulatorName = "iPhone 17"
    package static let osVersion = "27.2"

    /// 撮る端末。端末を増やすときは、ここに足す（今は iPhone 17 だけ）。
    @MainActor package static var devices: [SnapshotDevice] {
        [SnapshotDevice(name: "iPhone17", config: .iPhone17)]
    }

    /// 走っている端末と OS が、参照画像を撮った環境と同じなら nil。違えば、人に向けたメッセージを返す。
    @MainActor
    package static func mismatchMessage() -> String? {
        // シミュレーターのプロセスには、環境変数 SIMULATOR_DEVICE_NAME で機種名が入る
        let name = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"]
        let version = UIDevice.current.systemVersion
        guard name != simulatorName || version != osVersion else { return nil }
        return """
            スナップショットは \(simulatorName)・iOS \(osVersion) で走らせてください \
            （今は \(name ?? "シミュレーター以外")・iOS \(version)）。\
            mise run test なら、この環境が既定です。
            """
    }
}

/// 撮る端末の名前（参照画像のファイル名に入る）と、画面の大きさや安全領域。
package struct SnapshotDevice {
    package let name: String
    package let config: ViewImageConfig
}

extension ViewImageConfig {
    /// iPhone 17（6.3 インチ、402 × 874 pt、3x、Dynamic Island）。
    /// ライブラリの組み込みの端末は古いので、同じ形で自分で定義する。
    /// 文字サイズは実機の既定の large に固定する（ライブラリの組み込みは medium）。
    @MainActor static var iPhone17: ViewImageConfig {
        ViewImageConfig(
            safeArea: UIEdgeInsets(top: 62, left: 0, bottom: 34, right: 0),
            size: CGSize(width: 402, height: 874),
            traits: UITraitCollection { traits in
                traits.displayScale = 3
                traits.forceTouchCapability = .available
                traits.layoutDirection = .leftToRight
                traits.preferredContentSizeCategory = .large
                traits.userInterfaceIdiom = .phone
                traits.horizontalSizeClass = .compact
                traits.verticalSizeClass = .regular
            }
        )
    }
}
