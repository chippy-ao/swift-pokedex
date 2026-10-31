// 依存チェック。使い方と背景は docs/package-dependencies.md の「依存チェック」を参照。
//
// 1. 各 target のソースの import と、`swift package describe --type json` の直接依存を突き合わせる。
//    パッケージ内の target と、宣言した外部パッケージの product は、直接依存に書かずに import するとエラー。
//    Foundation や SwiftUI などのシステムのモジュールは対象外。
// 2. Package.swift のテスト target が app/AllTests.xctestplan に過不足なく登録されているかを検査する。
import Foundation

struct PackageTarget: Decodable {
    let name: String
    let c99name: String
    let type: String
    let path: String
    let sources: [String]
    let targetDependencies: [String]?
    let productDependencies: [String]?

    enum CodingKeys: String, CodingKey {
        case name, c99name, type, path, sources
        case targetDependencies = "target_dependencies"
        case productDependencies = "product_dependencies"
    }
}

struct PackageDescription: Decodable {
    let targets: [PackageTarget]
}

struct TestPlanTarget: Decodable {
    let name: String
}

struct TestPlanEntry: Decodable {
    let target: TestPlanTarget
    let enabled: Bool?
}

struct TestPlan: Decodable {
    let testTargets: [TestPlanEntry]
}

let rootURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    .deletingLastPathComponent()
let testPlanPath = "app/AllTests.xctestplan"

func fail(_ messages: [String]) -> Never {
    for message in messages {
        FileHandle.standardError.write(Data("error: \(message)\n".utf8))
    }
    FileHandle.standardError.write(Data("依存チェックに失敗しました（\(messages.count) 件）。\n".utf8))
    exit(1)
}

func describePackage() -> PackageDescription {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["swift", "package", "describe", "--type", "json"]
    process.currentDirectoryURL = rootURL
    let output = Pipe()
    process.standardOutput = output
    do {
        try process.run()
    } catch {
        fail(["swift package describe を実行できませんでした: \(error)"])
    }
    let data = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        fail(["swift package describe が失敗しました（終了コード \(process.terminationStatus)）"])
    }
    do {
        return try JSONDecoder().decode(PackageDescription.self, from: data)
    } catch {
        fail(["swift package describe の出力を読めませんでした: \(error)"])
    }
}

/// import 文を探す。`@testable import X`、`import struct X.Y`、`public import X` などの形も扱う。
let importPattern = try NSRegularExpression(
    pattern: #"^\s*"#
        // @testable や @preconcurrency などの属性、public などのアクセス修飾子
        + #"(?:@\w+(?:\([^)]*\))?\s+|(?:public|package|internal|private|fileprivate)\s+)*"#
        + #"import\s+"#
        // import struct X.Y のような宣言の種類
        + #"(?:(?:typealias|struct|class|enum|protocol|let|var|func|actor)\s+)?"#
        + #"([A-Za-z_][A-Za-z0-9_]*)"#,
    options: [.anchorsMatchLines]
)
let blockCommentPattern = try NSRegularExpression(
    pattern: #"/\*.*?\*/"#, options: [.dotMatchesLineSeparators])
let lineCommentPattern = try NSRegularExpression(pattern: #"//.*$"#, options: [.anchorsMatchLines])

func importedModules(inSourceAt url: URL) -> [(module: String, line: Int)] {
    guard var text = try? String(contentsOf: url, encoding: .utf8) else {
        fail(["\(url.path) を読めませんでした"])
    }
    // コメントの中の import を拾わないよう、行数を保ったままコメントを空白にする。
    for pattern in [blockCommentPattern, lineCommentPattern] {
        let matches = pattern.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches.reversed() {
            let range = Range(match.range, in: text)!
            let blanked = String(text[range].map { $0 == "\n" ? "\n" : " " })
            text.replaceSubrange(range, with: blanked)
        }
    }
    var found: [(String, Int)] = []
    for (index, lineText) in text.components(separatedBy: "\n").enumerated() {
        let range = NSRange(lineText.startIndex..., in: lineText)
        guard let match = importPattern.firstMatch(in: lineText, range: range),
            let moduleRange = Range(match.range(at: 1), in: lineText)
        else { continue }
        found.append((String(lineText[moduleRange]), index + 1))
    }
    return found
}

func checkImports(in package: PackageDescription) -> [String] {
    // import したときに直接依存の宣言を求めるモジュール。システムのモジュールは含まれない。
    let internalModules = Set(package.targets.map(\.c99name))
    let externalProducts = Set(package.targets.flatMap { $0.productDependencies ?? [] })
    let managedModules = internalModules.union(externalProducts)

    var errors: [String] = []
    for target in package.targets {
        // 依存は target 名、product 名で書かれるので、import に使うモジュール名（c99name 相当）にそろえる。
        let allowedModules = Set(
            ((target.targetDependencies ?? []) + (target.productDependencies ?? []))
                .map { $0.replacingOccurrences(of: "-", with: "_") }
        ).union([target.c99name])
        let declared = (target.targetDependencies ?? []).joined(separator: ", ")

        for source in target.sources where source.hasSuffix(".swift") {
            let relativePath = "\(target.path)/\(source)"
            let url = rootURL.appendingPathComponent(relativePath)
            for (module, line) in importedModules(inSourceAt: url) {
                guard managedModules.contains(module), !allowedModules.contains(module) else {
                    continue
                }
                errors.append(
                    "\(relativePath):\(line): \(target.name) が \(module) を import していますが、"
                        + "直接の依存に書かれていません（Package.swift の \(target.name) の dependencies: [\(declared)]）。"
                        + "import を消すか、依存ルール（docs/package-dependencies.md）で許される場合だけ dependencies に追加してください。"
                )
            }
        }
    }
    return errors
}

func checkTestPlan(in package: PackageDescription) -> [String] {
    let testPlanURL = rootURL.appendingPathComponent(testPlanPath)
    let plan: TestPlan
    do {
        plan = try JSONDecoder().decode(TestPlan.self, from: Data(contentsOf: testPlanURL))
    } catch {
        return ["\(testPlanPath) を読めませんでした: \(error)"]
    }

    let packageTests = Set(package.targets.filter { $0.type == "test" }.map(\.name))
    let enabledInPlan = Set(plan.testTargets.filter { $0.enabled != false }.map(\.target.name))
    let allInPlan = Set(plan.testTargets.map(\.target.name))

    var errors: [String] = []
    for name in packageTests.subtracting(enabledInPlan).sorted() {
        let reason = allInPlan.contains(name) ? "無効になっています" : "登録されていません"
        errors.append("\(testPlanPath): テスト target \(name) が\(reason)。テストプランに有効な状態で登録してください。")
    }
    for name in enabledInPlan.subtracting(packageTests).sorted() {
        errors.append(
            "\(testPlanPath): \(name) は Package.swift のテスト target にありません。テストプランから外してください。")
    }
    return errors
}

let package = describePackage()
let errors = checkImports(in: package) + checkTestPlan(in: package)
if errors.isEmpty {
    print("依存チェック: 問題ありません（\(package.targets.count) target）")
} else {
    fail(errors)
}
