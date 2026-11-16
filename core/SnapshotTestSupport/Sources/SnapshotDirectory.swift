import Foundation

/// 参照画像を置くフォルダを求める。`feature/<feature 名>/Tests/__Snapshots__/<テストのファイル名>/`。
///
/// 画像は、テストの正解なので、画面の持ち主（feature）のテストのフォルダに置く。
/// ただし、その feature の SwiftPM のテスト target の path（`Tests`）の中なので、Package.swift で
/// `exclude: ["__Snapshots__"]` して SwiftPM に拾わせない。別の feature の画面を撮り始めるときは、
/// その feature のテスト target にも同じ 1 行が要る。忘れても壊れないが、`swift build` が
/// 「unhandled files」の警告を出すだけで、xcodebuild の結果を読む check-warnings では気づけない。
///
/// swift-snapshot-testing の既定（テストのファイルの隣の `__Snapshots__/<テストのファイル名>/`）は使わない。
/// テストは `app/` のテスト target のフォルダ（Xcode のフォルダ同期）にあり、その中に PNG があると、
/// Xcode が PNG をテストの成果物（.xctest の直下）へコピーする。画像の名前は場面ごとに
/// `loaded.iPhone17-light.png` のようになるので、テストのファイルが 2 つ以上あると名前がぶつかってビルドが失敗する。
/// フォルダごとの除外はできない（ファイル 1 枚ずつしか外せない）ので、同期の対象の外に置く。
enum SnapshotDirectory {
    /// - Parameters:
    ///   - file: テストのファイルのパス（`#filePath`）。`app/<target>/X.swift` の形で、
    ///     2 つ上がリポジトリのルート。
    ///   - feature: 画像を置く feature の名前（例: `PokedexFeature`）。テストの場所からは分からないので、呼ぶ側が渡す。
    static func path(forTestFile file: String, feature: String) -> String {
        let url = URL(fileURLWithPath: file)
        let testName = url.deletingPathExtension().lastPathComponent
        return
            url
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("feature")
            .appendingPathComponent(feature)
            .appendingPathComponent("Tests")
            .appendingPathComponent("__Snapshots__")
            .appendingPathComponent(testName)
            .path
    }
}
