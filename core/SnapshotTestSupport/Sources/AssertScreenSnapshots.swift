import SnapshotTesting
import SwiftUI
import Testing
import UIKit

/// 画面を、撮る端末（SnapshotEnvironment.devices）ごとに、ライトとダークで撮って参照画像と比べる。
/// 参照画像は `__Snapshots__/<テストのファイル名>/<テスト名>.<端末>-<ライト / ダーク>.png`。
///
/// ホストアプリ付きのテスト target（app/PokedexSnapshotTests）から呼ぶ。理由は ADR-0020。
///
/// - `drawHierarchyInKeyWindow: true`: 実際に画面に出した View を描いて撮る。
///   既定の撮り方（layer.render）は Liquid Glass（`.glassProminent` など）を描けず白紙になる。
///   ライブラリの作者も、ホストアプリと true の組み合わせが要るとしている
///   （https://github.com/pointfreeco/swift-snapshot-testing/issues/1029）。
/// - 比べ方: `precision` 1（全ピクセルを比べる）、`perceptualPrecision` 0.98。
///   ライブラリのコメントで「98〜99% は人の目の精度」とされる値で、アンチエイリアスなど
///   目に見えない色の揺れだけを許す。Point-Free の isowords も 0.98。誤検知が出たら見直す。
/// - 言語と文字サイズ: 英語と、実機の既定の文字サイズ（large）に固定する。
///   文字サイズは端末の traits（`ViewImageConfig.iPhone17`）、言語は View の環境の `locale` で決める。
///   シミュレーターの言語設定には左右されない。
/// `public` なのは、呼ぶ側の app/PokedexSnapshotTests が Package.swift の外にあり、`package` が見えないため。
@MainActor
public func assertScreenSnapshots(
    of screen: some View,
    fileID: StaticString = #fileID,
    file: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line,
    column: UInt = #column
) {
    if let message = SnapshotEnvironment.mismatchMessage() {
        Issue.record(Comment(rawValue: message))
        return
    }
    let styles: [(name: String, style: UIUserInterfaceStyle)] = [
        ("light", .light), ("dark", .dark),
    ]
    for device in SnapshotEnvironment.devices {
        for (styleName, style) in styles {
            let host = UIHostingController(
                rootView: screen.environment(\.locale, Locale(identifier: "en")))
            assertSnapshot(
                of: host,
                as: .image(
                    on: device.config,
                    drawHierarchyInKeyWindow: true,
                    precision: 1,
                    perceptualPrecision: 0.98,
                    traits: UITraitCollection { traits in
                        traits.userInterfaceStyle = style
                        traits.displayScale = device.config.traits.displayScale
                    }),
                named: "\(device.name)-\(styleName)",
                // 呼び出し元のテスト名を渡さないと、画像の名前が「assertScreenSnapshots」で衝突する
                fileID: fileID, file: file, testName: testName, line: line, column: column)
        }
    }
}
