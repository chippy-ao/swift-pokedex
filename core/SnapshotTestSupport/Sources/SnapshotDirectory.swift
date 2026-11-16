import Foundation

/// 参照画像を置くフォルダを求める。
///
/// swift-snapshot-testing の既定は「テストのファイルの隣の `__Snapshots__/<テストのファイル名>/`」。
/// ここでは、テストのファイルがあるフォルダの 1 つ上（`app/__Snapshots__/<テストのファイル名>/`）にする。
/// 既定の場所だと、テスト target のフォルダ（Xcode のフォルダ同期）の中に PNG が入り、
/// Xcode が PNG をテストの成果物（.xctest の直下）へコピーする。画像の名前は場面ごとに
/// `loaded.iPhone17-light.png` のようになるので、テストのファイルが 2 つ以上あると名前がぶつかってビルドが失敗する。
/// フォルダごとの除外はできない（ファイル 1 枚ずつしか外せない）ので、同期の対象の外に置く。
enum SnapshotDirectory {
    /// - Parameter file: テストのファイルのパス（`#filePath`）。
    static func path(forTestFile file: String) -> String {
        let url = URL(fileURLWithPath: file)
        let testName = url.deletingPathExtension().lastPathComponent
        return
            url
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__")
            .appendingPathComponent(testName)
            .path
    }
}
