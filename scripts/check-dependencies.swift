// 依存チェック。使い方と背景は docs/package-dependencies.md の「依存チェック」を参照。
//
// 1. 各 target のソースの import と、`swift package describe --type json` の直接依存を突き合わせる。
//    パッケージ内の target と、宣言した外部パッケージの product は、直接依存に書かずに import するとエラー。
//    Foundation や SwiftUI などのシステムのモジュールは対象外。
// 2. Package.swift のテスト target が app/AllTests.xctestplan に過不足なく登録されているかを検査する。
// 3. Package.swift の依存が、docs/package-dependencies.md の依存グラフ（mermaid）の矢印に載っているかを検査する。
//    図が許可リストになる。図に無い target や依存はエラー。図にあって Package.swift に無い矢印はエラーにしない
//    （外部ライブラリは最初に使う Issue で入れるため）。
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

/// 依存グラフ（mermaid）から読んだ許可リスト。
struct DependencyGraph {
    /// ノード ID の集合。
    var nodes: Set<String> = []
    /// 矢印（依存元のノード ID → 依存先のノード ID の集合）。
    var arrows: [String: Set<String>] = [:]
    /// product 名 → ノード ID。ラベルの括弧内の名前（例: `(Dependencies / DependenciesMacros)`）を product 名とする。
    var productToNode: [String: String] = [:]

    func node(forDependency name: String) -> String {
        productToNode[name] ?? name
    }
}

let graphDocPath = "docs/package-dependencies.md"

let arrowPattern = try NSRegularExpression(
    pattern: #"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*-->\s*([A-Za-z_][A-Za-z0-9_]*)\s*$"#)
let nodePattern = try NSRegularExpression(
    pattern: #"^\s*([A-Za-z_][A-Za-z0-9_]*)(?:\[\"(.*)\"\])?\s*$"#)
let labelPattern = try NSRegularExpression(pattern: #"\(([^()]*)\)\s*$"#)
/// ノード定義ではない mermaid の構文の先頭語。
let mermaidKeywords: Set<String> = ["end", "flowchart", "graph", "subgraph", "classDef", "class"]

func capture(_ match: NSTextCheckingResult, _ index: Int, in line: String) -> String? {
    Range(match.range(at: index), in: line).map { String(line[$0]) }
}

/// 「## 依存グラフ」直下の最初の mermaid ブロックの行を返す。
func mermaidLines(in text: String) -> [String] {
    var lines: [String] = []
    var inSection = false
    var inBlock = false
    for line in text.components(separatedBy: "\n") {
        if inBlock {
            if line.hasPrefix("```") { break }
            lines.append(line)
        } else if line.hasPrefix("## ") {
            inSection = line == "## 依存グラフ"
        } else if inSection && line.hasPrefix("```mermaid") {
            inBlock = true
        }
    }
    return lines
}

func addGraphLine(_ line: String, to graph: inout DependencyGraph) {
    let range = NSRange(line.startIndex..., in: line)
    if let match = arrowPattern.firstMatch(in: line, range: range),
        let source = capture(match, 1, in: line), let destination = capture(match, 2, in: line)
    {
        graph.nodes.formUnion([source, destination])
        graph.arrows[source, default: []].insert(destination)
        return
    }
    guard let match = nodePattern.firstMatch(in: line, range: range),
        let id = capture(match, 1, in: line), !mermaidKeywords.contains(id)
    else { return }
    graph.nodes.insert(id)
    // ラベルの末尾の括弧内を product 名として扱う。括弧が無ければノード ID が product 名。
    guard let label = capture(match, 2, in: line),
        let labelMatch = labelPattern.firstMatch(
            in: label, range: NSRange(label.startIndex..., in: label)),
        let inner = capture(labelMatch, 1, in: label)
    else { return }
    for product in inner.split(separator: "/") {
        graph.productToNode[product.trimmingCharacters(in: .whitespaces)] = id
    }
}

func readDependencyGraph() -> DependencyGraph {
    guard
        let text = try? String(
            contentsOf: rootURL.appendingPathComponent(graphDocPath), encoding: .utf8)
    else {
        fail(["\(graphDocPath) を読めませんでした"])
    }
    var graph = DependencyGraph()
    for line in mermaidLines(in: text) {
        addGraphLine(line, to: &graph)
    }
    if graph.arrows.isEmpty {
        fail([
            "\(graphDocPath) の「## 依存グラフ」直下の mermaid ブロックから矢印（A --> B）を読めませんでした。"
                + "書式を変えた場合は scripts/check-dependencies.swift の読み取りも直してください。"
        ])
    }
    return graph
}

func checkDependencyGraph(in package: PackageDescription) -> [String] {
    let graph = readDependencyGraph()
    let guide = "\(graphDocPath) の依存グラフと依存ルールを確認し、依存を変えるときは先に図を直してください。"
    var errors: [String] = []
    for target in package.targets {
        let dependencies =
            (target.targetDependencies ?? []).map { ($0, graph.node(forDependency: $0)) }
            + (target.productDependencies ?? []).map { ($0, graph.node(forDependency: $0)) }
        if target.type == "test" {
            // テスト target は、名前から Tests を除いた自分の target と TestSupport だけを許可する。
            let subject =
                target.name.hasSuffix("Tests") ? String(target.name.dropLast(5)) : target.name
            for (name, _) in dependencies where name != subject && name != "TestSupport" {
                errors.append(
                    "Package.swift: テスト target \(target.name) が \(name) に依存していますが、"
                        + "許可されているのは \(subject) と TestSupport だけです。\(guide)")
            }
            continue
        }
        guard graph.nodes.contains(target.name) else {
            errors.append(
                "Package.swift: target \(target.name) が \(graphDocPath) の依存グラフにありません。"
                    + "モジュールを足したら図も直してください。\(guide)")
            continue
        }
        let allowed = graph.arrows[target.name] ?? []
        for (name, node) in dependencies where !allowed.contains(node) {
            errors.append(
                "Package.swift: \(target.name) → \(name) の依存が \(graphDocPath) の依存グラフにありません。\(guide)"
            )
        }
    }
    return errors
}

let package = describePackage()
let errors =
    checkImports(in: package) + checkTestPlan(in: package) + checkDependencyGraph(in: package)
if errors.isEmpty {
    print("依存チェック: 問題ありません（\(package.targets.count) target）")
} else {
    fail(errors)
}
