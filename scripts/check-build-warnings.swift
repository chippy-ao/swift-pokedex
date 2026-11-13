// ビルドの警告チェック。`mise run test` が出した xcresult の警告を数え、1 件でもあれば exit 1 にする。
// 使い方: swift scripts/check-build-warnings.swift [xcresult のパス]（既定は build/AllTests.xcresult）
//
// 何のため: 警告が増えたことに気づかないまま PR がマージされるのを防ぐ。CI の build-test ジョブで
// テストのあとに `mise run check-warnings` として走らせる。手元のビルドは止めない。
//
// なぜコンパイラのフラグでないか（試して確かめた結果）:
// - `-warnings-as-errors` を付けても、Swift 6 の並行性の警告（XCUIApplication が @MainActor）は
//   エラーにならず、ビルドが通った。
// - Xcode は外部の SwiftPM 依存を `-suppress-warnings` で組むため、`-warnings-as-errors` や
//   `-Wwarning` と衝突して Nuke などのビルドが失敗した（Conflicting options）。
// 外部依存の警告は抑えられていて、xcresult に入らない（CI で 0 件だった）。
//
// 手元は増分ビルドなので、変更のないファイルの警告は xcresult に記録されないことがある。
// 0 件でも当てにならない。CI はまっさらな状態からビルドするので、CI の結果が正。
//
// deprecated の警告も数える。増えたら（Xcode を上げたときなど）そのとき相談する。
import Foundation

struct Issue: Decodable {
    let issueType: String?
    let message: String
    let sourceURL: String?
    let targetName: String?
}

struct BuildResults: Decodable {
    let warningCount: Int
    let warnings: [Issue]
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("error: \(message)\n".utf8))
    exit(1)
}

/// `file:///path/File.swift#...StartingLineNumber=12&...` を「path/File.swift:13」の形にする。
/// xcresult の行番号は 0 始まり。
func location(_ issue: Issue) -> String {
    guard let urlString = issue.sourceURL, let url = URL(string: urlString) else {
        return issue.targetName.map { "(\($0))" } ?? "(場所不明)"
    }
    var path = url.path
    let root = FileManager.default.currentDirectoryPath + "/"
    if path.hasPrefix(root) { path.removeFirst(root.count) }
    guard let fragment = url.fragment,
        let item = fragment.split(separator: "&").first(where: {
            $0.hasPrefix("StartingLineNumber=")
        }),
        let line = Int(item.dropFirst("StartingLineNumber=".count))
    else { return path }
    return "\(path):\(line + 1)"
}

let path = CommandLine.arguments.dropFirst().first ?? "build/AllTests.xcresult"
guard FileManager.default.fileExists(atPath: path) else {
    fail("\(path) がありません。先に mise run test を実行してください")
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
process.arguments = ["xcresulttool", "get", "build-results", "--path", path]
let pipe = Pipe()
process.standardOutput = pipe
try process.run()
// 出力が大きいと waitUntilExit の前にパイプが詰まるので、先に読み切る
let data = pipe.fileHandleForReading.readDataToEndOfFile()
process.waitUntilExit()
guard process.terminationStatus == 0 else {
    fail("xcresulttool が失敗しました（終了コード \(process.terminationStatus)）")
}

let results: BuildResults
do {
    results = try JSONDecoder().decode(BuildResults.self, from: data)
} catch {
    fail("xcresulttool の出力を読めませんでした: \(error)")
}

for warning in results.warnings {
    print("\(location(warning)) \(warning.message)")
}
print("ビルドの警告: \(results.warningCount) 件")
exit(results.warningCount > 0 || !results.warnings.isEmpty ? 1 : 0)
